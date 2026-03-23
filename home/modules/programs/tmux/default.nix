{ config, pkgs, lib, mylib, ... }:

with lib;
let
  cfg = config.my.programs.tmux;
  inherit (mylib) templateFile;
  templateData = {
    tmuxFzfScriptsDir = "${pkgs.tmux-fzf}/share/tmux-plugins/tmux-fzf/scripts";
    inherit (config.home) sessionVariables;
    inherit (config.my.services.clipper) copyCommand;
  };
in {

  options.my.programs.tmux = { enable = mkEnableOption "Tmux"; };

  config = mkIf cfg.enable {
    programs.zsh.shellAliases = {
      ta = "tmux attach -t";
      tad = "tmux attach -d -t";
      ts = "tmux new -A -s";
      tl = "tmux list-sessions";
      tksv = "tmux kill-server";
      tkss = "tmux kill-session -t";
    };
    programs.tmux = rec {
      enable = true;
      shell = "$SHELL";
      sensibleOnTop = true;
      prefix = "F8";
      baseIndex = 1;
      escapeTime = 0;
      historyLimit = 50000;
      keyMode = "vi";
      terminal = "tmux";
      plugins =
        (with pkgs.tmuxPlugins; [
          sensible
          resurrect
          extrakto
          jump
        ])
        ++ [
          pkgs.tmux-fzf
          pkgs.tmux-omni-search
        ]
        ++ (with pkgs.tmuxPlugins; [
        # tmux-continuum should be last so its status-right hook keeps autosave working.
          continuum
        ]);
    };
    # Place my config between mkBefore and mkDefault
    xdg.configFile."tmux/tmux.conf".text = pipe ./tmux.conf.jinja [
      (templateFile "tmux.conf" templateData)
      builtins.readFile
      (mkOrder 600)
    ];
  };
}
