{ nixvimLib, config, lib, ... }:

with lib;
let
  cfg = config.my.programs.nvim.avante;
  nvimCfg = config.my.programs.nvim;
in {
  options.my.programs.nvim.avante = {
    enable = mkEnableOption "Avante AI assistant for Neovim";

    enableFastapply = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Fast Apply feature";
    };

    provider = mkOption {
      type = types.str;
      default = "moonshot";
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
        default = "claude-haiku-4-5-20251001";
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

    gemini = {
      model = mkOption {
        type = types.str;
        default = "gemini-3-flash-preview";
        description = "Gemini model to use";
      };

      timeout = mkOption {
        type = types.int;
        default = 30000;
        description = "Request timeout in milliseconds";
      };

      temperature = mkOption {
        type = types.float;
        default = 0.2;
        description = "Gemini model temperature setting";
      };

      maxTokens = mkOption {
        type = types.int;
        default = 4096;
        description = "Maximum tokens for Gemini responses";
      };
    };

    moonshot = {
      model = mkOption {
        type = types.str;
        default = "kimi-k2-0905-preview";
        description = "Moonshot model to use";
      };

      timeout = mkOption {
        type = types.int;
        default = 30000;
        description = "Request timeout in milliseconds";
      };

      temperature = mkOption {
        type = types.float;
        default = 0.4;
        description = "Moonshot model temperature setting";
      };

      maxTokens = mkOption {
        type = types.int;
        default = 32768;
        description = "Maximum tokens for Moonshot responses";
      };
    };

    morph = {
      model = mkOption {
        type = types.str;
        default = "morph-v3-large";
        description = "Morph model to use";
      };
    };
  };

  config = mkIf (nvimCfg.enable && cfg.enable) {
    # Export API key environment variable
    programs.zsh.initContent = mkOrder 750 ''
      export AVANTE_ANTHROPIC_API_KEY=$(cat ${config.sops.secrets.avanteAnthropicApiKey.path})
      export AVANTE_OPENAI_API_KEY=$(cat ${config.sops.secrets.avanteOpenaiApiKey.path})
      export AVANTE_GEMINI_API_KEY=$(cat ${config.sops.secrets.avanteGeminiApiKey.path})
      export AVANTE_MOONSHOT_API_KEY=$(cat ${config.sops.secrets.avanteMoonshotApiKey.path})
      export MORPH_API_KEY=$(cat ${config.sops.secrets.morphApiKey.path}) '';

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
      {
        key = "<leader>apg";
        action = nixvimLib.mkRaw ''
          function() require("avante.api").switch_provider("gemini") end
        '';
        options.desc = "avante: switch_provider gemini";
      }
      {
        key = "<leader>apm";
        action = nixvimLib.mkRaw ''
          function() require("avante.api").switch_provider("moonshot") end
        '';
        options.desc = "avante: switch_provider moonshot";
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
        behaviour = { enable_fastapply = cfg.enableFastapply; };
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
          gemini = {
            endpoint =
              "https://generativelanguage.googleapis.com/v1beta/models";
            model = cfg.gemini.model;
            timeout = cfg.gemini.timeout;
            extra_request_body = {
              temperature = cfg.gemini.temperature;
              max_tokens = cfg.gemini.maxTokens;
            };
          };
          moonshot = {
            endpoint = "https://api.moonshot.ai/v1";
            model = cfg.moonshot.model;
            timeout = cfg.moonshot.timeout;
            extra_request_body = {
              temperature = cfg.moonshot.temperature;
              max_tokens = cfg.moonshot.maxTokens;
            };
          };
          morph = { model = cfg.morph.model; };
        };
      };
    };
  };
}

