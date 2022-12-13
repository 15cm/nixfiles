{ config, pkgs, lib, mylib, hostname, ... }:

with lib;

let
  inherit (mylib) templateFile;
  templateData = {
    cifsCredentialsPath = "${config.sops.secrets."autofs-cifs".path}";
  };
  autoNasPath = templateFile "autofs-nas" templateData ./auto.nas.jinja;
in {
  environment.systemPackages = with pkgs; [ nfs-utils cifs-utils ];

  sops.secrets."autofs-cifs" = {
    format = "binary";
    sopsFile = ./cifs-secrets.txt;
  };
  services.autofs = {
    enable = true;
    autoMaster = ''
      /misc	${./auto.misc}

      +auto.master
      /nas ${autoNasPath} --timeout=20,browse
    '';
  };
}
