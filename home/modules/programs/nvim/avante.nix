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
      default = "claude-haiku";
      description = "AI provider to use (claude-sonnet, openai, etc.)";
    };

    instructionsFile = mkOption {
      type = types.str;
      default = "avante.md";
      description = "Instructions file for Avante";
    };

    claude-sonnet = {
      model = mkOption {
        type = types.str;
        default = "claude-sonnet-4-5-20250929";
        description = "Claude Sonnet model to use";
      };

      timeout = mkOption {
        type = types.int;
        default = 30000;
        description = "Request timeout in milliseconds";
      };

      temperature = mkOption {
        type = types.float;
        default = 0.2;
        description = "Claude Sonnet model temperature setting";
      };

      maxTokens = mkOption {
        type = types.int;
        default = 4096;
        description = "Maximum tokens for Claude Sonnet responses";
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

    claude-haiku = {
      model = mkOption {
        type = types.str;
        default = "claude-haiku-4-5-20251001";
        description = "Claude Haiku model to use";
      };

      timeout = mkOption {
        type = types.int;
        default = 30000;
        description = "Request timeout in milliseconds";
      };

      temperature = mkOption {
        type = types.float;
        default = 0.2;
        description = "Claude Haiku model temperature setting";
      };

      maxTokens = mkOption {
        type = types.int;
        default = 4096;
        description = "Maximum tokens for Claude Haiku responses";
      };
    };

    gemini = {
      model = mkOption {
        type = types.str;
        default = "gemini-2.5-flash";
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
  };

  config = mkIf (nvimCfg.enable && cfg.enable) {
    # Export API key environment variable
    programs.zsh.initContent = mkOrder 750 ''
      export AVANTE_ANTHROPIC_API_KEY=$(cat ${config.sops.secrets.avanteAnthropicApiKey.path})
      export AVANTE_OPENAI_API_KEY=$(cat ${config.sops.secrets.avanteOpenaiApiKey.path})
      export AVANTE_GEMINI_API_KEY=$(cat ${config.sops.secrets.avanteGeminiApiKey.path}) '';

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
          function() require("avante.api").switch_provider("claude-sonnet") end
        '';
        options.desc = "avante: switch_provider claude-sonnet";
      }
      {
        key = "<leader>apg";
        action = nixvimLib.mkRaw ''
          function() require("avante.api").switch_provider("gemini") end
        '';
        options.desc = "avante: switch_provider gemini";
      }
      {
        key = "<leader>aph";
        action = nixvimLib.mkRaw ''
          function() require("avante.api").switch_provider("claude-haiku") end
        '';
        options.desc = "avante: switch_provider claude-haiku";
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
          claude-sonnet = {
            endpoint = "https://api.anthropic.com";
            model = cfg.claude-sonnet.model;
            timeout = cfg.claude-sonnet.timeout;
            extra_request_body = {
              temperature = cfg.claude-sonnet.temperature;
              max_tokens = cfg.claude-sonnet.maxTokens;
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
          claude-haiku = {
            endpoint = "https://api.anthropic.com";
            model = cfg.claude-haiku.model;
            timeout = cfg.claude-haiku.timeout;
            extra_request_body = {
              temperature = cfg.claude-haiku.temperature;
              max_tokens = cfg.claude-haiku.maxTokens;
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
        };
      };
    };
  };
}

