# Desktop role: the shared graphical base with no laptop mobility/power
# tweaks. Desktop-only configuration (if any arises) goes here; anything
# shared with laptops belongs in ./graphical.nix.
{ ... }:

{
  imports = [ ./graphical.nix ];
}
