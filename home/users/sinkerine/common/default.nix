{ config, pkgs, nixinfo, hostname, ... }:

{
  home = rec {
    username = "sinkerine";
    homeDirectory = "/home/${username}";
  };

  home.file."local/bin/switch-nix-home.sh".source =
    let homeFlakeUri = with nixinfo; "path:${projectRoot}#${configName}";
    in pkgs.writeShellScript "switch-nix-home.sh" ''
      home-manager switch "$@" --impure --flake ${homeFlakeUri}
    '';
  home.file."local/bin/switch-nix-os.sh".source =
    let osFlakeUri = with nixinfo; "path:${projectRoot}#${hostname}";
    in pkgs.writeShellScript "switch-nix-os.sh" ''
      sudo nixos-rebuild switch "$@" --flake ${osFlakeUri}
    '';
  home.file."local/bin/build-nix-home.sh".source = let
    homeTopLevelFlakeUri = with nixinfo;
      "path:${projectRoot}#homeConfigurations.${config.home.username}@${hostname}.activationPackage";
  in pkgs.writeShellScript "build-nix-home.sh" ''
    nix build --impure --no-link --print-out-paths "$@" ${homeTopLevelFlakeUri}
  '';
  home.file."local/bin/build-nix-os.sh".source = let
    osTopLevelFlakeUri = with nixinfo;
      "path:${projectRoot}#nixosConfigurations.${hostname}.config.system.build.toplevel";
  in pkgs.writeShellScript "build-nix-os.sh" ''
    nix build --no-link --print-out-paths "$@" ${osTopLevelFlakeUri}
  '';

  imports = [ ../../../common/baseline.nix ../../../features/app/gpg ];
}
