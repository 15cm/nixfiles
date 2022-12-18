{ pkgs, config, mylib, hostname, lib, ... }:

with lib;
let
  inherit (mylib) templateFile;
  templateData = { inherit hostname; };
in {
  xsession = {
    enable = true;
    profileExtra = pipe ./xprofile.sh.jinja [
      (templateFile "xprofile" templateData)
      builtins.readFile
    ];
  };

  home.sessionVariables = {
    PATH = "${config.home.homeDirectory}/.nix-profile/bin:$PATH";
  };

  xsession.importedVariables = [
    "PATH"
    "DISPLAY"
    "XAUTHORITY"
    "QT_QPA_PLATFORMTHEME"
    "GTK2_RC_FILES"
    "XCURSOR_PATH"
    "QT_SCREEN_SCALE_FACTORS"
    "QT_AUTO_SCREEN_SCALE_FACTOR"
    "GDK_SCALE"
    "GDK_DPI_SCALE"
    "WINIT_HIDPI_FACTOR"
    "INPUT_METHOD"
    "GTK_IM_MODULE"
    "QT_IM_MODULE"
    "XMODIFIERS"
    "XDG_RUNTIME_DIR"
    "DBUS_SESSION_BUS_ADDRESS"
  ];

  home.file.".imwheelrc".source = ./imwheelrc;

  services.screen-locker = {
    enable = true;
    lockCmd = "${pkgs.betterlockscreen}/bin/betterlockscreen -l";
    inactiveInterval = (if hostname == "asako" then 60 else 180);
  };

  # Cursor icons.
  home.file.".icons/default".source =
    "${pkgs.vanilla-dmz}/share/icons/Vanilla-DMZ";

  home.packages = with pkgs; [ betterlockscreen nitrogen ];
}
