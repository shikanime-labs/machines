# Local Inference (Strix Halo nodes)

## Why llama.cpp RPC, not Ollama or vLLM

Target model: **DeepSeek V4 Flash 0731** — 284B total parameters, 13B active
(sparse MoE), 1M context window. GGUF weights: IQ3_S ≈ 103 GB, IQ4_XS ≈ 130 GB.

- A single Strix Halo has 128 GB unified memory and cannot hold the model at
  usable quality. Two nodes (256 GB) run IQ4_XS with KV-cache headroom.
- **Ollama** has no multi-node story — cannot shard across the two nodes.
- **vLLM** has no GGUF path (wants BF16, ~568 GB for this model), assumes
  InfiniBand-class fabric for multi-node (the 10 GbE bond is the wall), and is
  still unstable on gfx1151 (Radeon 8060S) per current issue trackers.
- **llama.cpp RPC** is the AMD-blessed two-Halo clustering topology. Only 13B is
  active per token, so cross-node traffic is activations, not weights — 10 GbE
  (~65 µs/hop) is adequate.

## Topology

- `kushira` — `role = "server"`: runs `llama-server`, offloads the rest to the
  rpc peer. Exposes OpenAI-compatible API on `:8080`.
- `sashina` — `role = "rpc"`: runs `llama-rpc-server` only, exposing its GPU to
  kushira over `:50052`.

Both nodes must have the same GGUF present locally (the model is loaded locally
on each for its layer slice) before the inference service starts.

## Configuration

GPU/ROCm acceleration lives entirely in
`modules/nixos/hardware/minisforum-ms-s1.nix` (imported by both hosts):

- `hardware.enableRedistributableFirmware = true` — Radeon 8060S (gfx1151)
  microcode so the compute stack reaches `/dev/dri/renderD128`.
- `hardware.graphics.enable = true` + `enable32Bit` (inherited from nixos-hardware `common-gpu-amd`) — Mesa/ROCm userspace.
- `boot.kernelParams = [ "amdgpu.gttsize=98304" "ttm.pages_limit=25165824" ]` —
  96 GiB GTT carve-out for the unified-memory iGPU.

The llama.cpp inference _service_ (server/rpc roles, `:8080`/`:50052`) is not
yet wired as a module — the nodes are provisioned with acceleration enabled and
the worker/RKE2 stack; the inference service is deferred until the nodes are
online. When added back, the ROCm package is
`pkgs.llama-cpp.override { rocmSupport = true; rpcSupport = true; }` —
`ngl = 999` offloads all layers to the iGPU; `flash-attn = "on"`; `ctx-size`
128k.

## ponytail notes

- The 10 GbE bond is adequate for MoE activations. If per-token latency proves
  RPC-bound, move to a USB4 ring first (community measured ~8 µs vs ~65 µs)
  before any other tuning.
- `ctx-size` is intentionally conservative at 128k; raise toward 1M only with
  measured VRAM/KV headroom — the 96 GiB GTT cap on Strix Halo bounds it.
- The model file is not fetched by the module — stage it manually (e.g. via
  `hf download unsloth/DeepSeek-V4-Flash-0731-GGUF --include "*UD-IQ4_XS*"`).
