{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.my.programs.codex;
  caveman = pkgs.caveman;
in {
  options.my.programs.codex = {
    enable = mkEnableOption "Codex";
    enableCLIProxyAPI = mkEnableOption "CLIProxyAPI for Codex";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.codex-notify
      pkgs.codex-trusted
    ];

    home.file.".codex/hooks.json".text = builtins.toJSON {
      hooks = {
        SessionStart = [
          {
            hooks = [
              {
                type = "command";
                command = "echo 'CAVEMAN MODE ACTIVE. Rules: Drop articles/filler/pleasantries/hedging. Fragments OK. Short synonyms. Pattern: [thing] [action] [reason]. [next step]. Not: Sure! I would be happy to help you with that. Yes: Bug in auth middleware. Fix: Code/commits/security: write normal. User says stop caveman or normal mode to deactivate.'";
                statusMessage = "Loading caveman mode...";
                timeout = 10;
              }
            ];
          }
        ];
      };
    };
    home.file.".codex/plugins/caveman" = {
      source = "${caveman}/plugins/caveman";
    };
    home.file.".agents/skills/caveman" = {
      source = "${caveman}/skills/caveman";
    };
    home.file.".agents/skills/caveman-commit" = {
      source = "${caveman}/skills/caveman-commit";
    };
    home.file.".agents/skills/caveman-help" = {
      source = "${caveman}/skills/caveman-help";
    };
    home.file.".agents/skills/caveman-review" = {
      source = "${caveman}/skills/caveman-review";
    };
    home.file.".agents/skills/caveman-compress" = {
      source = "${caveman}/caveman-compress";
    };
    home.file.".codex/auth.json" = mkIf cfg.enableCLIProxyAPI {
      text = builtins.toJSON {
        OPENAI_API_KEY = "sk-dummy";
      };
    };

    programs.zsh.shellAliases = {
      codex = "codex-trusted";
      cx = "codex-trusted";
      cx-deep = "codex-trusted --profile deep";
      cx-fast = "codex-trusted --profile fast";
      cx-offline = "codex-trusted --profile offline";
      cx-quick = "codex-trusted --profile quick";
    };

    programs.codex = {
      enable = true;
      settings =
        {
          features = {
            hooks = true;
            shell_snapshot = true;
            multi_agent = true;
            apps = true;
            skills = true;
            prevent_idle_sleep = true;
            undo = true;
          };

          history = {
            persistence = "save-all";
            max_bytes = 104857600;
          };

          hooks.state."/home/sinkerine/.codex/hooks.json:session_start:0:0".trusted_hash = "sha256:9106e42acfdabf4c89dfa2d44eff9326047a7003afe2ea9ed7ed682f68429135";

          model = "gpt-5.5";
          model_reasoning_effort = "medium";
          plan_mode_reasoning_effort = "high";

          notify = [(lib.getExe pkgs.codex-notify)];
          personality = "pragmatic";

          project_root_markers = [
            ".git"
            ".hg"
            ".sl"
          ];

          approval_policy = "never";
          sandbox_mode = "danger-full-access";

          tui.status_line = [
            "model-with-reasoning"
            "current-dir"
            "context-remaining"
            "context-used"
            "five-hour-limit"
          ];

          profiles = {
            deep = {
              model_reasoning_effort = "high";
              model_verbosity = "high";
              plan_mode_reasoning_effort = "xhigh";
              web_search = "live";
            };

            fast = {
              model_reasoning_effort = "low";
              model_reasoning_summary = "none";
              model_verbosity = "low";
              plan_mode_reasoning_effort = "medium";
              service_tier = "fast";
              web_search = "disabled";
            };

            quick = {
              model = "gpt-5.4";
              model_reasoning_effort = "low";
              model_reasoning_summary = "none";
              model_verbosity = "low";
              plan_mode_reasoning_effort = "medium";
              web_search = "disabled";
            };

            offline = {
              sandbox_workspace_write.network_access = false;
              web_search = "disabled";
            };

          };
        }
        // optionalAttrs cfg.enableCLIProxyAPI {
          model_provider = "cliproxyapi";
          model_providers = {
            cliproxyapi = {
              name = "cliproxyapi";
              base_url = "https://cpa.sachi.m.mado.moe/v1";
              wire_api = "responses";
            };
          };
        };
    };

  };
}
