# Jack's NixOS Configs

### Hosts

| Host | Role | Notes |
|-------|-----------|-------|
| `x13` | laptop | ZFS on LUKS, TPM enabled, secure-boot (lanzaboote) imported but not yet turned on |
| `m1` | laptop | M1 Pro Macbook Pro |
| `g16` | desktop | Asus Strix G16CHR |
| `tank` | server | stub |

## Prerequisites

- Nix with flakes enabled (`experimental-features = nix-command flakes`).
- For identity setup: the [1Password desktop app](https://1password.com) with CLI integration turned on (see below) — not required just to build, only to get a working git/SSH identity.

## Usage

Rebuild a host:

```sh
sudo nixos-rebuild switch --flake /etc/nixos#x13
```

(substitute `g16` or `m1`, or `tank` once it has a real hardware config.)

Check what a host would build without switching:

```sh
nixos-rebuild build --flake /etc/nixos#x13
```

### Adding a new host

1. `mkdir hosts/<name>`, copy a `hardware-configuration.nix` from the real machine (`nixos-generate-config`).
2. Write `hosts/<name>/default.nix`: import the hardware config, a role from `modules/roles/`, and `modules/zfs.nix` if it uses ZFS (with a unique `networking.hostId`). Set `networking.hostName` and `system.stateVersion`.
3. Add `home-manager.users.jack.imports = [ ../../home/common.nix ]` (plus `../../home/desktop.nix` if it's graphical).
4. Add it to `nixosConfigurations` in `flake.nix`.

## Identities (SSH keys, git email) — kept out of this repo

This repo is public, so no email addresses, public keys, or org names live in it. Instead, `home/identities.nix` + `home/scripts/generate-identities.sh` regenerate all of that at every `home-manager`/`nixos-rebuild switch`, pulling the actual values live from 1Password.

### One-time setup

1. In the 1Password desktop app: **Settings → Developer → "Integrate with 1Password CLI"**, and make sure the app is unlocked. (This fleet authenticates `op` via the desktop app's socket, *not* `op signin` — a plain `op signin` session is scoped to one shell process and won't be visible to the activation script.)
2. For each identity, the 1Password item (an SSH Key item works well) needs two fields: one labeled `public key` (1Password's standard SSH-key field) and one labeled `email` (a custom field you add).
3. Copy `home/identities.example.json` to `~/.config/nixos-identities.json` (outside this repo, never tracked) and fill in your real 1Password item names:

   ```json
   {
     "sshKeys": [
       { "1passwordName": "Personal GitHub", "default": true },
       { "1passwordName": "Some Employer", "default": false, "path": "~/git/work", "alias": "github-work", "githubOrgs": ["some-employer-org"] }
     ]
   }
   ```

   - `default: true` → becomes the global git identity and the `Host github.com` SSH key. Exactly one entry should be `default`.
   - `path` (required for non-default entries) → a `gitdir:` prefix; repos under it commit as that identity.
   - `alias` (optional, defaults to a slug of the name) → the SSH `Host` alias, e.g. clone as `git@github-work:org/repo.git` to force that key.
   - `githubOrgs` (optional) → auto-rewrites `git@github.com:org/...` to use that alias, so normal-looking clone URLs still pick up the right key.

4. `sudo nixos-rebuild switch --flake /etc/nixos#<host>`.
