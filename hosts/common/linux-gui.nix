{ pkgs, ... }:

{
  services.xserver = {
    enable = true;

    libinput = {
      enable = true;
      touchpad = {
        disableWhileTyping = true;
        naturalScrolling = true;
        additionalOptions = ''
          Option "PalmDetection" "True"
        '';
      };
    };

    displayManager = {
      xserverArgs = [ "-ardelay" "300" "-arinterval" "22" ];
      autoLogin = {
        enable = true;
        user = "sinkerine";
      };
      lightdm = { enable = true; };
    };
    desktopManager.session = [{
      name = "xsession";
      start = ''
        ${pkgs.runtimeShell} $HOME/.xsession &
        waitPID=$!
      '';
    }];
  };

  hardware.video.hidpi.enable = true;
}
