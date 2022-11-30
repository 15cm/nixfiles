{ pkgs, ... }:

let
  colorPalette = {
    base03 = "234";
    base02 = "235";
    base01 = "240";
    base00 = "241";
    base0 = "244";
    base1 = "245";
    base2 = "252";
    base3 = "230";
    yellow = "136";
    orange = "166";
    red = "160";
    magenta = "125";
    violet = "61";
    blue = "33";
    cyan = "39";
    green = "64";
  };
in {
  programs.fzf = {
    enable = true;
    defaultCommand = "fd";
    enableZshIntegration = true;
    enableBashIntegration = false;
    enableFishIntegration = false;
    defaultOptions = [
      "--height 40%"
      "-m"
      "--reverse"
      "--bind"
      "pgdn:page-down,pgup:page-up,ctrl-k:kill-line,ctrl-u:preview-page-up,ctrl-d:preview-page-down,alt-a:toggle-all"
    ];
    colors = {
      fg = "-1";
      "fg+" = colorPalette.base02;
      bg = "-1";
      "bg+" = colorPalette.base02;
      hl = colorPalette.magenta;
      "hl+" = colorPalette.cyan;
    };
    fileWidgetOptions = [
      "--preview '(([ -f {} ] && (highlight -O ansi -l {} 2> /dev/null || cat {})) || ([ -d {} ] && $_tree_cmd {} )) | head -200'"
    ];
    changeDirWidgetOptions = [ "--preview '$_tree_cmd {} | head -200'" ];
    historyWidgetOptions = [
      "--exact"
      "--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview'"
    ];
  };

  home.packages = [ pkgs.fd ];
}
