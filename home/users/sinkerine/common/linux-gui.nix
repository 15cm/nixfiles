args@{ pkgs, ... }: {
  imports = [
    # Essentials
    # TODO: switch to the pkgs.emacsPgtkNativeComp when the nixfiles repo is stable. The Pgtk variant needs to compile from Emacs head and it takes a while.
    (import ../../../features/emacs
      (args // { withArgs.packageOverride = pkgs.emacsNativeComp; }))
    # XSession related
    ../../../features/xresources
    ../../../features/keychain
    ../../../features/x-dotfiles
    ../../../features/fontconfig
    ../../../features/i3
    # Applications
    ../../../features/alacritty
    ../../../features/ssh
  ];
}
