# laptop base
{ ... }:

{
  imports = [ ./graphical.nix ];

  services.automatic-timezoned.enable = true;
  services.geoclue2.enable = true;
  zramSwap.enable = true;

  systemd.services.systemd-suspend.environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "false";
}
