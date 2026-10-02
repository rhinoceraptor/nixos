# MacBook Pro (M1) — laptop, bare-metal Asahi Linux (btrfs root), same
# graphical/laptop experience as x13. Everything x13-specific that doesn't
# apply to this hardware (ZFS-on-LUKS, Intel microcode, TPM2/lanzaboote
# secure-boot prep, the ACPI S3 sleep param, the gs_usb CAN-bus module) is
# deliberately left out rather than copied — see hosts/x13/default.nix for
# that.
{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/roles/laptop.nix
  ];

  networking.hostName = "m1";
  # This machine was first installed via the Asahi installer's unstable-based
  # ISO, which self-reports as 26.11 — unlike the other hosts, this is NOT
  # "26.05" to match them. stateVersion records whatever version a machine
  # was *actually* first installed with (for on-disk-format defaults); never
  # bump it to match sibling hosts or the current nixpkgs pin.
  system.stateVersion = "26.11";

  # Apple Silicon support (kernel, GPU driver, peripheral firmware, boot) from
  # nixos-apple-silicon — see flake.nix for why its nixpkgs isn't `follows`ed.
  hardware.asahi.enable = true;

  # The module's default for this is impure (builtins.pathExists against
  # whatever machine is *evaluating* the flake, not the target machine) —
  # fine when building directly on the Mac itself (where this is exactly
  # where the Asahi installer put it), but breaks evaluation from any other
  # machine. Pin it explicitly instead.
  hardware.asahi.peripheralFirmwareDirectory = "/boot/vendorfw";

  # Asahi's U-Boot already presents the UEFI environment the Asahi installer
  # set up (one per installed OS, picked via the Mac's own boot picker);
  # systemd-boot sits on top of that but must not try to manage EFI variables
  # itself. modules/common.nix defaults this to true for the other (plain
  # x86_64 UEFI) hosts, so override it here.
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

  home-manager.users.jack.imports = [
    ../../home/common.nix
    ../../home/desktop.nix
  ];
}
