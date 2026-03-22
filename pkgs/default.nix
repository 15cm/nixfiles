{ pkgs ? null, ... }:

with pkgs; {
  clipper = callPackage ./clipper { };
  codex-notify = callPackage ./codex-notify { };
  i3-quickterm = callPackage ./i3-quickterm { };
  AriaNg = callPackage ./AriaNg { };
  sarasa-gothic-nerdfont = (callPackage ./sarasa-gothic-nerdfont { });
  iosevka-nerdfont = (callPackage ./iosevka-nerdfont { });
  khinsider = (callPackage ./khinsider { });
  feishin-appimage = (callPackage ./feishin-appimage { });
  lsp-ai = (callPackage ./lsp-ai { });
  tmux-fzf = (callPackage ./tmux-fzf { });
  webos-dev-manager = (callPackage ./webos-dev-manager { });
}
