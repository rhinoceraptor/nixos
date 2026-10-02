# Shared graphical base
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
        "org/gnome/desktop/wm/keybindings" = {
          switch-to-workspace-left = [ "<Super><Control>h" "<Super><Control>Left" ];
          switch-to-workspace-right = [ "<Super><Control>l" "<Super><Control>Right" ];
        };
      };
    }
  ];

  fonts.packages = with pkgs; [
    libertine
  ];

  environment.systemPackages = with pkgs; [
    # Boot packages
    sbctl
    tpm2-tools
    cryptsetup

    # Terminal emulator
    wezterm

    # Web browsers
    chromium

    # Communication
    signal-desktop
    element-desktop

    # Media
    vlc
    ffmpeg-full
    obs-studio
    reaper
    gnome-sound-recorder

    # Graphics & design
    gimp
    krita
    inkscape
    darktable

    # Productivity & notes
    obsidian
    calibre
    bruno

    # Theming
    catppuccin

    # GNOME
    gnome-tweaks
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
    gnomeExtensions.emoji-copy
    gnomeExtensions.gtk4-desktop-icons-ng-ding
    gnomeExtensions.window-calls-extended

    # Desktop utils
    wl-clipboard
    wl-color-picker
    desktop-file-utils
    gparted

    # Embedded tools
    esptool
    ubertooth
    hackrf
    gqrx
    gnuradio
    can-utils
    python312Packages.rfcat
  ] ++ lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
    # No Linux aarch64 build upstream.
    slack
    discord
    zoom-us
    spotify
  ];

  # Embedded system setup
  users.groups.ubertooth = {};
  users.users.jack.extraGroups = [ "ubertooth" ];
  services.udev.packages = [ pkgs.ubertooth pkgs.python312Packages.rfcat ];
}
