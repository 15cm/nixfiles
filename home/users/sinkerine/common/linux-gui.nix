args@{ pkgs, ... }: {
  imports = [
    # Essentials
    # TODO: switch to the pkgs.emacsPgtkNativeComp when the nixfiles repo is stable. The Pgtk variant needs to compile from Emacs head and it takes a while.
    (import ../../../features/app/emacs
      (args // { withArgs.packageOverride = pkgs.emacsNativeComp; }))
    ../../../features/conf/ssh
    # XSession related
    ../../../features/conf/xsession
    ../../../features/conf/xresources
    ../../../features/conf/keychain
    ../../../features/conf/fontconfig
    ../../../features/app/i3
    # Applications
    ../../../features/app/alacritty
    ../../../features/conf/mpv
    ../../../features/app/redshift
    ../../../features/app/rofi
    ../../../features/app/picom
    ../../../features/app/aria2
  ];
}
