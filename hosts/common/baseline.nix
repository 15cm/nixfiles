{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    sops
    acpi
    wget
    killall
    pciutils
    openssl
    sops
    gnupg
    age
  ];

  nix = {
    gc = {
      automatic = true;
      options = "--delete-older-than 14d";
      dates = "weekly";
    };
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      substituters =
        [ "https://nix-community.cachix.org" "https://cache.nixos.org/" ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };

  users.mutableUsers = false;
  time.timeZone = "America/Los_Angeles";
  services.acpid.enable = true;

  system.activationScripts.systemdZshCompletion = ''
    mkdir -p /usr/share/zsh/site-functions
    ln -sf ${config.systemd.package}/share/zsh/site-functions/* /usr/share/zsh/site-functions/
  '';
  system.activationScripts.linkTzdata = ''
    if ! [ -L /usr/share/zoneinfo ]; then
      mkdir -p /usr/share
      ln -sf ${pkgs.tzdata}/share/zoneinfo /usr/share/zoneinfo
    fi
  '';

  boot.kernel.sysctl = {
    "vm.max_map_count" = 262144;
    "fs.inotify.max_user_watches" = 200000;
  };

  networking.firewall.enable = true;
}
