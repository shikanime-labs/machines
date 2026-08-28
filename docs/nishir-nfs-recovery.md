# NFS share-manager recovery (nishir cluster)

## When to use this procedure

Pods stuck in `ContainerCreating`/`Init` with:

- `FailedMount ... attacher.MountDevice ... DeadlineExceeded` for a Longhorn
  volume served over NFS (share-manager export).
- Kubelet log shows `unmounted volumes=[<vol>]` repeated every `sync-frequency`
  (30 s) for multiple pods sharing that volume.
- CSI plugin logs show NO `NodeStageVolume`/`NodePublishVolume` call for the
  volume — silence means the kubelet did not even invoke the plugin.

Root cause: the share-manager pod restarted, its Service got a NEW ClusterIP,
and stale mounts on the consumer node point at the OLD ClusterIP. Optionally
layered on top: a deleted pod's subpath cleanup wedge in kubelet's in-memory
operation queue.

## Signature

```text
Error syncing pod: unmounted volumes=[<vol>], ...: context deadline exceeded
nestedpendingoperations: Operation for "<vol>" pod "<DELETED-POD-UID>" failed.
No retries permitted until <future>. Error: error cleaning subPath mounts:
unmount failed: exit status 16 — device is busy
```

Key tell: multiple pods are stuck simultaneously, and the CSI plugin log
(consume node) shows nothing about this volume.

## Verification (before acting)

```bash
export K="kubectl --context nishir-k8s-operator.taila659a.ts.net"

# 1. Current share-manager Service ClusterIP
$K -n longhorn-system get svc downloads-whisparr-data \
  -o jsonpath='{.spec.clusterIP}'
# compare against what mounts are still active:
ssh <consumer-node> 'mount | grep downloads-whisparr'
# → stale mounts show an old IP different from the current Service ClusterIP

# 2. share-manager pod health
$K -n longhorn-system get pod share-manager-downloads-whisparr-data
# → must be Running; if in CrashLoopBackOff, resolve that first

# 3. Reachability test from consumer node (dry, no side effect)
ssh <consumer-node> \
  'mount -t nfs4 -o vers=4.1,soft,timeo=3,retrans=2,noresvport \
  <current-cluster-ip>:/downloads-whisparr-data /tmp/nfs-test-whisparr && \
  ls /tmp/nfs-test-whisparr && \
  umount -l /tmp/nfs-test-whisparr'
# → if "No such file or directory" or timeout, mounts are stale

# 4. Confirm no NPO wedge
ssh <consumer-node> \
  'grep -i "downloads-whisparr-data" /var/lib/rancher/rke2/agent/logs/kubelet.log | tail -30'
# → look for: repeated pod_workers "context deadline exceeded" + a
#   nestedpendingoperations "device is busy" line referencing a deleted pod UID
```

## Fix (ordered)

### Step 1: Lazy-unmount stale NFS mounts

```bash
ssh <consumer-node>
# for each stale mount (shows old ClusterIP in mount output):
umount -l <mountpoint>
# e.g.:
umount -l 10.104.70.211:/downloads-whisparr-data
# leave the subpath dirs under /var/lib/kubelet/pods/<dead-pod> — kubelet cleans them
```

### Step 2: Restart kubelet

On RKE2, kubelet is a child of `rke2-server.service`. On a control-plane node
restarting kubelet is safe when the cluster has ≥3 control-plane nodes (quorum
holds).

```bash
ssh <consumer-node>
systemctl restart rke2-server
# wait for node Ready
$K get node <node>  # must show Ready (not NotReady)
```

The queue-clearing is the key side effect — kubelet replays its operation log
with a clean NPO queue, so subsequent mount attempts reach the plugin.

Do NOT kill the kubelet process directly on RKE2 (the supervisor watchdog will
restart it, but the supervisor may not be a direct cgroup parent — restarting
`rke2-server` is the safe path).

### Step 3: Recreate the stuck pod(s)

```bash
$K -n <ns> delete pod <pod>
# StatefulSet recreates it immediately — verify: kubectl get pod <pod>
```

Creating the pod in place does NOT clear the wedge — only a healthy kubelet on a
healthy node does.

### Step 4: Verify

```bash
$K -n <ns> get pod <pod>
# → 1/1 Running
ssh <consumer-node> 'mount | grep downloads-whisparr'
# → shows the current ClusterIP, not a stale old IP
ssh <consumer-node> \
  'mount -t nfs4 -o vers=4.1,soft,timeo=3,retrans=2,noresvport \
  <current-cluster-ip>:/downloads-whisparr-data /tmp/nfs-test && \
  ls /tmp/nfs-test'
# → data visible; umount after
```

## What NOT to do

- **Do not rebuild/reinstall ganesha.nfsd on any host.** The share-manager pod
  IS the NFS server. A second ganesha on manash was a red herring in 2026-08-28
  — it served nothing and was stopped.
- **Do not patch `/etc/exports` or `/tmp/vfs.conf`** on any host.
- **Do not force-delete the Longhorn volume.** The share-manager pod was healthy
  the whole time.
- **Do not restart individual kubelet pods on RKE2.** Use
  `systemctl restart rke2-server` to get a clean kubelet. Individual `kubelet`
  restarts can conflict with the RKE2 supervisor.

## Related: share-manager subpath cleanup failure

A separate (but related) symptom: share-manager stuck in `starting` → `Failed`
loop with `Failed to recover intents` / XFS dirty log. That is diagnosed and
repaired via
[longhorn-volume-recovery](https://hermes-agent.nousresearch.com/docs/devops/longhorn-volume-recovery)
— fix the log on the engine-node replica first, then the share-manager
re-creates. This procedure applies when the share-manager pod itself is Running
fine and the blocker is entirely at the kubelet mount/volume layer.

## Why kubelet doesn't retry

After the subpath cleanup failure (`device is busy`):

1. Kubelet's `nestedpendingoperations` queue records the failure and its
   retry-after timestamp.
2. The lazy unmount of the physical NFS mount happens in a separate cleanup path
   that does not signal the queue.
3. Once the retry window closes, kubelet marks the operation permanently failed.
   Subsequent mount attempts for that volume (e.g. from a new pod using the same
   CSI volume) are queued after the dead entry and never reach the plugin —
   which is why the CSI logs are silent.
4. Restarting kubelet clears the entire NPO queue (and the pending-operation
   backlog), so the next reconciliation for each volume starts clean.
