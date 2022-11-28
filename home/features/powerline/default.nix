{ config, lib, pkgs, specialArgs, ... }:

with lib;
let
  colorScheme =
    (if specialArgs.colorScheme == "light" then "solarized-light" else "nord");
in {
  programs.powerline = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      ext = {
        shell = {
          theme = "default";
          local_themes = {
            continuation = "continuation";
            select = "select";
          };
          colorscheme = colorScheme;
        };
        tmux = {
          theme = "default";
          colorscheme = colorScheme;
        };
      };
      # TODO: Verify 24 bit color support of Alacritty
      # Powerline doc: https://powerline.readthedocs.io/en/2.3/configuration/reference.html
      # Alacritty issue: https://github.com/alacritty/alacritty/issues/109
      common = { term_truecolor = false; };
    };

    colors = pipe ./colors.json [ builtins.readFile builtins.fromJSON ];

    colorSchemes = {
      nord =
        pipe ./colorschemes/nord.json [ builtins.readFile builtins.fromJSON ];
      "solarized-light" = pipe ./colorschemes/solarized-light.json [
        builtins.readFile
        builtins.fromJSON
      ];
    };
    colorSchemesShell = {
      nord = pipe ./colorschemes/shell/nord.json [
        builtins.readFile
        builtins.fromJSON
      ];
      "solarized-light" = pipe ./colorschemes/shell/solarized-light.json [
        builtins.readFile
        builtins.fromJSON
      ];
    };
    colorSchemesTmux = {
      nord = pipe ./colorschemes/tmux/nord.json [
        builtins.readFile
        builtins.fromJSON
      ];
      "solarized-light" = pipe ./colorschemes/tmux/solarized-light.json [
        builtins.readFile
        builtins.fromJSON
      ];
    };
    # TODO: Find a way to package these shell theme segments and conditionally loads them:
    # "right": [
    # {
    #     "function": "powerline_pyenv.pyenv",
    #     "priority": 20
    # },
    # {
    #     "function": "powerline_gitstatus.gitstatus",
    #     "priority": 10
    # }
    # ]
    themesShell = {
      default = pipe ./themes/shell/default.json [
        builtins.readFile
        builtins.fromJSON
      ];
    };
    themesTmux = {
      default =
        pipe ./themes/tmux/default.json [ builtins.readFile builtins.fromJSON ];
    };
  };
}
