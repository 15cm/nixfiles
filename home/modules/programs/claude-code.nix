{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.my.programs.claude-code;
  caveman = pkgs.caveman;
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

    home.file.".claude/skills/caveman" = {
      source = "${caveman}/skills/caveman";
    };
    home.file.".claude/skills/caveman-commit" = {
      source = "${caveman}/skills/caveman-commit";
    };
    home.file.".claude/skills/caveman-help" = {
      source = "${caveman}/skills/caveman-help";
    };
    home.file.".claude/skills/caveman-review" = {
      source = "${caveman}/skills/caveman-review";
    };
    home.file.".claude/skills/caveman-compress" = {
      source = "${caveman}/caveman-compress";
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
        };
        statusLine = {
          type = "command";
          command = "if [ -f ~/.claude/hooks/caveman-statusline.sh ]; then bash ~/.claude/hooks/caveman-statusline.sh; fi";
        };
      };
    };

    programs.zsh.shellAliases = {
      cc = "claude";
    };
  };
}
