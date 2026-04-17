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
        format = "%s\n%b";
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
  };
}
