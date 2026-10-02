# PLACEHOLDER. Replace with the real hardware-configuration.nix from the
# machine (the Asahi/NixOS installer already generated one at
# /etc/nixos/hardware-configuration.nix during install — copy that file
# here verbatim) before `nixos-rebuild build .#m1` will work.
#
# Expect fileSystems."/" with fsType = "btrfs" (per the install), plus a
# fileSystems."/boot" entry mounting the EFI system partition the Asahi
# installer created specifically for this OS — on the real machine that's
# found via:
#   /dev/disk/by-partuuid/`cat /proc/device-tree/chosen/asahi,efi-system-partition`
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ];
  # TODO: boot.initrd, fileSystems."/", fileSystems."/boot", swapDevices,
  # hardware.* go here — copy from the machine's own hardware-configuration.nix.
}
