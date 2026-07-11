{
  config,
  lib,
  pkgs,
  mylib,
  ...
}:
with lib; let
  cfg = config.my.programs.codex;
  caveman = pkgs.caveman;
  tmuxAgentSidebarHook = "${pkgs.tmux-agent-sidebar}/share/tmux-plugins/agent-sidebar/hook.sh";
  tmuxAgentSidebarCommand = event:
    "${lib.getExe pkgs.bash} ${tmuxAgentSidebarHook} codex ${event}";
  tmuxAgentSidebarHookConfig = event: matcher: {
    inherit matcher;
    hooks = [
      {
        type = "command";
        command = tmuxAgentSidebarCommand event;
      }
    ];
  };
  tmuxAgentSidebarTrustedHash = eventName: event: matcher:
    "sha256:${builtins.hashString "sha256" (builtins.toJSON ({
      event_name = eventName;
      hooks = [
        {
          type = "command";
          command = tmuxAgentSidebarCommand event;
          timeout = 600;
          async = false;
        }
      ];
    } // optionalAttrs (matcher != null) { inherit matcher; }))}";
  codexHooksPath = "${config.home.homeDirectory}/.codex/hooks.json";
  inherit (mylib) mkDefaultTrueEnableOption;
  toml = pkgs.formats.toml {};
  codexModels = {
    terra = "gpt-5.6-terra";
    luna = "gpt-5.6-luna";
  };
  defaultCodexModel = "gpt-5.6-sol";
  reasoningEfforts = [
    "medium"
    "high"
    "xhigh"
    "max"
  ];
  reasoningProfiles = builtins.listToAttrs (flatten (mapAttrsToList (
      modelName: model:
        map (effort:
          nameValuePair "${modelName}-${effort}" {
            inherit model;
            model_reasoning_effort = effort;
            plan_mode_reasoning_effort = effort;
          })
        reasoningEfforts
    )
    codexModels));
  defaultReasoningProfiles = builtins.listToAttrs (map (effort:
      nameValuePair effort {
        model = defaultCodexModel;
        model_reasoning_effort = effort;
        plan_mode_reasoning_effort = effort;
      })
    reasoningEfforts);
  ultraProfiles = mapAttrs' (modelName: model:
    nameValuePair "${modelName}-ultra" {
      inherit model;
      model_reasoning_effort = "ultra";
      plan_mode_reasoning_effort = "ultra";
    })
  codexModels;
  defaultUltraProfile = {
    ultra = {
      model = defaultCodexModel;
      model_reasoning_effort = "ultra";
      plan_mode_reasoning_effort = "ultra";
    };
  };
  codexProfiles = defaultReasoningProfiles // defaultUltraProfile // reasoningProfiles // ultraProfiles;
  codexProfileFiles = mapAttrs' (profileName: profileSettings:
    nameValuePair ".codex/${profileName}.config.toml" {
      source = toml.generate "${profileName}.config.toml" profileSettings;
    })
  codexProfiles;
  codexProfileAliases = mapAttrs' (profileName: _:
    nameValuePair "cx-${profileName}" "codex-trusted --profile ${profileName}")
  codexProfiles;
in {
  options.my.programs.codex = {
    enable = mkEnableOption "Codex";
    enableCLIProxyAPI = mkDefaultTrueEnableOption "CLIProxyAPI for Codex";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.codex-notify
      pkgs.codex-trusted
    ];

    home.file =
      codexProfileFiles
      // {
        ".codex/hooks.json".text = builtins.toJSON {
          hooks = {
            PostToolUse = [
              (tmuxAgentSidebarHookConfig "activity-log" "")
            ];
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
              (tmuxAgentSidebarHookConfig "session-start" "startup|resume")
            ];
            Stop = [
              (tmuxAgentSidebarHookConfig "stop" "")
            ];
            UserPromptSubmit = [
              (tmuxAgentSidebarHookConfig "user-prompt-submit" "")
            ];
          };
        };
        ".codex/plugins/caveman" = {
          source = "${caveman}/plugins/caveman";
        };
        ".agents/skills/caveman" = {
          source = "${caveman}/skills/caveman";
        };
        ".agents/skills/caveman-commit" = {
          source = "${caveman}/skills/caveman-commit";
        };
        ".agents/skills/caveman-help" = {
          source = "${caveman}/skills/caveman-help";
        };
        ".agents/skills/caveman-review" = {
          source = "${caveman}/skills/caveman-review";
        };
        ".agents/skills/caveman-compress" = {
          source = "${caveman}/caveman-compress";
        };
      }
      // optionalAttrs cfg.enableCLIProxyAPI {
        ".codex/auth.json".text = builtins.toJSON {
          OPENAI_API_KEY = "sk-dummy";
        };
      };

    programs.zsh.shellAliases =
      {
        codex = "codex-trusted";
        cx = "codex-trusted --profile medium";
      }
      // codexProfileAliases;

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

          hooks.state = {
            "${codexHooksPath}:post_tool_use:0:0".trusted_hash =
              tmuxAgentSidebarTrustedHash "post_tool_use" "activity-log" "";
            "${codexHooksPath}:session_start:0:0".trusted_hash =
              "sha256:9106e42acfdabf4c89dfa2d44eff9326047a7003afe2ea9ed7ed682f68429135";
            "${codexHooksPath}:session_start:1:0".trusted_hash =
              tmuxAgentSidebarTrustedHash "session_start" "session-start" "startup|resume";
            "${codexHooksPath}:stop:0:0".trusted_hash =
              tmuxAgentSidebarTrustedHash "stop" "stop" null;
            "${codexHooksPath}:user_prompt_submit:0:0".trusted_hash =
              tmuxAgentSidebarTrustedHash "user_prompt_submit" "user-prompt-submit" null;
          };

          model = defaultCodexModel;
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
