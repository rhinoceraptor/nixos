# MacBook Pro (M1) — laptop, bare-metal Asahi Linux (btrfs root)
{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/roles/laptop.nix
  ];

  networking.hostName = "m1";
  networking.networkmanager.wifi.backend = "iwd";
  services.automatic-timezoned.enable = lib.mkForce false;
  time.timeZone = "America/Detroit";
  system.stateVersion = "26.11";
  hardware.asahi.enable = true;
  hardware.asahi.peripheralFirmwareDirectory = "/boot/vendorfw";
  nix.settings.extra-sandbox-paths = [ "/boot/vendorfw" ];
  hardware.asahi.avd.enable = false;
  boot.extraModprobeConfig = ''
    options hid_apple fnmode=2
  '';
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

  home-manager.users.jack.imports = [
    ../../home/common.nix
    ../../home/desktop.nix
  ];

  environment.systemPackages = [ pkgs.vesktop ];
  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/settings-daemon/plugins/color" = {
        night-light-enabled = true;
        night-light-schedule-automatic = true;
      };
    }
  ];
}
