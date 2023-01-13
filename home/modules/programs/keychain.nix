{ config, lib, ... }:

with lib;
let cfg = config.my.programs.keychain;
in {
  options.my.programs.keychain = { enable = mkEnableOption "keychain"; };

  config = mkIf cfg.enable {
    programs.keychain = {
      enable = true;
      keys = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
      enableZshIntegration = true;
      enableBashIntegration = false;
      enableFishIntegration = false;
    };
  };
}
