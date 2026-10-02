# thinkpad x13
{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/zfs.nix
    ../../modules/roles/laptop.nix
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  networking.hostName = "x13";
  networking.hostId = "07c57de4";
  system.stateVersion = "26.05";

  boot.kernelParams = [ "mem_sleep_default=deep" ];
  boot.kernelModules = [ "gs_usb" ];

  # LUKS root
  boot.initrd.systemd.enable = true;
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/94c29069-af13-420d-8d01-1441ea8420a6";
    allowDiscards = true;
    # crypttabExtraOpts = [ "tpm2-device=auto" ]; # Uncomment late
  };

  hardware.cpu.intel.updateMicrocode = true;

  security.tpm2 = {
    enable = true;
    pkcs11.enable = true;
    tctiEnvironment.enable = true;
  };

  home-manager.users.jack.imports = [
    ../../home/common.nix
    ../../home/desktop.nix
  ];
}
