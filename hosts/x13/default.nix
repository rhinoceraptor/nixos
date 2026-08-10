# Thinkpad X13 — laptop, ZFS-on-LUKS, TPM, SDR/RF hobby hardware.
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

  # Use S3 deep sleep instead of the flaky s2idle default (firmware
  # advertises S0 S3 S4 S5). More reliable + far less battery drain.
  boot.kernelParams = [ "mem_sleep_default=deep" ];
  boot.kernelModules = [ "gs_usb" ];

  # LUKS root
  boot.initrd.systemd.enable = true;
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/94c29069-af13-420d-8d01-1441ea8420a6";
    allowDiscards = true;
    # crypttabExtraOpts = [ "tpm2-device=auto" ]; # Uncomment late
  };

  # Intel CPU microcode
  hardware.cpu.intel.updateMicrocode = true;

  # TPM (secure-boot prep; lanzaboote module imported above but not yet enabled)
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
