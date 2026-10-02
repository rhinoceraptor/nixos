{ config, lib, pkgs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;

  hardware.enableRedistributableFirmware = true;
  services.fwupd.enable = true;

  hardware.bluetooth.enable = true;

  programs.wireshark.enable = true;

  users.defaultUserShell = pkgs.zsh;
  programs.zsh.enable = true;

  nixpkgs.config.allowUnfree = true;

  services.openssh.enable = true;
  services.tailscale.enable = true;

  virtualisation.docker.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  users.users.jack = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "networkmanager" "video" "dialout" "wireshark" ];
  };

  environment.systemPackages = with pkgs; [
    # editors
    neovim

    # version control
    git
    jujutsu

    # shell utilities
    tmux
    tree
    htop
    fastfetch
    rsync
    silver-searcher
    jq
    unzip
    zip
    envsubst

    # toolchains and build tools
    gcc
    gnumake
    pkg-config
    rustup
    pnpm
    nodejs_24
    python314
    dotnet-sdk_10
    uv

    # cloud
    google-cloud-sdk
    opentofu
    jsonnet

    # slop generators
    claude-code
    codex
    antigravity-cli
    cursor-cli

    # networking
    wget
    dig
    arp-scan

    # etc
    usbutils
    nvme-cli
    ldmtool
    parted
    bpftrace

    # docs
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
