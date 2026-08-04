{ config, lib, pkgs, ... }:

{
  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use S3 deep sleep instead of the flaky s2idle default (firmware
  # advertises S0 S3 S4 S5). More reliable + far less battery drain.
  boot.kernelParams = [ "mem_sleep_default=deep" ];
  boot.kernelModules = [ "gs_usb" ];

  # Work around the systemd >=256 regression where user sessions are
  # frozen before suspend; this deadlocks against in-flight ZFS fsync()
  # and aborts the suspend ("Freezing user space processes failed").
  systemd.services.systemd-suspend.environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "false";

  # ZFS
  boot.supportedFilesystems.zfs = true;
  boot.initrd.supportedFilesystems.zfs = true;
  networking.hostId = "07c57de4";
  boot.zfs.forceImportRoot = false;
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

  # LUKS
  boot.initrd.systemd.enable = true;
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/94c29069-af13-420d-8d01-1441ea8420a6";
    allowDiscards = true;
    # crypttabExtraOpts = [ "tpm2-device=auto" ]; # Uncomment late
  };

  # Hardware
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;
  services.fwupd.enable = true;
  security.tpm2 = {
    enable = true;
    pkcs11.enable = true;
    tctiEnvironment.enable = true;
  };
  zramSwap.enable = true;

  networking.hostName = "x13";
  networking.networkmanager.enable = true;
  time.timeZone = "America/Detroit";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  users.defaultUserShell = pkgs.zsh;
  users.groups.ubertooth = {};

  services.udev.packages = [ pkgs.ubertooth pkgs.python312Packages.rfcat ];

  users.users.jack = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "networkmanager" "video" "dialout" "ubertooth" ];
  };

  nixpkgs.config.allowUnfree = true;
  programs.zsh.enable = true;
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
    sbctl
    git
    vim
    neovim
    tpm2-tools
    cryptsetup
    nvme-cli
    ffmpeg-full
    wget
    tmux
    jujutsu
    catppuccin
    wezterm
    spotify
    chromium
    cinny-desktop
    google-cloud-sdk
    opentofu
    tree
    desktop-file-utils
    stdenv
    gnumake
    htop
    unzip
    gparted
    rsync
    element-desktop
    discord
    gnome-tweaks
    silver-searcher
    reaper
    slack
    zoom-us
    uv
    tesseract
    wl-clipboard
    dig
    vlc
    hyfetch
    zip
    jq
    bpftrace
    nodejs_24
    usbutils
    wl-color-picker
    dotnet-sdk_10
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
    gnomeExtensions.emoji-copy
    gnomeExtensions.gtk4-desktop-icons-ng-ding
    gnomeExtensions.window-calls-extended
    ldmtool
    util-linux
    bruno
    jsonnet
    gemini-cli
    envsubst
    gimp
    krita
    parted
    imagemagick
    inkscape
    cursor-cli
    claude-code
    codex
    pandoc
    libertine
    gnome-sound-recorder
    (texlive.combine {
      inherit (texlive)
        scheme-small
        moderncv
        fontspec
        enumitem
        xetex;
    })
    obsidian
    obs-studio
    calibre
    rustup
    signal-desktop
    bluez
    gnumake
    gcc
    pkg-config
    dbus
    esptool
    ubertooth
    hackrf
    gqrx
    gnuradio
    can-utils
    wireshark
    python314
    python312Packages.rfcat
  ];

  virtualisation.docker.enable = true;
  services.pipewire.enable = true;
  services.openssh.enable = true;
  services.printing.enable = true;
  services.tailscale.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  system.stateVersion = "26.05";
}

