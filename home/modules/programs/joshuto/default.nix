{ config, pkgs, lib, mylib, state, ... }:

with lib;
let
  cfg = config.my.programs.joshuto;
  inherit (mylib) writeShellScriptFile;
in {
  options.my.programs.joshuto = { enable = mkEnableOption "joshuto"; };
  config = mkIf cfg.enable {
    home.packages = with pkgs; [ bat ueberzugpp ];
    home.file."local/bin/joshuto-wrapped".source =
      writeShellScriptFile "joshuto" ./joshuto.sh;
    xdg.configFile = {
      "joshuto/on_preview_shown.sh".source =
        writeShellScriptFile "joshuto-on_preview_shown" ./on_preview_shown.sh;
      "joshuto/on_preview_removed.sh".source =
        writeShellScriptFile "joshuto-on_preview_removed"
        ./on_preview_removed.sh;
      "joshuto/preview_file.sh".source =
        writeShellScriptFile "joshuto-preview_file" ./preview_file.sh;
    };
    programs.joshuto = {
      enable = true;
      settings = {
        preview = {
          max_preview_size = 20971520;
          # This is the script that will be ran whenever a preview needs to be generated
          preview_script = "~/.config/joshuto/preview_file.sh";

          preview_shown_hook_script = "~/.config/joshuto/on_preview_shown.sh";

          # This script is ran whenever the preview selection changes.
          # Usually used to cleanup the old preview.
          preview_removed_hook_script =
            "~/.config/joshuto/on_preview_removed.sh";
        };
      };
      theme = if state.theme == "light" then {
        regular.fg = "light_grey";
        directory = {
          fg = "grey";
          bold = true;
        };
        selection = {
          bg = "black";
          bold = true;
        };
        visual_mode_selection = {
          fg = "yellow";
          bold = true;
        };
        link = {
          fg = "light_magenta";
          bold = true;
        };
      } else {
        regular.fg = "grey";
        directory = {
          fg = "light_blue";
          bold = true;
        };
        selection = {
          bg = "cyan";
          bold = true;
        };
        visual_mode_selection = {
          fg = "yellow";
          bold = true;
        };
        link = {
          fg = "light_magenta";
          bold = true;
        };
      };
    };
  };
}
