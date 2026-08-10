# Laptop role: mobility (auto timezone, geolocation), memory pressure relief,
# and suspend fixes.
{ ... }:

{
  services.automatic-timezoned.enable = true;
  services.geoclue2.enable = true;
  zramSwap.enable = true;

  # Work around the systemd >=256 regression where user sessions are frozen
  # before suspend; this deadlocks against in-flight ZFS fsync() and aborts
  # the suspend ("Freezing user space processes failed").
  systemd.services.systemd-suspend.environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "false";
}
