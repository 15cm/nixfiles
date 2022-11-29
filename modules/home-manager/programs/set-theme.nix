args@{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.programs.setTheme;
  myLib = (import ../../../lib/options.nix args);
  inputsStr = (builtins.toJSON specialArgs);
in {
  options = {
    programs.setTheme = {
      enable = mkEnableOption "set system theme";
      setThemeCommand = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = ''sed -i "<expr>" <state-file>'';
        description = ''
          Command to modify the theme state file.
          $1, an string that is either "dark" or "light", will be provided as the theme to set. Must be provided.'';
      };
      hmSwitchCommand = mkOption {
        type = types.nullOr types.str;
        default = null;
        example =
          ''home-manager switch --flake "path:$HOME/.nixfiles#username@host"'';
        description =
          "Command to run home manager derivations after changing the theme state file. Must be provided.";
      };
      enableI3Integration = myLib.mkDefaultTrueEnableOption "i3 integration";
      enableI3statusRsIntegration =
        myLib.mkDefaultTrueEnableOption "i3status-rs integration";
      enablePowerlineIntegration =
        myLib.mkDefaultTrueEnableOption "powerline integration";
      enablePowerlineTmuxIntegration =
        myLib.mkDefaultTrueEnableOption "powerline integration";
      enableEmacsIntegration =
        myLib.mkDefaultTrueEnableOption "emacs integration";
    };
  };

  config = let
    i3Reload = (if cfg.enableI3Integration then ''
      i3-msg reload
    '' else
      "");
    i3statusRsReload = (if cfg.enableI3statusRsIntegration then ''
      killall -USR2 i3status-rs
    '' else
      "");
    powerlineReload = (if cfg.enablePowerlineIntegration then ''
      powerline-daemon --replace
    '' else
      "");
    powerlineTmuxReload = (if cfg.enablePowerlineTmuxIntegration then ''
      tmux source ${pkgs.python3Packages.powerline}/share/tmux/powerline.conf
    '' else
      "");
  in mkIf cfg.enable (mkMerge [
    {
      home.file."local/bin/set-theme.sh".source =
        pkgs.writeShellScript "set-theme.sh" ''
          if [ -z $1 ]; then
             echo "Missing required 1st arg: dark/light"
             exit 1
          fi

          ${assert (cfg.setThemeCommand != null); cfg.setThemeCommand}
          ${assert (cfg.hmSwitchCommand != null); cfg.hmSwitchCommand}

          ${i3Reload}
          ${i3statusRsReload}
          ${powerlineReload}
          ${powerlineTmuxReload}
        '';
    }
    {
      programs.zsh.shellAliases = {
        stl = "set-theme.sh light";
        std = "set-theme.sh dark";
      };
    }
  ]);
}
