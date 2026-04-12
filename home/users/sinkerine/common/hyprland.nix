{
  config,
  lib,
  ...
}:

with lib;
{
  my.programs.hyprland = {
    enable = true;
    inherit (config.my.display) monitors scale;
    musicPlayer = "Feishin";
    musicPlayerDesktopFileName = "feishin.desktop";
  };
}
