{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.my.programs.ai-agent-common;
in {
  options.my.programs.ai-agent-common = {
    enable = mkEnableOption "AI agent common configuration";
  };

  config = mkIf cfg.enable {
    home.file.".codex/AGENTS.md".source = ./agents-template.md;
    home.file.".claude/CLAUDE.md".source = ./agents-template.md;
  };
}
