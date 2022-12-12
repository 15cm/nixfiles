{ pkgs, lib, hostname, ... }:

with lib;

{
  environment.systemPackages = with pkgs; [
    pavucontrol
    pulseaudio
    xorg.xev
    evtest
    libinput
  ];
  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-emoji
    inconsolata-lgc
    font-awesome_4
    dejavu_fonts
    (nerdfonts.override { fonts = [ "Noto" "InconsolataLGC" ]; })
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

  hardware.bluetooth.enable = true;
}
