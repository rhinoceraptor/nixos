# SSH/git identities (which 1Password key, which email, which directory)
# are kept out of this public repo entirely. Instead they're generated at
# every home-manager activation from ~/.config/nixos-identities.json plus
# live 1Password lookups (see home/scripts/generate-identities.sh) — nothing
# but a directory listing and a person's name ever touches this file.
#
# To add or change an identity: edit ~/.config/nixos-identities.json (schema
# in home/identities.example.json) and rebuild. If that file is missing, or
# `op` isn't signed in, activation just skips this step rather than failing
# — so a fresh clone of this repo, or a machine that hasn't signed into
# 1Password yet, still activates cleanly with no identities configured.
#
# Deliberately *not* using `pkgs._1password-cli` as a runtimeInput here: this
# fleet installs `op` via `programs._1password.enable` (a wrapped binary with
# desktop-app biometric unlock integration), and pulling in the plain CLI
# package would shadow that wrapped binary on PATH and break sign-in.
{ config, pkgs, lib, ... }:

let
  generateIdentities = pkgs.writeShellApplication {
    name = "generate-identities";
    runtimeInputs = [ pkgs.jq ];
    text = builtins.readFile ./scripts/generate-identities.sh;
  };
in
{
  programs.ssh.includes = [ "${config.home.homeDirectory}/.ssh/generated-identities.config" ];
  programs.git.includes = [
    { path = "${config.home.homeDirectory}/.config/git/generated-identities.gitconfig"; }
  ];

  home.activation.generateIdentities = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${generateIdentities}/bin/generate-identities
  '';
}
