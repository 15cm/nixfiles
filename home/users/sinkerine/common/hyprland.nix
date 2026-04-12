{
  config,
  lib,
  ...
}:

with lib;
{
  config = mkIf config.my.isHeaded {
    my.programs.hyprland = {
      enable = true;
      inherit (config.my.display) monitors scale;
      musicPlayer = "Feishin";
      musicPlayerDesktopFileName = "feishin.desktop";
    };
  };
}
