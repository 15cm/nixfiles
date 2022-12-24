{ pkgs, lib, hostname, ... }:

with lib;

{
  imports = [ ../features/autofs ../features/docker ../features/AriaNg ];
  environment.systemPackages = with pkgs; [
    pavucontrol
    pulseaudio
    xorg.xev
    evtest
    libinput
    mpv
  ];

  services.xserver = {
    enable = true;

    libinput = { enable = true; };

    displayManager = {
      xserverArgs = [ "-ardelay" "300" "-arinterval" "22" ];
      autoLogin = {
        enable = true;
        user = "sinkerine";
      };
      lightdm = { enable = true; };
      defaultSession = "none+i3";
      session = [{
        manage = "window";
        name = "i3";
        start = ''
          ${pkgs.runtimeShell} $HOME/.xsession &
          waitPID=$!
        '';
      }];
    };
  };

  # Adjust DPIs by myself.
  hardware.video.hidpi.enable = mkForce false;

  # For easy effects https://github.com/nix-community/home-manager/issues/3113
  programs.dconf.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Required by pipewire rt mod.
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
  };

  hardware.bluetooth.enable = true;
  # Needed by Nautilus.
  services.gvfs.enable = true;

  # For web apps.
  services.nginx.enable = true;

  networking.firewall = {
    # https://docs.syncthing.net/users/firewall.html
    allowedTCPPorts = [ 22000 ];
    allowedUDPPorts = [ 22000 21027 ];
  };
}
