# Headless server role. No graphical stack. Add server-wide defaults here
# (ssh hardening, monitoring, etc.) as the fleet grows.
{ lib, ... }:

{
  # Servers are headless; keep the graphical stack off even if some other
  # module tries to pull it in.
  services.xserver.enable = lib.mkDefault false;
}
