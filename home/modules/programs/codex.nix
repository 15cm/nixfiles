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
  orcaSkills = pkgs.fetchFromGitHub {
    owner = "stablyai";
    repo = "orca";
    rev = "v${pkgs.orca-ide.version}";
    hash = "sha256-DgHpLT8OSf6vG6dBGekIp78Py8alrCsYnzyGF4KF/qk=";
  };
  orcaSkillNames = [
    "computer-use"
    "orca-cli"
    "orca-emulator"
    "orca-emulator-android"
    "orca-linear"
    "orca-per-workspace-env"
    "orchestration"
  ];
  orcaSkillFiles = listToAttrs (map (skill:
    nameValuePair ".agents/skills/${skill}" {
      source = "${orcaSkills}/skills/${skill}";
    })
  orcaSkillNames);
  codexHooksPath = "${config.home.homeDirectory}/.codex/hooks.json";
  inherit (mylib) mkDefaultTrueEnableOption;
  toml = pkgs.formats.toml {};
  codexModels = {
    terra = "gpt-5.6-terra";
    luna = "gpt-5.6-luna";
  };
  defaultCodexModel = "gpt-5.6-sol";
  notificationsEnabled = false;
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
      // orcaSkillFiles
      // {
        ".codex/hooks.json".text = builtins.toJSON {
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
        ".agents/skills/manage-docker-services" = {
          source = ./codex-skills/manage-docker-services;
        };
        ".agents/skills/nix-deploy-rs" = {
          source = ./codex-skills/nix-deploy-rs;
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
        cx = "codex-trusted --profile luna-max";
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

          hooks.state."${codexHooksPath}:session_start:0:0".trusted_hash =
            "sha256:9106e42acfdabf4c89dfa2d44eff9326047a7003afe2ea9ed7ed682f68429135";

          model = defaultCodexModel;
          model_reasoning_effort = "medium";
          plan_mode_reasoning_effort = "high";

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
        // optionalAttrs notificationsEnabled {
          notify = [(lib.getExe pkgs.codex-notify)];
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
