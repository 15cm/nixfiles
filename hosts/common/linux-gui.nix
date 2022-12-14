{ pkgs, lib, hostname, ... }:

with lib;

{
  environment.systemPackages = with pkgs; [
    pavucontrol
    pulseaudio
    xorg.xev
    evtest
    libinput
    mpv
    deploy-rs
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

  # Required by pipewire rt mod and Flatpak.
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
  };

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  services.flatpak.enable = true;
  # Needed by Nautilus.
  services.gvfs.enable = true;

  networking.firewall = {
    # https://docs.syncthing.net/users/firewall.html
    allowedTCPPorts = [ 22000 ];
    allowedUDPPorts = [ 22000 21027 ];
  };

  my.services.docker.enable = true;
  my.services.autofs.enable = true;
  my.programs.AriaNg.enable = true;

  services.printing.enable = true;
  services.avahi.enable = true;
  services.avahi.nssmdns = true;
}
