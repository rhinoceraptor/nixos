# tank — headless server. STUB: needs a real hardware-configuration.nix
# (run `nixos-generate-config` on the machine) before it will build.
{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/zfs.nix
    ../../modules/roles/server.nix
  ];

  networking.hostName = "tank";
  # TODO: ZFS requires a unique 8-hex-digit hostId. Generate with
  # `head -c4 /dev/urandom | od -A none -t x4`.
  # networking.hostId = "xxxxxxxx";
  system.stateVersion = "26.05";

  home-manager.users.jack.imports = [
    ../../home/common.nix
  ];
}
