args@{ pkgs, config, ... }:

let commonConfig = (import ../../common/config.nix args);
in {
  programs.setTheme = {
    enable = true;
    setThemeCommand = ''
      sed -i "s/\(colorScheme.*\)\"[^\"]*\"/\1\"$1\"/" ${commonConfig.nix.projectRoot}/home/state/default.nix
    '';
    hmSwitchCommand =
      "home-manager switch --flake ${commonConfig.nix.flakeUri}";
  };
}
