{ pkgs, lib, hostname, ... }:

with lib;

{
  environment.systemPackages = with pkgs; [
    pavucontrol
    pulseaudio
    xorg.xev
    evtest
    mpv
    deploy-rs
    glxinfo
  ];

  hardware.opengl.enable = true;

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
  services.geoclue2.enable = true;

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
  my.services.swaylock.enable = true;

  services.printing.enable = true;
  services.printing.allowFrom = [ "all" ];
  services.avahi.enable = true;
  services.avahi.nssmdns = true;
}
