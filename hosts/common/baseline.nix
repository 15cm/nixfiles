{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    sops
    systemd
    acpi
    wget
    killall
    pciutils
    openssl
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

  # Bootloader
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 3;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  users.mutableUsers = false;
  time.timeZone = "America/Los_Angeles";
  services.acpid.enable = true;

  system.activationScripts.systemdZshCompletion = ''
    mkdir -p /usr/share/zsh/site-functions
    ln -sf ${pkgs.systemd}/share/zsh/site-functions/* /usr/share/zsh/site-functions/
  '';
}
