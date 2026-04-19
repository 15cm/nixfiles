{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.my.programs.ai-agent-common;
  agentsTemplate = builtins.readFile ./agents-template.md;
  claudeRtkTemplate = builtins.readFile ./claude-rtk.md;
  codexRtkTemplate = builtins.readFile ./codex-rtk.md;
  codexRtkRef = "@${config.home.homeDirectory}/.codex/RTK.md";
in {
  options.my.programs.ai-agent-common = {
    enable = mkEnableOption "AI agent common configuration";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.rtk ];

    home.file.".codex/AGENTS.md".text = ''
      ${removeSuffix "\n" agentsTemplate}

      ${codexRtkRef}
    '';
    home.file.".codex/RTK.md".text = codexRtkTemplate;

    home.file.".claude/CLAUDE.md".text = ''
      ${removeSuffix "\n" agentsTemplate}

      @RTK.md
    '';
    home.file.".claude/RTK.md".text = claudeRtkTemplate;
  };
}
