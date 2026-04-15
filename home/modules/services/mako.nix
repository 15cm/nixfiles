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
        default-timeout = 3000;
        font = "Noto Sans CJK SC 12";
      };
      extraConfig = ''
        [app-name="claude-notify"]
        on-notify=none
        default-timeout=0
        on-button-left=invoke-action focus

        [app-name="codex-notify"]
        on-notify=none
        default-timeout=0
        on-button-left=invoke-action focus
      '';
    };
  };
}
