{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.my.programs.claude-code;
in {
  options.my.programs.claude-code = {
    enable = mkEnableOption "Claude Code";
  };

  config = mkIf cfg.enable {
    programs.claude-code = {
      enable = true;
    };

    programs.zsh.shellAliases = {
      cc = "claude --dangerously-skip-permissions";
    };
  };
}
