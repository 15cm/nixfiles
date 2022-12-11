{ pkgs, nixinfo, hostname, ... }:

{
  home = rec {
    username = "sinkerine";
    homeDirectory = "/home/${username}";
  };

  home.file."local/bin/switch-nix-home.sh".source =
    let homeFlakeUri = with nixinfo; "path:${projectRoot}#${configName}";
    in pkgs.writeShellScript "switch-nix-home.sh"
    "home-manager switch --impure --flake ${homeFlakeUri}";
  home.file."local/bin/switch-nix-os.sh".source =
    let osFlakeUri = with nixinfo; "path:${projectRoot}#${hostname}";
    in pkgs.writeShellScript "switch-nix-os.sh"
    "sudo nixos-rebuild switch --flake ${osFlakeUri}";

  imports = [ ../../../common/baseline.nix ../../../features/app/gpg ];
}
