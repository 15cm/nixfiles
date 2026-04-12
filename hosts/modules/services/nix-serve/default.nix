{ config, lib, ... }:

with lib;
let cfg = config.my.services.nix-serve;
in {
  options.my.services.nix-serve = { enable = mkEnableOption "nix cache"; };

  config = mkIf cfg.enable {
    sops.secrets.nix-serve-secret = {
      format = "binary";
      sopsFile = ./priv-key.pem;
      owner = config.users.extraUsers.nix-serve.name;
    };

    services.nix-serve = {
      enable = true;
      secretKeyFile = config.sops.secrets."nix-serve-secret".path;
    };

    users.extraUsers.nix-serve = {
      description = "Nix-serve user";
      uid = config.my.ids.uids.nix-serve;
      group = "nix-serve";
    };
    users.groups.nix-serve = { gid = config.my.ids.uids.nix-serve; };

    services.caddy.virtualHosts."nixcache.mado.moe" = {
      extraConfig = ''
        reverse_proxy 127.0.0.1:${builtins.toString config.services.nix-serve.port}
      '';
    };
  };
}
