{ config, lib, pkgs, mylib, ... }:

with lib;

let
  configRoot = "${nixinfo.projectRoot}/home/features/app/fcitx5/fcitx5";
  inherit (mylib) mkOutOfStoreSymlinkRecusively;
in {
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [ fcitx5-rime fcitx5-mozc ];
  };

  xdg.configFile =
    mkOutOfStoreSymlinkRecusively config "home/features/app/fcitx5/fcitx5"
    "fcitx5";

  home.file.".local/share/fcitx5/themes/Material-Color-Pink/theme.conf".source =
    pkgs.fetchurl {
      url =
        "https://raw.githubusercontent.com/hosxy/Fcitx5-Material-Color/master/theme-pink.conf";
      hash = "sha256-VbYvwAb3pxyReFzl7j3eqqUsMuSY32+XlEhBNb12ZRc=";
    };
}
