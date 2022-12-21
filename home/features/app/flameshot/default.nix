{ config, ... }:

{
  services.flameshot = {
    enable = true;
    settings = {
      General = {
        disabledTrayIcon = false;
        showStartupLaunchMessage = false;
        saveAsFileExtension = "png";
        savePathFixed = true;
        savePath = "${config.home.homeDirectory}/Screenshots";
      };
    };
  };
}
