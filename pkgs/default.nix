{ pkgs ? null, tmux-omni-search, ... }:

with pkgs; {
  notify-lib = callPackage ./notify-lib { };
  ergodox-layout = callPackage ./ergodox-layout { };
  ccstatusline = callPackage ./ccstatusline { };
  clipper = callPackage ./clipper { };
  caveman = callPackage ./caveman { };
  jujutsu-skill = callPackage ./jujutsu-skill { };
  claude-notify = callPackage ./claude-notify { };
  codex-trusted = callPackage ./codex-trusted { };
  codex-notify = callPackage ./codex-notify { };
  i3-quickterm = callPackage ./i3-quickterm { };
  AriaNg = callPackage ./AriaNg { };
  sarasa-gothic-nerdfont = (callPackage ./sarasa-gothic-nerdfont { });
  iosevka-nerdfont = (callPackage ./iosevka-nerdfont { });
  khinsider = (callPackage ./khinsider { });
  feishin-appimage = (callPackage ./feishin-appimage { });
  lsp-ai = (callPackage ./lsp-ai { });
  tmux-fzf = (callPackage ./tmux-fzf { });
  tmux-omni-search = tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-omni-search";
    rtpFilePath = "tmux-omni-search.tmux";
    version = "unstable-${builtins.substring 0 8 (tmux-omni-search.lastModifiedDate or "19700101")}";

    src = "${tmux-omni-search.packages.${stdenv.hostPlatform.system}.default}/share/tmux-plugins/tmux-omni-search";

    meta = {
      homepage = "https://github.com/sinkerine/tmux-omni-search";
      description = "Popup-based tmux pane full-text search plugin";
      license = lib.licenses.mit;
      platforms = lib.platforms.unix;
    };
  };
  webos-dev-manager = (callPackage ./webos-dev-manager { });
  xurl = (callPackage ./xurl { });
}
