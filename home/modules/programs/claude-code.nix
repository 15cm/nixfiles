{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.my.programs.claude-code;
in {
  options.my.programs.claude-code = {
    enable = mkEnableOption "Claude Code";
  };

  config = mkIf cfg.enable {
    home.packages = [pkgs.claude-notify];

    programs.claude-code = {
      enable = true;
      settings = {
        hooks = {
          Stop = [
            {
              matcher = "";
              hooks = [
                {
                  type = "command";
                  command = lib.getExe pkgs.claude-notify;
                }
              ];
            }
          ];
        };
      };
    };

    programs.zsh.shellAliases = {
      cc = "claude --dangerously-skip-permissions";
    };
  };
}
