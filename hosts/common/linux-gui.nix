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
    ventoy
  ];

  # For easy effects https://github.com/nix-community/home-manager/issues/3113
  # Required by pipewire rt mod and Flatpak.
  programs.dconf.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  programs.hyprland = {
    enable = true;
    xwayland = { enable = true; };
  };

  xdg.portal.config.common.default = "*";

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
  my.services.lock = {
    enable = true;
    lockService = "gtklock.service";
  };

  services.printing.enable = true;
  services.avahi.enable = true;
  services.avahi.nssmdns = true;

  systemd.services.restart-network-manager-on-resume = {
    enable = true;
    description = "Restart network manager on system resume";
    serviceConfig = {
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 3";
      ExecStart =
        "${pkgs.systemd}/bin/systemctl restart NetworkManager.service";
      Type = "oneshot";
    };
    after = [ "systemd-suspend.service" "systemd-hibernate.service" ];
    requiredBy = [ "systemd-suspend.service" "systemd-hibernate.service" ];
  };
}
