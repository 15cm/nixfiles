{ pkgs, ... }:

{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters =
      [ "https://nix-community.cachix.org" "https://cache.nixos.org/" ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
  users.mutableUsers = false;

  environment.systemPackages = with pkgs; [ systemd ];

  system.activationScripts.systemdZshCompletion = ''
    mkdir -p /usr/share/zsh/site-functions
    ln -sf ${pkgs.systemd}/share/zsh/site-functions/* /usr/share/zsh/site-functions/
  '';
}
