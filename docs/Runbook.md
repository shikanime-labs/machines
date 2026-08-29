<!-- owner: shikanime | zone: internal | purpose: deploy hosts and manage secrets -->

# Runbook

## Deploy a host

`comin` reconciles hosts from the flake on its poll interval. To force a switch
now, run on the target:

```sh
sudo nixos-rebuild switch --flake .#<host>
# or for darwin
darwin-rebuild switch --flake .#telsha
```

CI builds `packages.<system>.*` (incl. `catbox`) for verification; the published
package outputs are convenience artifacts.

## Edit a secret

Never commit plaintext. Edit the encrypted source and let SOPS re-key:

```sh
sops secrets/<host>.enc.yaml
```

Each host points `sops.defaultSopsFile` at its own secret file. Some hosts use
`sops.templates.*` to materialize config fragments at activation.

## Branch protection

- 1 approving review, linear history, signed commits, squash+rebase only.
- Keep one logical change per PR; land stacked work with `gh stack merge`, never
  `gh pr merge` on a stacked PR.
