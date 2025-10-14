{ nixvimLib, config, lib, ... }:

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

    instructionsFile = mkOption {
      type = types.str;
      default = "avante.md";
      description = "Instructions file for Avante";
    };

    claude = {
      model = mkOption {
        type = types.str;
        default = "claude-sonnet-4-20250514";
        description = "Claude model to use";
      };

      timeout = mkOption {
        type = types.int;
        default = 30000;
        description = "Request timeout in milliseconds";
      };

      temperature = mkOption {
        type = types.float;
        default = 0.2;
        description = "Claude model temperature setting";
      };

      maxTokens = mkOption {
        type = types.int;
        default = 4096;
        description = "Maximum tokens for Claude responses";
      };
    };

    openai = {
      model = mkOption {
        type = types.str;
        default = "gpt-4o";
        description = "OpenAI model to use";
      };

      timeout = mkOption {
        type = types.int;
        default = 30000;
        description = "Request timeout in milliseconds";
      };

      temperature = mkOption {
        type = types.float;
        default = 0.2;
        description = "OpenAI model temperature setting";
      };

      maxTokens = mkOption {
        type = types.int;
        default = 4096;
        description = "Maximum tokens for OpenAI responses";
      };
    };
  };

  config = mkIf (nvimCfg.enable && cfg.enable) {
    # Export API key environment variable
    programs.zsh.initContent = mkOrder 750 ''
      export AVANTE_ANTHROPIC_API_KEY=$(cat ${config.sops.secrets.avanteAnthropicApiKey.path})
      export AVANTE_OPENAI_API_KEY=$(cat ${config.sops.secrets.avanteOpenaiApiKey.path})
    '';

    programs.nixvim.keymaps = [
      {
        key = "<leader>apo";
        action = nixvimLib.mkRaw ''
          function() require("avante.api").switch_provider("openai") end
        '';
        options.desc = "avante: switch_provider openai";
      }
      {
        key = "<leader>apc";
        action = nixvimLib.mkRaw ''
          function() require("avante.api").switch_provider("claude") end
        '';
        options.desc = "avante: switch_provider claude";
      }
    ];

    programs.nixvim.plugins.which-key.settings.spec = [
      {
        __unkeyed-a = "<leader>a";
        group = "Avante";
      }
      {
        __unkeyed-ap = "<leader>ap";
        group = "Avante SwitchProvider";
      }
    ];

    # Configure the Avante plugin
    programs.nixvim.plugins.avante = {
      enable = true;
      settings = {
        instructions_file = cfg.instructionsFile;
        provider = cfg.provider;
        mappings = {
          submit = {
            normal = "<CR>";
            insert = "<A-Enter>";
          };
        };
        providers = {
          claude = {
            endpoint = "https://api.anthropic.com";
            model = cfg.claude.model;
            timeout = cfg.claude.timeout;
            extra_request_body = {
              temperature = cfg.claude.temperature;
              max_tokens = cfg.claude.maxTokens;
            };
          };
          openai = {
            endpoint = "https://api.openai.com/v1";
            model = cfg.openai.model;
            timeout = cfg.openai.timeout;
            extra_request_body = {
              temperature = cfg.openai.temperature;
              max_tokens = cfg.openai.maxTokens;
            };
          };
        };
      };
    };
  };
}

