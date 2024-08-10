{ config, lib, pkgs, ... }:

with lib;
let cfg = config.my.services.vsftpd;
in {
  options.my.services.vsftpd = {
    enable = mkEnableOption "vsftpd";
    enableSsl = mkEnableOption "ssl";
    sopsCertFile = mkOption {
      default = null;
      type = with types; nullOr path;
    };
    sopsKeyFile = mkOption {
      default = null;
      type = with types; nullOr path;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.vsftpd = {
        enable = true;
        userlistDeny = false;
        localUsers = true;
        userlist = [ "sinkerine" ];
        localRoot = "/pool/main";
        writeEnable = true;
        extraConfig = ''
          # Required for FTPS to work
          ssl_ciphers=HIGH
          pasv_enable=YES
          pasv_min_port=20000
          pasv_max_port=20010
        '';
      };
    }
    (mkIf cfg.enableSsl {
      sops.secrets = {
        ftp-cert = {
          format = "binary";
          sopsFile = (assert cfg.sopsCertFile != null; cfg.sopsCertFile);
        };
        ftp-key = {
          format = "binary";
          sopsFile = (assert cfg.sopsKeyFile != null; cfg.sopsKeyFile);
        };
      };
      services.vsftpd = {
        forceLocalLoginsSSL = true;
        forceLocalDataSSL = true;
        rsaCertFile = config.sops.secrets.ftp-cert.path;
        rsaKeyFile = config.sops.secrets.ftp-key.path;
      };
    })
  ]);
}
