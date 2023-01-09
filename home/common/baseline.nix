{ config, pkgs, state, nixinfo, hostname, ... }:

let parallel = pkgs.parallel-full.override (old: { willCite = true; });
in {
  programs.home-manager.enable = true;

  imports = [
    ../features/app/git
    ../features/app/vim
    ../features/app/tmux
    ../features/app/zsh
    ../features/app/navi
    ../features/app/powerline
    ../features/app/fzf
    ../features/app/set-theme
    ../features/app/tealdeer
    ../features/conf/misc-dotfiles
  ];

  home.packages = (with pkgs; [
    nixfmt
    exa
    fd
    nix-template
    xclip
    htop
    lsof
    ripgrep
    silver-searcher
    ueberzug
    bind
    cloc
    hunspell
    hunspellDicts.en_US-large
    direnv
  ]) ++
    # Packages with overrides.
    [ parallel ];

  my.programs.emacs.enable = true;
  programs.bottom = {
    enable = true;
    settings = {
      flags = {
        color = (if state.theme == "light" then "gruvbox-light" else "gruvbox");
      };
    };
  };
  my.programs.ranger.enable = true;

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
      "path:${projectRoot}#homeConfigurations.${configName}.activationPackage";
  in pkgs.writeShellScript "build-nix-home.sh" ''
    nix build --impure --no-link --print-out-paths "$@" ${homeTopLevelFlakeUri}
  '';
  home.file."local/bin/build-nix-os.sh".source = let
    osTopLevelFlakeUri = with nixinfo;
      "path:${projectRoot}#nixosConfigurations.${hostname}.config.system.build.toplevel";
  in pkgs.writeShellScript "build-nix-os.sh" ''
    nix build --no-link --print-out-paths "$@" ${osTopLevelFlakeUri}
  '';
}
