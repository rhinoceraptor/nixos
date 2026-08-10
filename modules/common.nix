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
    extraGroups = [ "wheel" "docker" "networkmanager" "video" "dialout" ];
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    neovim
    wget
    tmux
    jujutsu
    google-cloud-sdk
    opentofu
    tree
    stdenv
    gnumake
    gcc
    pkg-config
    dbus
    htop
    unzip
    zip
    rsync
    silver-searcher
    uv
    dig
    hyfetch
    jq
    bpftrace
    nodejs_24
    usbutils
    dotnet-sdk_10
    util-linux
    jsonnet
    gemini-cli
    envsubst
    cursor-cli
    claude-code
    codex
    pandoc
    wireshark
    python314
    arp-scan
    nvme-cli
    ldmtool
    parted
    imagemagick
    tesseract
    bluez
    rustup
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
