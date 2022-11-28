{ config, pkgs, ... }:

let commonConfig = (import ../../common/config.nix pkgs);
in {
  programs.tmux = rec {
    enable = true;
    shell = commonConfig.shell.binary;
    sensibleOnTop = true;
    prefix = "F8";
    baseIndex = 1;
    escapeTime = 0;
    historyLimit = 20000;
    keyMode = "vi";
    plugins = with pkgs.tmuxPlugins; [
      resurrect
      continuum
      pain-control
      extrakto
      jump
      # fzf
    ];
    extraConfig = ''
      # Start a non-login shell
      set -g default-command "${shell}"

      # Auto Restore
      set -g @continuum-restore 'on'

      # Tmux jump
      set -g @jump-key 't'

      # Key bindings
      bind z confirm-before "kill-window"
      bind C-c new-session
      bind ^D detach
      # Pane movement
      bind '@' command-prompt -p "join pane from:"  "join-pane -s '%%'"
      bind '#' command-prompt -p "send pane to:" "join-pane -t '%%'"
      # pane rotation
      bind ^K rotate -U
      bind ^J rotate -D
      # Window reordering
      bind < swap-window -t -1\; select-window -t -1
      bind > swap-window -t +1\; select-window -t +1
      # Zoom pane to maximum size.
      bind a "resize-pane -Z"
      # clean history
      bind , send-keys -R \; run "sleep 0.1" \; clear-history
      # TODO(powerline)

      # Copy mode key bindings
      bind-key -T copy-mode-vi v   send -X begin-selection
      bind-key -T copy-mode-vi V   send -X select-line
      bind-key -T copy-mode-vi C-v send -X rectangle-toggle
      bind-key -t vi-copy y copy-pipe "${commonConfig.clipper.copyCommand}"

      # Extrakto
      set -g @extrakto_fzf_tool fzf
      set -g @extrakto_key o
      set -g @extrakto_split_size 20
      set -g @extrakto_fzf_options "\
          --color fg:-1,bg:-1,hl:125,fg+:235,bg+:252,hl+:39 \
          --color info:136,prompt:136,pointer:230,marker:230,spinner:136 \
          -m --reverse --bind=ctrl-d:page-down,ctrl-u:page-up,ctrl-k:kill-line,pgup:preview-page-up,pgdn:preview-page-down,alt-a:toggle-all \
      "
      set -g @extrakto_opts "path/url word lines"
      set -g @extrakto_clip_tool "${commonConfig.clipper.copyCommand}"

      # Press C-q to disable/enable prefix for outer session
      bind -T root C-q  \
        set prefix None \;\
        set key-table off \;\
        refresh-client -S \;\

      bind -T off C-q \
        set -u prefix \;\
        set -u key-table \;\
        refresh-client -S
    '';
  };
}
