{ pkgs, ... }:

let package = pkgs.easyeffects;
in {
  services.easyeffects = {
    enable = true;
    preset = "Perfect-EQ";
  };

  xdg.configFile."easyeffects/output/Perfect-EQ.json".source = pkgs.fetchurl {
    url =
      "https://raw.githubusercontent.com/JackHack96/EasyEffects-Presets/master/Perfect%20EQ.json";
    hash = "sha256-LhXdj97iFgBouAbcxfabksSBJO/AouHPv1rcy2Zx9zI=";
  };
}
