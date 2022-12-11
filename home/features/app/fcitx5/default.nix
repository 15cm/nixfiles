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
}
