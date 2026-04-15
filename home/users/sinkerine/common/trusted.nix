{ hostname, ... }:

{
  my.programs.nvim = {
    enable = true;
    avante.enable = true;
  };
  my.programs.gh.enable = true;

  programs.zsh.shellAliases = {
    jc = "nix develop /nixfiles --command jailed-claude-code";
    jx = "nix develop /nixfiles --command jailed-codex";
    jailedcodex-tmux = "nix develop /nixfiles#tmux --command jailed-codex";
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

  sops.secrets.avanteAnthropicApiKey = {
    sopsFile = ./secrets.yaml;
  };
  sops.secrets.githubToken = {
    sopsFile = ./secrets.yaml;
  };
  sops.secrets.avanteOpenaiApiKey = {
    sopsFile = ./secrets.yaml;
  };
  sops.secrets.avanteGeminiApiKey = {
    sopsFile = ./secrets.yaml;
  };
  sops.secrets.avanteMoonshotApiKey = {
    sopsFile = ./secrets.yaml;
  };
  sops.secrets.morphApiKey = {
    sopsFile = ./secrets.yaml;
  };
  sops.secrets.myPwd = {
    sopsFile = ./secrets.yaml;
  };

  my.programs.opencode = {
    enable = false;
  };
  my.programs.codex = {
    enable = true;
  };
  my.programs.claude-code = {
    enable = true;
  };

  my.programs.ai-agent-common = {
    enable = true;
  };
  my.programs.obsidian = {
    enable = true;
  };
}
