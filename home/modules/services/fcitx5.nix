{ config, lib, pkgs, ... }:

with lib;
let cfg = config.my.services.fcitx5;
in {
  options.my.services.fcitx5 = {
    enable = mkEnableOption "Fcitx5";

    package = mkOption {
      type = types.package;
      default = pkgs.fcitx5-with-addons.override {
        addons = with pkgs; [
          (fcitx5-rime.override {
            librime =
              config.nur.repos.xddxdd.lantianCustomized.librime-with-plugins;
          })
          fcitx5-mozc
        ];
      };
    };
  };

  config = mkIf cfg.enable {

    home.sessionVariables = {
      GLFW_IM_MODULE = "ibus"; # IME support in kitty
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
      XMODIFIERS = "@im=fcitx";
      QT_PLUGIN_PATH =
        "${cfg.package}/${pkgs.qt6.qtbase.qtPluginPrefix}:\${QT_PLUGIN_PATH}";
    };

    home.file.".local/share/fcitx5/themes/Material-Color-Pink/theme.conf".source =
      pkgs.fetchurl {
        url =
          "https://raw.githubusercontent.com/hosxy/Fcitx5-Material-Color/2256feeae48dcc87f19a3cfe98f171862f8fcace/theme-pink.conf";
        hash = "sha256-VbYvwAb3pxyReFzl7j3eqqUsMuSY32+XlEhBNb12ZRc=";
      };
    systemd.user.services.fcitx5-daemon = {
      Unit = {
        Description = "Fcitx5 input method editor";
        PartOf = mkForce [ "tray.target" ];
        After = mkForce [ "tray.target" ];
      };
      Service.ExecStart = "${cfg.package}/bin/fcitx5";
      Install.WantedBy = mkForce [ "tray.target" ];
    };
  };
}
