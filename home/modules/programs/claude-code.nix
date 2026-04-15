{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.my.programs.claude-code;
  guiEnabled = config.my.essentials.gui.enable;
  caveman = pkgs.caveman;
  ccstatusline = pkgs.ccstatusline;
  claude-notify = pkgs.claude-notify;
  jujutsu-skill = pkgs.jujutsu-skill;
in {
  options.my.programs.claude-code = {
    enable = mkEnableOption "Claude Code";
  };

  config = mkIf cfg.enable {
    home.file.".claude/hooks" = {
      source = "${caveman}/hooks";
    };

    home.file.".claude/commands" = {
      source = "${caveman}/commands";
    };

    programs.claude-code.skills = {
      caveman = "${caveman}/skills/caveman";
      caveman-commit = "${caveman}/skills/caveman-commit";
      caveman-help = "${caveman}/skills/caveman-help";
      caveman-review = "${caveman}/skills/caveman-review";
      caveman-compress = "${caveman}/caveman-compress";
      jujutsu = "${jujutsu-skill}/skills/jujutsu";
    };

    programs.claude-code = {
      enable = true;
      settings = {
        permissions.defaultMode = "bypassPermissions";
        includeCoAuthoredBy = false;
        skipDangerousModePermissionPrompt = true;
        hooks = {
          SessionStart = [
            {
              hooks = [
                {
                  type = "command";
                  command = "if [ -f ~/.claude/hooks/caveman-activate.js ]; then node ~/.claude/hooks/caveman-activate.js; fi";
                  timeout = 5;
                  statusMessage = "Loading caveman mode...";
                }
              ];
            }
          ];
          UserPromptSubmit = [
            {
              hooks = [
                {
                  type = "command";
                  command = "if [ -f ~/.claude/hooks/caveman-mode-tracker.js ]; then node ~/.claude/hooks/caveman-mode-tracker.js; fi";
                  timeout = 5;
                  statusMessage = "Tracking caveman mode...";
                }
              ];
            }
          ];
        } // optionalAttrs guiEnabled {
          Stop = [
            {
              hooks = [
                {
                  type = "command";
                  command = "${lib.getExe claude-notify}";
                  background = true;
                }
              ];
            }
          ];
          Notification = [
            {
              hooks = [
                {
                  type = "command";
                  command = "${lib.getExe claude-notify}";
                  timeout = 5;
                }
              ];
            }
          ];
        };
        statusLine = {
          type = "command";
          command = "${lib.getExe ccstatusline}";
        };
      };
    };

    programs.zsh.shellAliases = {
      cc = "claude";
    };
  };
}
