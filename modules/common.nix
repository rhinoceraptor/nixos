# Universal system config — imported by every host regardless of role.
{ config, lib, pkgs, ... }:

{
  # Nix / flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Boot loader (sensible default; hosts may override for their firmware).
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.networkmanager.enable = true;

  # Firmware + updates
  hardware.enableRedistributableFirmware = true;
  services.fwupd.enable = true;

  # Bluetooth
  hardware.bluetooth.enable = true;

  # Packet capture — installs wireshark plus the setuid dumpcap wrapper and
  # the `wireshark` group (members can capture without root).
  programs.wireshark.enable = true;

  # Shell
  users.defaultUserShell = pkgs.zsh;
  programs.zsh.enable = true;

  nixpkgs.config.allowUnfree = true;

  # Remote access / mesh VPN
  services.openssh.enable = true;
  services.tailscale.enable = true;

  # Containers / dev
  virtualisation.docker.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Primary user. Hosts append machine-specific groups (e.g. hardware access).
  users.users.jack = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "networkmanager" "video" "dialout" "wireshark" ];
  };

  environment.systemPackages = with pkgs; [
    # Editors
    neovim

    # Version control
    git
    jujutsu

    # Shell / terminal utilities
    tmux
    tree
    htop
    hyfetch
    rsync
    silver-searcher
    jq
    unzip
    zip
    envsubst

    # Language toolchains & build tools
    gcc
    gnumake
    pkg-config
    rustup
    pnpm
    nodejs_24
    python314
    dotnet-sdk_10
    uv

    # Cloud / infrastructure-as-code
    google-cloud-sdk
    opentofu
    jsonnet

    # AI coding assistants
    claude-code
    codex
    gemini-cli
    cursor-cli

    # Networking (wireshark is enabled via programs.wireshark above)
    wget
    dig
    arp-scan

    # Disks / hardware / kernel tracing
    usbutils
    nvme-cli
    ldmtool
    parted
    bpftrace

    # Documents & media
    pandoc
    imagemagick
    tesseract
    (texlive.combine {
      inherit (texlive)
        scheme-small
        moderncv
        fontspec
        enumitem
        xetex;
    })
  ];
}
