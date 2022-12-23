{ config, ... }:

{
  imports = [ ./users.nix ];

  sops.secrets.nix-serve-secret = {
    format = "binary";
    sopsFile = ./priv-key.pem;
    owner = config.users.extraUsers.nix-serve.name;
  };

  services.nix-serve = {
    enable = true;
    secretKeyFile = config.sops.secrets."nix-serve-secret".path;
  };
}
