# Jack's NixOS Configs

A flake-based NixOS fleet, driven by [Home Manager](https://github.com/nix-community/home-manager) for everything user-level. One repo, three machines, each importing only the pieces it needs.

## Overview

Every host is built the same way: `modules/common.nix` (system-wide defaults every machine gets) plus one *role* module (`modules/roles/{laptop,desktop,server}.nix`) plus whatever's specific to that host in `hosts/<name>/default.nix`. Home Manager config follows the same idea — `home/common.nix` is universal, `home/desktop.nix` is opt-in for graphical machines.

```
flake.nix                  # inputs, overlays, the three nixosConfigurations
modules/
  common.nix                # every host: shell, dev tooling, docker, tailscale, ssh, the primary user...
  zfs.nix                   # opt-in: ZFS support (hosts using it need a unique networking.hostId)
  roles/
    graphical.nix            # shared GUI base: GNOME, 1Password, browsers, apps
    laptop.nix                # graphical.nix + mobility (auto-timezone, geoclue, suspend fixes)
    desktop.nix               # graphical.nix, no laptop-specific tweaks
    server.nix                 # headless, no graphical stack
hosts/
  x13/                        # ThinkPad X13 laptop — ZFS-on-LUKS, TPM, SDR/RF hardware
  mouse/                       # desktop workstation (STUB, see below)
  tank/                         # headless server (STUB, see below)
home/
  common.nix                    # every host: git, ssh, tmux, neovim, zsh...
  desktop.nix                    # graphical machines only: wezterm, desktop entries
  identities.nix                  # wires up the generated SSH/git identity config (see below)
  identities.example.json          # template for the untracked identities config
  scripts/
    generate-identities.sh          # regenerates SSH/git identity config from 1Password at every activation
```

### Hosts

| Host  | Role      | Notes |
|-------|-----------|-------|
| `x13` | laptop    | ZFS on LUKS, TPM enabled, secure-boot (lanzaboote) imported but not yet turned on, SDR/RF hobby hardware (HackRF, Ubertooth, GNU Radio, etc.) |
| `mouse` | desktop | **Stub** — needs a real `hosts/mouse/hardware-configuration.nix` (run `nixos-generate-config` on the machine) before it'll build |
| `tank` | server   | **Stub** — same as above, plus needs a unique `networking.hostId` for ZFS (see the `TODO` comment in `hosts/tank/default.nix`) |

## Prerequisites

- Nix with flakes enabled (`experimental-features = nix-command flakes`).
- For identity setup: the [1Password desktop app](https://1password.com) with CLI integration turned on (see below) — not required just to build, only to get a working git/SSH identity.

## Usage

Rebuild a host:

```sh
sudo nixos-rebuild switch --flake /etc/nixos#x13
```

(substitute `mouse` or `tank` once they have real hardware configs.)

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

### What gets generated (all untracked, regenerated every activation)

- `~/.ssh/op-identities/id_<slug>.pub` — each identity's public key
- `~/.ssh/generated-identities.config` — `Host` blocks, included from the top of `~/.ssh/config`
- `~/.config/git/generated-identities.gitconfig` — default `user.email`, `includeIf`/`url.insteadOf` blocks, included from `~/.config/git/config`
- `~/.config/git/identities/<slug>.gitconfig` — per-identity `user.email`
- `~/.config/1Password/ssh/agent.toml` — vault list for the SSH agent, derived from whichever vaults your configured items live in

If `~/.config/nixos-identities.json` doesn't exist, or 1Password isn't authorized, the script logs a message and exits cleanly — a fresh clone of this repo (or a machine that hasn't set up 1Password yet) still activates fine, just with no identities configured (and `git commit` will say "Please tell me who you are" until one's set up).

## Cross-OS notes

`home/common.nix` is mostly Linux-specific today (e.g. `pkgs.acpi` is only pulled in `lib.optionals pkgs.stdenv.isLinux`). There's a `nix-darwin` branch with WIP work toward running this same Home Manager config on macOS; the flake doesn't expose a `nix-darwin`/`homeConfigurations` output yet.
