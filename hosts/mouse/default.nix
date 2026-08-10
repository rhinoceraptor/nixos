# mouse — desktop workstation. STUB: needs a real hardware-configuration.nix
# (run `nixos-generate-config` on the machine) before it will build.
{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/roles/desktop.nix
  ];

  networking.hostName = "mouse";
  # TODO: if this machine uses ZFS, import ../../modules/zfs.nix and set a
  # unique networking.hostId here.
  system.stateVersion = "26.05";

  home-manager.users.jack.imports = [
    ../../home/common.nix
    ../../home/desktop.nix
  ];
}
