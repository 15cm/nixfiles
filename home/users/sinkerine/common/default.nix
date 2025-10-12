{ pkgs, nixinfo, hostname, ... }:

{
  home = rec {
    username = "sinkerine";
    homeDirectory = "/home/${username}";
  };

  imports = [ ../../../common/baseline.nix ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age = {
      keyFile = "/keys/age/${hostname}.txt";
      sshKeyPaths = [ ];
    };
    # https://github.com/Mic92/sops-nix/issues/167
    gnupg.sshKeyPaths = [ ];
  };
  sops.secrets.avanteAnthropicApiKey = { sopsFile = ./secrets.yaml; };
}
