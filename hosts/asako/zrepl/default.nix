{ config, mylib, ... }:

let
  pubCredentials = (import ../../common/pub-credentials/default.nix);
  inherit (mylib) templateFile;
  templateData = {
    inherit (pubCredentials.zrepl) caCertPath;
    certPath = "${config.sops.secrets."zrepl-asako-cert".path}";
    keyPath = "${config.sops.secrets."zrepl-asako-key".path}";
  };
in {
  sops.secrets = {
    "zrepl-asako-cert" = {
      format = "binary";
      sopsFile = ./asako.machine.mado.moe.crt;
    };
    "zrepl-asako-key" = {
      format = "binary";
      sopsFile = ./asako.machine.mado.moe.key;
    };
  };
  services.my-zrepl = {
    enable = true;
    configPath = templateFile "zrepl-config" templateData ./zrepl.yaml.jinja;
  };
}
