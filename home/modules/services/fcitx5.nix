{ config, lib, pkgs, ... }:

with lib;
let cfg = config.my.services.fcitx5;
in {
  options.my.services.fcitx5 = { enable = mkEnableOption "Fcitx5"; };

  config = mkIf cfg.enable {
    i18n.inputMethod = {
      enabled = "fcitx5";
      fcitx5.addons = with pkgs; [ fcitx5-rime fcitx5-mozc ];
    };
    home.file.".local/share/fcitx5/themes/Material-Color-Pink/theme.conf".source =
      pkgs.fetchurl {
        url =
          "https://raw.githubusercontent.com/hosxy/Fcitx5-Material-Color/2256feeae48dcc87f19a3cfe98f171862f8fcace/theme-pink.conf";
        hash = "sha256-VbYvwAb3pxyReFzl7j3eqqUsMuSY32+XlEhBNb12ZRc=";
      };
  };
}
