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
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.codex-notify
      pkgs.codex-trusted
    ];

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

    programs.zsh.shellAliases = {
      codex = "codex-trusted";
      cx = "codex-trusted '$caveman'";
      cxp = "codex-trusted";
      cx-deep = "codex-trusted --profile deep '$caveman'";
      cxp-deep = "codex-trusted --profile deep";
      cx-fast = "codex-trusted --profile fast '$caveman'";
      cxp-fast = "codex-trusted --profile fast";
      cx-offline = "codex-trusted --profile offline '$caveman'";
      cxp-offline = "codex-trusted --profile offline";
      cx-quick = "codex-trusted --profile quick '$caveman'";
      cxp-quick = "codex-trusted --profile quick";
      cx-unsafe = "codex-trusted --profile unsafe '$caveman'";
      cxp-unsafe = "codex-trusted --profile unsafe";
    };

    programs.codex = {
      enable = true;
      enableMcpIntegration = true;
      settings = {
        features = {
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

        model = "gpt-5.4";
        model_reasoning_effort = "medium";
        plan_mode_reasoning_effort = "high";

        notify = [(lib.getExe pkgs.codex-notify)];
        personality = "pragmatic";

        project_root_markers = [
          ".git"
          ".jj"
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
            model_reasoning_effort = "low";
            model_reasoning_summary = "none";
            model_verbosity = "low";
            plan_mode_reasoning_effort = "medium";
            service_tier = "fast";
            web_search = "disabled";
          };

          offline = {
            sandbox_workspace_write.network_access = false;
            web_search = "disabled";
          };

          unsafe = {
            approval_policy = "never";
            sandbox_mode = "danger-full-access";
            shell_environment_policy.ignore_default_excludes = true;
          };
        };
      };
    };

  };
}
