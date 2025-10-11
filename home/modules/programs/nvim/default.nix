{ config, lib, pkgs, ... }:

with lib;
let cfg = config.my.programs.nvim;
in {
  options.my.programs.nvim = { enable = mkEnableOption "Neo Vim"; };
  config = mkIf cfg.enable {
    programs.nixvim = {
      enable = true;
      globals.mapleader = " ";
      keymaps = [{
        key = "<leader>ft";
        action = "<cmd>NvimTreeToggle<CR>";
      }];
      plugins = {
        "lz-n".enable = true;
        nix = { enable = true; };
        "nvim-tree" = {
          enable = true;
          lazyLoad = {
            settings = {
              cmd = "NvimTreeToggle";
              keys = [ "<leader>ft" ];
            };
          };
        };
        "web-devicons".enable = true;
        telescope = {
          enable = true;
          keymaps = {
            "<A-x>" = { action = "commands"; };
            "<leader>hx" = { action = "commands"; };
          };
        };
      };
    };
  };
}
