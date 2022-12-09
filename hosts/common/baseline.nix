{ pkgs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  users.mutableUsers = false;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  environment.systemPackages = with pkgs; [ systemd ];

  system.activationScripts.systemdZshCompletion = ''
    mkdir -p /usr/share/zsh/site-functions
    ln -sf ${pkgs.systemd}/share/zsh/site-functions/* /usr/share/zsh/site-functions/
  '';
}
