{ config, pkgs, lib, mylib, ... }:

with lib;

let
  inherit (mylib) templateFile;
  cfg = config.my.services.autofs;
  templateData = {
    cifsCredentialsFile = "${config.sops.secrets.autofs-cifs.path}";
  };
  autoNasFile = templateFile "autofs-nas" templateData ./auto.nas.jinja;
in {
  options.my.services.autofs = {
    enable = mkEnableOption "autofs";
    mountpoint = mkOption {
      type = types.str;
      default = "/nas";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ nfs-utils cifs-utils samba ];
    sops.secrets.autofs-cifs = {
      format = "binary";
      sopsFile = ./cifs-secrets.txt;
    };
    services.autofs = {
      enable = true;
      autoMaster = ''
        /misc	${./auto.misc}

        +auto.master
        ${cfg.mountpoint} ${autoNasFile} --timeout=20,browse
      '';
    };
  };
}
