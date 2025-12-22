{ hostname, ... }:

{
  my.programs.nvim = {
    enable = true;
    avante.enable = true;
  };

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
  sops.secrets.avanteOpenaiApiKey = { sopsFile = ./secrets.yaml; };
  sops.secrets.avanteGeminiApiKey = { sopsFile = ./secrets.yaml; };
  sops.secrets.avanteMoonshotApiKey = { sopsFile = ./secrets.yaml; };
  sops.secrets.morphApiKey = { sopsFile = ./secrets.yaml; };

}

