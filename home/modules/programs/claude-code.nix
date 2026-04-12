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
      };
    };

    programs.zsh.shellAliases = {
      cc = "claude '/caveman'";
      ccp = "claude";
    };
  };
}
