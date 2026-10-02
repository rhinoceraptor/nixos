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
