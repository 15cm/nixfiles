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
            key = "<leader>;";
            action = "<cmd>Yazi<CR>";
          }
          {
            key = "<leader>ft";
            action = "<cmd>Neotree toggle<CR>";
          }
          {
            key = "<leader>ff";
            action = "<cmd>Telescope find_files<CR>";
          }
          {
            key = "<leader>fr";
            action = "<cmd>Telescope oldfiles<CR>";
          }
          {
            key = "<leader>ss";
            action = "<cmd>Telescope live_grep<CR>";
          }
          {
            key = "<leader>bb";
            action = "<cmd>Telescope buffers<CR>";
          }
          {
            mode = [ "" "!" ];
            key = "<A-c>";
            action = "<cmd>Telescope yank_history<CR>";
          }
          {
            mode = [ "" "!" ];
            key = "<A-x>";
            action = "<cmd>Telescope commands<CR>";
          }
          {
            key = "<leader>bn";
            action = "<cmd>enew<CR>";
          }
          {
            key = "<leader>bd";
            action = "<cmd>bp <BAR> bd #<CR>";
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
          {
            mode = "c";
            key = "<C-s>";
            action =
              nixvimLib.mkRaw ''function() require("flash").toggle() end'';
            options.desc = "Toggle Flash Search";
          }
          {
            key = "<leader>pp";
            action = "<cmd>Telescope projects<CR>";
          }
          {
            key = "<leader>pn";
            action = "<cmd>ProjectAdd<CR>";
          }
          {
            key = "<leader>pd";
            action = "<cmd>ProjectDelete<CR>";
          }
          {
            key = "<leader>p/";
            action = "<cmd>ProjectFzf<CR>";
          }
        ];

        plugins = {
          "lz-n".enable = true;
          nix = { enable = true; };
          "neo-tree" = { enable = true; };
          "web-devicons".enable = true;
          telescope = {
            enable = true;
            extensions = { "file-browser".enable = true; };
          };
          project-nvim = { enable = true; };
          yanky = {
            enable = true;
            enableTelescope = true;
          };
          neogit = {
            enable = true;
            lazyLoad = { settings = { cmd = "Neogit"; }; };
          };
          flash = { enable = true; };
          airline = { enable = true; };
          fzf-lua = { enable = true; };
          yazi = {
            enable = true;
            settings = {
              open_for_directories = true;
              keymaps = false;
              clipboard_register = "";
            };
            lazyLoad = { settings = { cmd = "Yazi"; }; };
            luaConfig.pre = ''
              vim.g.loaded_netrw       = 1
              vim.g.loaded_netrwPlugin = 1
            '';
          };
          which-key = {
            enable = true;
            settings = {
              spec = [
                {
                  __unkeyed-1 = "<leader>b";
                  group = "Buffers";
                }
                {
                  __unkeyed-2 = "<leader>f";
                  group = "Files";
                }
                {
                  __unkeyed-3 = "<leader>p";
                  group = "Projects";
                }
              ];
            };
          };
        };
        extraPlugins = with pkgs.vimPlugins; [ vim-rsi ];
        extraConfigLua = ''
          require("project").setup()
          require("telescope").load_extension("projects")
        '';
      };
    }
    (mkIf cfg.viAlias { programs.zsh.shellAliases = { vi = "nvim"; }; })
  ]);
}
