{ pkgs, lib, hostname, ... }:

with lib;

{
  environment.systemPackages = with pkgs; [
    exfat
    exfatprogs
    pavucontrol
    pulseaudio
    xorg.xev
    evtest
    mpv
    deploy-rs
    glxinfo
    ventoy
    # support both 32- and 64-bit applications
    wineWowPackages.stable
    # winetricks (all versions)
    winetricks
    # native wayland support (unstable)
    wineWowPackages.waylandFull
    ryujinx
  ];

  fonts.packages = with pkgs; [ noto-fonts ];
  fonts.fontconfig.enable = false;

  # For easy effects https://github.com/nix-community/home-manager/issues/3113
  # Required by pipewire rt mod and Flatpak.
  programs.dconf.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  programs.hyprland = {
    enable = true;
    xwayland = { enable = true; };
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    config.common.default = "*";
  };

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  services.geoclue2.enable = true;

  services.flatpak.enable = true;
  # Needed by Nautilus.
  services.gvfs.enable = true;

  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark;
  };

  my.services.docker.enable = true;
  my.services.autofs.enable = true;
  my.services.aria2 = {
    enable = true;
    downloadDir = "/home/sinkerine/Downloads";
    enableSession = true;
    enableReverseProxy = true;
  };
  my.programs.AriaNg.enable = true;

  services.printing = {
    enable = true;
    drivers = with pkgs; [ hplip ];
  };
  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;

  system.activationScripts.linkBinaries = ''
    ln -sf ${pkgs.mpv}/bin/mpv /usr/bin/mpv
  '';

  # systemd.services.restart-network-manager-on-resume = {
  #   enable = true;
  #   description = "Restart network manager on system resume";
  #   serviceConfig = {
  #     ExecStartPre = "${pkgs.coreutils}/bin/sleep 3";
  #     ExecStart =
  #       "${pkgs.systemd}/bin/systemctl restart NetworkManager.service";
  #     Type = "oneshot";
  #   };
  #   after = [ "systemd-suspend.service" "systemd-hibernate.service" ];
  #   requiredBy = [ "systemd-suspend.service" "systemd-hibernate.service" ];
  # };
  # For QMK Flashing of Ergodox EZ https://github.com/zsa/docs/issues/14
  services.udev.extraRules = ''
    # UDEV rules for Teensy USB devices
    ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", ENV{ID_MM_DEVICE_IGNORE}="1"
    ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789A]?", ENV{MTP_NO_PROBE}="1"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789ABCD]?", MODE:="0666"
    KERNEL=="ttyACM*", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", MODE:="0666"
  '';
}
