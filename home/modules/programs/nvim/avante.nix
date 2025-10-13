{ config, lib, ... }:

with lib;
let
  cfg = config.my.programs.nvim.avante;
  nvimCfg = config.my.programs.nvim;
in {
  options.my.programs.nvim.avante = {
    enable = mkEnableOption "Avante AI assistant for Neovim";

    provider = mkOption {
      type = types.str;
      default = "claude";
      description = "AI provider to use (claude, openai, etc.)";
    };

    model = mkOption {
      type = types.str;
      default = "claude-sonnet-4-20250514";
      description = "AI model to use";
    };

    timeout = mkOption {
      type = types.int;
      default = 30000;
      description = "Request timeout in milliseconds";
    };

    temperature = mkOption {
      type = types.float;
      default = 0.75;
      description = "AI model temperature setting";
    };

    maxTokens = mkOption {
      type = types.int;
      default = 20480;
      description = "Maximum tokens for AI responses";
    };

    instructionsFile = mkOption {
      type = types.str;
      default = "avante.md";
      description = "Instructions file for Avante";
    };
  };

  config = mkIf (nvimCfg.enable && cfg.enable) {
    # Export API key environment variable
    programs.zsh.initContent = mkOrder 750 ''
      export AVANTE_ANTHROPIC_API_KEY=$(cat ${config.sops.secrets.avanteAnthropicApiKey.path})
    '';

    # Configure the Avante plugin
    programs.nixvim.plugins.avante = {
      enable = true;
      settings = {
        instructions_file = cfg.instructionsFile;
        provider = cfg.provider;
        mappings = {
          submit = {
            normal = "<C-Space>";
            insert = "<C-Space>";
          };
        };
        providers = {
          claude = {
            endpoint = "https://api.anthropic.com";
            model = cfg.model;
            timeout = cfg.timeout;
            extra_request_body = {
              temperature = cfg.temperature;
              max_tokens = cfg.maxTokens;
            };
          };
        };
      };
    };
  };
}

