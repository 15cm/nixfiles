{ nixvimLib, config, lib, state, pkgs, mylib, ... }:

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
        colorschemes.kanagawa.enable = true;
        opts = {
          number = true; # Show line numbers
          relativenumber = true; # Show relative line numbers
          shiftwidth = 2; # Tab width should be 2
          background = state.theme;
          hlsearch = true;
        };
        globals.mapleader = " ";
        keymaps = [
          {
            mode = "n";
            options.silent = true;
            key = "<Esc>";
            action = "<cmd>noh<CR>";
          }
          {
            key = "<leader>ft";
            action = "<cmd>NvimTreeToggle<CR>";
          }
          {
            key = "<leader>ff";
            action = "<cmd>Telescope find_files<CR>";
          }
          {
            key = "<leader>bb";
            action = "<cmd>Telescope buffers<CR>";
          }
          {
            mode = "n";
            key = "<leader>bn";
            action = "<cmd>Telescope buffers<CR>";
          }
          {
            key = "<leader>gg";
            action = "<cmd>Neogit<CR>";
          }
          {
            key = "s";
            action = nixvimLib.mkRaw ''function() require("flash").jump() end'';
            options.desc = "Flash";
          }
        ];

        plugins = {
          "lz-n".enable = true;
          nix = { enable = true; };
          "nvim-tree" = {
            enable = true;
            autoClose = true;
            openOnSetup = true;
          };
          "web-devicons".enable = true;
          telescope = {
            enable = true;
            keymaps = {
              "<A-x>" = { action = "commands"; };
              "<A-c>" = { action = "yank_history"; };
              "<leader>hx" = { action = "commands"; };
            };
          };
          yanky = {
            enable = true;
            enableTelescope = true;
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
          flash = { enable = true; };
          airline = { enable = true; };
        };
      };
    }
    (mkIf cfg.viAlias { programs.zsh.shellAliases = { vi = "nvim"; }; })
  ]);
}
