{ config, lib, pkgs, ... }:

with lib;
let cfg = config.programs.zsh.zimfw;
in {
  options.programs.zsh.zimfw = {
    enable = mkEnableOption "Zim";
    modules = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = "List of Zim modules";
    };
    package = mkOption {
      type = types.package;
      default = pkgs.zimfw;
    };
    zimHome = mkOption {
      type = types.path;
      default = "${config.home.homeDirectory}/.local/share/zim";
      defaultText = "~/.local/share/zim";
    };
    zimConfigFile = mkOption {
      type = types.path;
      default = "${config.home.homeDirectory}/.zimrc";
      defaultText = "~/.zimrc";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    home.file.${cfg.zimConfigFile}.text = ''
      ${optionalString (cfg.modules != [ ]) ''
        ${concatStringsSep "\n" (map (m: "zmodule ${m}") cfg.modules)}
      ''}
    '';
    programs.zsh.initExtraBeforeCompInit = ''
      export ZIM_HOME=${cfg.zimHome};
      export ZIM_CONFIG_FILE=${cfg.zimConfigFile};
      zstyle ':zim:zmodule' use 'degit'
      if [[ ! $ZIM_HOME/init.zsh -nt $ZIM_CONFIG_FILE ]]; then
        source ${pkgs.zimfw}/zimfw.zsh init -q
      fi
      source $ZIM_HOME/init.zsh
    '';
  };
}
