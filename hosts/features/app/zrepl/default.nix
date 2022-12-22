{ config, lib, mylib, configTemplatePath, sopsCertPath, sopsKeyPath
, openPort ? false, ... }:

with lib;
let
  inherit (mylib) templateFile;
  templateData = {
    caCertPath = ./zrepl-ca.crt;
    certPath = "${config.sops.secrets."zrepl-cert".path}";
    keyPath = "${config.sops.secrets."zrepl-key".path}";
  };
in {
  sops.secrets = {
    "zrepl-cert" = {
      format = "binary";
      sopsFile = sopsCertPath;
    };
    "zrepl-key" = {
      format = "binary";
      sopsFile = sopsKeyPath;
    };
  };
  services.my-zrepl = {
    enable = true;
    configPath = templateFile "zrepl-config" templateData configTemplatePath;
  };
  networking.firewall.allowedTCPPorts = mkIf openPort [ 38888 ];
}
