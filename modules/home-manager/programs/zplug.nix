{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.zsh.my-zplug;

  pluginModule = types.submodule ({ config, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        description = "The name of the plugin.";
      };

      tags = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "The plugin tags.";
      };
    };

  });

in {
  options.programs.zsh.my-zplug = {
    enable = mkEnableOption "zplug - a zsh plugin manager";

    plugins = mkOption {
      default = [ ];
      type = types.listOf pluginModule;
      description = "List of zplug plugins.";
    };

    zplugHome = mkOption {
      type = types.path;
      default = "${config.home.homeDirectory}/.zplug";
      defaultText = "~/.zplug";
      apply = toString;
      description = "Path to zplug home directory.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.zplug ];

    # Load plugins first so zshrc can override config later, e.g. key bindings of zsh-vi-mode. Plugin env vars should go to zsh.sessionVariables (not a good practice to put things in .zshenv though).
    programs.zsh.initExtraFirst = ''
      export ZPLUG_HOME=${cfg.zplugHome}

      source ${pkgs.zplug}/share/zplug/init.zsh

      ${optionalString (cfg.plugins != [ ]) ''
        ${concatStrings (map (plugin: ''
          zplug "${plugin.name}"${
            optionalString (plugin.tags != [ ]) ''
              ${concatStrings (map (tag: ", ${tag}") plugin.tags)}
            ''
          }
        '') cfg.plugins)}
      ''}

      if ! zplug check; then
        zplug install
      fi

      zplug load
    '';

  };
}
