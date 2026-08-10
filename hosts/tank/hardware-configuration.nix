# PLACEHOLDER. Replace with the output of `nixos-generate-config --show-hardware-config`
# run on the `tank` machine. Until then `nixos-rebuild build .#tank` will fail
# (no root filesystem / boot device defined).
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ];
  # TODO: boot.initrd, fileSystems."/", swapDevices, hardware.* go here.
}
