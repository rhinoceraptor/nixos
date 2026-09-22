# Home-manager config for graphical machines only (terminal emulator, GUI
# desktop entries).
{ config, pkgs, lib, ... }:

{
  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
    extraConfig = ''
      local wezterm = require "wezterm"
      return {
        font_size = 12.0,
        color_scheme = "Catppuccin Mocha",
        hide_tab_bar_if_only_one_tab = true,
        window_content_alignment = {
          horizontal = 'Center',
          vertical = 'Bottom',
        },
        keys = {
          { key = "F11", action = wezterm.action.ToggleFullScreen },
        },
      }
    '';
  };

  xdg.desktopEntries."chromium-browser" = {
    name = "Chromium";
    exec = "chromium %U";
    icon = "chromium";
    categories = [ "Network" "WebBrowser" ];
  };
}
