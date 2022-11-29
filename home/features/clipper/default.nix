{ config, ... }:

let
  logDir = "${config.home.homeDirectory}/local/log";
  logFile = "${logDir}/clipper.log";
in {
  programs.clipper = {
    enable = true;
    settings = {
      address = "localhost";
      port = 8377;
      logfile = logFile;
    };
  };

  services.clipper = {
    enable = true;
    inherit logDir;
  };
}

