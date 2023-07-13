{ config, lib, pkgs, ... }:

with lib;
let cfg = config.my.programs.pythonDevTools;
in {
  options.my.programs.pythonDevTools = {
    enable = mkEnableOption "pythonDevTools";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      pdm
      pyright
      black
      isort
      python3Packages.docformatter
    ];

    xdg.configFile."pdm/config.toml".text = ''
      check_update = false

      [python]
      use_venv = false
    '';
  };
}
