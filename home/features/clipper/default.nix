{ config, templateData, ... }:

let
  logDir = "${config.home.homeDirectory}/local/log";
  logFile = "${logDir}/clipper.log";
in {
  programs.clipper = {
    enable = true;
    settings = {
      inherit (templateData.clipper) address port;
      logfile = logFile;
    };
  };

  services.clipper = {
    enable = true;
    inherit logDir;
  };
}

