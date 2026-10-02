# ZFS support. Import on hosts with ZFS, also set unique `networking.hostId`.
{ ... }:

{
  boot.supportedFilesystems.zfs = true;
  boot.initrd.supportedFilesystems.zfs = true;
  boot.zfs.forceImportRoot = false;
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;
}
