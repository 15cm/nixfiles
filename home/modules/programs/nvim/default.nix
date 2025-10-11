{ config, lib, state, pkgs, mylib, ... }:

with lib;
let cfg = config.my.programs.nvim;
in {
  options.my.programs.nvim = {
    enable = mkEnableOption "Neo Vim";
    viAlias = mylib.mkDefaultTrueEnableOption "Vi Alias";
  };
  config = mkIf cfg.enable (mkMerge [
    {
      programs.nixvim = {
        enable = true;
        colorschemes.tokyonight.enable = true;
        opts = {
          number = true; # Show line numbers
          relativenumber = true; # Show relative line numbers
          shiftwidth = 2; # Tab width should be 2
          background = state.theme;
        };
        globals.mapleader = " ";
        keymaps = [
          {
            key = "<leader>ft";
            action = "<cmd>NvimTreeToggle<CR>";
          }
          {
            key = "<leader>gg";
            action = "<cmd>Neogit<CR>";
          }
        ];
        plugins = {
          "lz-n".enable = true;
          nix = { enable = true; };
          "nvim-tree" = {
            enable = true;
            openOnSetup = true;
          };
          "web-devicons".enable = true;
          telescope = {
            enable = true;
            keymaps = {
              "<A-x>" = { action = "commands"; };
              "<leader>hx" = { action = "commands"; };
            };
          };
          neogit = {
            enable = true;
            lazyLoad = {
              settings = {
                cmd = "Neogit";
                keys = [ "<leader>gg" ];
              };
            };
          };
        };
      };
    }
    (mkIf cfg.viAlias { programs.zsh.shellAliases = { vi = "nvim"; }; })
  ]);
}
