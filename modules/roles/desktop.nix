# Desktop/graphical role: GNOME, audio, printing, GUI applications.
{ config, lib, pkgs, ... }:

{
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  services.pipewire.enable = true;
  services.printing.enable = true;

  programs.firefox.enable = true;
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "jack" ];
  };

  programs.dconf.profiles.user.databases = [
    {
      lockAll = true;
      settings = {
        "org/gnome/desktop/input-sources" = {
          xkb-options = [ "ctrl:nocaps" ];
        };
        "org/gnome/desktop/peripherals/mouse" = {
          natural-scroll = true;
        };
      };
    }
  ];

  environment.systemPackages = with pkgs; [
    ffmpeg-full
    catppuccin
    wezterm
    spotify
    chromium
    cinny-desktop
    desktop-file-utils
    gparted
    element-desktop
    discord
    gnome-tweaks
    reaper
    slack
    zoom-us
    wl-clipboard
    vlc
    wl-color-picker
    bruno
    gimp
    krita
    inkscape
    libertine
    gnome-sound-recorder
    obsidian
    obs-studio
    calibre
    signal-desktop
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
    gnomeExtensions.emoji-copy
    gnomeExtensions.gtk4-desktop-icons-ng-ding
    gnomeExtensions.window-calls-extended
  ];
}
