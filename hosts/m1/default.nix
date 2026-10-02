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

  # Broadcom wifi on Asahi only works via iwd; wpa_supplicant (the
  # NetworkManager default) can't drive this card.
  networking.networkmanager.wifi.backend = "iwd";

  # laptop.nix turns on automatic-timezoned, but the Asahi brcmfmac driver
  # reports fake, sequential BSSIDs for every network except the one we're
  # connected to — geoclue's WiFi-based location lookup can never match those
  # against a real AP database, so the lookup just hangs forever. geoclue then
  # idles out after 60s, automatic-timezoned's pending D-Bus call dies with
  # "Remote peer disconnected", and systemd restarts it — a crash loop that
  # never actually sets the timezone (stuck on UTC). No GPS/modem to fall back
  # to either, so just set it statically until the driver improves.
  services.automatic-timezoned.enable = lib.mkForce false;
  time.timeZone = "America/Detroit";
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

  # The firmware-extraction derivation above reads that path directly in its
  # builder; the Nix build sandbox otherwise only exposes /nix/store, so
  # without this the build fails with "firmware.cpio missing" even though the
  # file is right there.
  nix.settings.extra-sandbox-paths = [ "/boot/vendorfw" ];

  # Defaults to true whenever hardware.asahi.enable is, but the current
  # nixos-apple-silicon release references pkgs.avd-fw in its video module
  # without actually defining it in the overlay — evaluation fails with
  # "attribute 'avd-fw' missing". Disable until upstream ships the package.
  hardware.asahi.avd.enable = false;

  # The internal keyboard still shows up as an Apple HID keyboard (driven by
  # the generic hid_apple module even under Asahi), so the usual Mac
  # fnmode knob applies: 2 = F1-F12 act as plain function keys by default,
  # hold Fn for brightness/volume/etc (the opposite of macOS's own default).
  boot.extraModprobeConfig = ''
    options hid_apple fnmode=2
  '';

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

  # Regular `discord` (gated to x86_64-linux in graphical.nix) has no Linux
  # aarch64 build. vesktop is an Electron-based, Discord-API-compatible
  # client that does ship official aarch64-linux builds.
  environment.systemPackages = [ pkgs.vesktop ];

  # Night Light, set to automatic sunset/sunrise scheduling by request. In
  # practice this won't actually turn on or off by itself right now: it
  # depends on geoclue for sunset/sunrise times, and geoclue can't resolve a
  # location here for the same reason automatic-timezoned is disabled above
  # (confirmed live — night-light-last-coordinates stays stuck at GNOME's
  # invalid (91, 181) sentinel). Flip night-light-schedule-automatic to false
  # plus explicit -from/-to hours for a schedule that actually activates.
  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/settings-daemon/plugins/color" = {
        night-light-enabled = true;
        night-light-schedule-automatic = true;
      };
    }
  ];
}
