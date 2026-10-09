# G16CHR Asus Strix desktop
{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/zfs.nix
    ../../modules/roles/desktop.nix
    inputs.nix-flatpak.nixosModules.nix-flatpak
  ];

  networking.hostName = "g16";
  networking.hostId = "7c0ee4ed";
  time.timeZone = "America/Detroit";
  system.stateVersion = "25.05";

  boot.kernelParams = [ "nvidia-drm.fbdev=0" ];
  boot.enableContainers = true;
  systemd.tpm2.enable = true;

  services.flatpak = {
    enable = true;
    remotes = [{
      name = "flathub";
      location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
    }];
    packages = [
      "com.bambulab.BambuStudio"
    ];
  };


  home-manager.users.jack.imports = [
    ../../home/common.nix
    ../../home/desktop.nix
  ];
}
