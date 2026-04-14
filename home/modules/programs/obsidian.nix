{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.my.programs.obsidian;
  obsidianCliSkillDir = pkgs.linkFarm "obsidian-cli-skill" [
    {
      name = "SKILL.md";
      path = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/kepano/obsidian-skills/main/skills/obsidian-cli/SKILL.md";
        hash = "sha256-tUJXzcDl0ESIs1sMeXv+QnskNZ8ISNPHOSTcrPjaY1g=";
      };
    }
  ];
in {
  options.my.programs.obsidian = {
    enable = mkEnableOption "Obsidian";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [pkgs.obsidian];
    }
    (mkIf config.my.programs.claude-code.enable {
      home.file.".claude/skills/obsidian-cli".source = obsidianCliSkillDir;
    })
    (mkIf config.my.programs.codex.enable {
      home.file.".agents/skills/obsidian-cli".source = obsidianCliSkillDir;
    })
  ]);
}
