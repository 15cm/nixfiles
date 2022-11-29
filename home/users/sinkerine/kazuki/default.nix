args@{ pkgs, ... }:

{
  home.stateVersion = "22.05";

  imports = [
    ../common
    # TODO: switch to the pkgs.emacsPgtkNativeComp when the nixfiles repo is stable. The Pgtk variant needs to compile from Emacs head and it takes a while.
    (import ../../../features/emacs
      (args // { withArgs.packageOverride = pkgs.emacsNativeComp; }))
    ../../../features/xresources
    ../../../features/x-dotfiles
    ../../../features/fontconfig
    ../../../features/alacritty
    ../../../features/keychain
    ../../../features/i3
  ];
}
