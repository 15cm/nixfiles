{ pkgs, config, ... }:

{
  services.flameshot = {
    enable = true;
    package = pkgs.symlinkJoin {
      name = "flameshot";
      paths = [pkgs.flameshot];
      buildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/flameshot \
          --set XDG_CURRENT_DESKTOP sway
      '';
    };
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
