{ pkgs, ... }:

{
  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-emoji
    inconsolata-lgc
    (nerdfonts.override { fonts = [ "Noto" "InconsolataLGC" ]; })
  ];

  services.xserver = {
    enable = true;

    displayManager = {
      xserverArgs = [ "-ardelay" "300" "-arinterval" "22" ];
      lightdm = { enable = true; };
    };
  };
}
