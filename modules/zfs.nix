# ZFS support. Import on hosts that use ZFS; each such host must also set a
# unique `networking.hostId`.
{ ... }:

{
  boot.supportedFilesystems.zfs = true;
  boot.initrd.supportedFilesystems.zfs = true;
  boot.zfs.forceImportRoot = false;
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;
}
