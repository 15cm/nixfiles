{
  config,
  lib,
  ...
}:
let
  cfg = config.my.services.mako;
in
{
  options.my.services.mako = {
    enable = lib.mkEnableOption "mako";
  };

  config = lib.mkIf cfg.enable {
    services.mako = {
      enable = true;
      settings = {
        default-timeout = 10000;
        font = "sans-serif 10";
        format = "%s\\n%b";
        height = 300;
        width = 420;
        ignore-timeout = true;
        markup = false;
        max-history = 100;
      };
      extraConfig = ''
        [app-name="claude-notify"]
        on-notify=none
        default-timeout=0
        on-button-left=invoke-default-action

        [app-name="codex-notify"]
        on-notify=none
        default-timeout=0
        on-button-left=invoke-default-action
      '';
    };

    # Mask the user unit entirely after Home Manager writes files. Keep D-Bus
    # activation path from the package, but block systemd user unit startup.
    home.activation.maskMakoUserService = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.config/systemd/user"
      ln -snf /dev/null "$HOME/.config/systemd/user/mako.service"
    '';
  };
}
