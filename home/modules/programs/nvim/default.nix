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
        colorschemes.kanagawa = { enable = true; };
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
            key = "<leader><leader>c";
            action = "<cmd>Telescope colorscheme<CR>";
          }
          {
            key = "<leader>;";
            action = "<cmd>Yazi<CR>";
          }
          {
            key = "<leader>;";
            action = "<cmd>Yazi<CR>";
          }
          {
            key = "<leader>:";
            action = "<cmd>Yazi toogle<CR>";
          }
          {
            key = "<leader>'";
            action = "<cmd>Yazi cwd<CR>";
          }
          {
            key = "<leader>ft";
            action = "<cmd>Neotree toggle<CR>";
          }
          {
            key = "<leader>ff";
            action = nixvimLib.mkRaw ''
              function()
                local fb = require("telescope").extensions.file_browser.file_browser
                local utils = require("telescope.utils")
                fb { cwd = utils.buffer_dir() }
              end
            '';
          }
          {
            key = "<leader>fr";
            action = "<cmd>Telescope oldfiles<CR>";
          }
          {
            key = "<leader>ss";
            action = "<cmd>Telescope current_buffer_fuzzy_find<CR>";
          }
          {
            key = "<leader>sS";
            action = nixvimLib.mkRaw ''
              function()
                require("telescope.builtin").current_buffer_fuzzy_find {
                  default_text = table.concat(get_selection())
                }
              end
            '';
          }
          {
            key = "<leader>sd";
            action = nixvimLib.mkRaw ''
              function()
                local lg = require("telescope.live_grep")
                local utils = require("telescope.utils")
                lg { cwd = utils.buffer_dir() }
              end
            '';
          }
          {
            key = "<leader>sD";
            action = nixvimLib.mkRaw ''
              function()
                local lg = require("telescope.live_grep")
                local utils = require("telescope.utils")
                lg {
                  cw= utils.buffer_dir(), 
                  default_text = table.concat(get_selection())
                }
              end
            '';
          }
          {
            key = "<leader>,";
            action = "<cmd>Telescope buffers<CR>";
          }
          {
            key = "<leader>.";
            action = "<cmd>Telescope find_files<CR>";
          }
          {
            key = "<leader>/";
            action = "<cmd>Telescope live_grep<CR>";
          }
          {
            key = "<leader>*";
            action = nixvimLib.mkRaw ''
              function()
                require("telescope.builtin").live_grep {
                  default_text = table.concat(get_selection())
                }
              end
            '';
            options.desc = "Telescope live_grep selection";
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
            mode = [ "" "!" ];
            key = "<C-s>";
            action = "<cmd>up<CR>";
          }
          {
            mode = [ "" "!" ];
            key = "<C-y>";
            action = nixvimLib.mkRaw ''require("wincent.clipper.clip") '';
          }
          {
            key = "<leader>bb";
            action = "<cmd>Telescope buffers<CR>";
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
            key = "t";
            action = nixvimLib.mkRaw ''function() require("flash").jump() end'';
            options.desc = "Flash";
          }
          {
            mode = "c";
            key = "<C-/>";
            action =
              nixvimLib.mkRaw ''function() require("flash").toggle() end'';
            options.desc = "Toggle Flash Search";
          }
          {
            key = "<leader>pp";
            action = "<cmd>Telescope projects<CR>";
          }
          {
            key = "<leader>pa";
            action = "<cmd>ProjectAdd<CR>";
          }
          {
            key = "<leader>pd";
            action = "<cmd>ProjectDelete<CR>";
          }
          {
            key = "<leader>ca";
            action = nixvimLib.mkRaw "vim.lsp.buf.code_action";
          }
          {
            key = "<leader>cd";
            action = "<cmd>Telescope diagnostics<CR>";
          }
        ];

        plugins = {
          lz-n.enable = true;
          noice.enable = true;
          nix = { enable = true; };
          orgmode = { enable = true; };
          neo-tree = { enable = true; };
          web-devicons.enable = true;
          telescope = {
            enable = true;
            extensions = {
              file-browser.enable = true;
              fzf-native = {
                enable = true;
                settings = {
                  case_mode = "smart_case";
                  fuzzy = true;
                };
              };
            };
            settings = {
              defaults = {
                mappings = {
                  i = {
                    "<ESC>" =
                      nixvimLib.mkRaw "require('telescope.actions').close";
                    "<C-h>" = "which_key";
                  };
                };
              };
            };
          };
          treesitter = {
            enable = true;
            folding = true;
            settings = {
              # NOTE: You can set whether `nvim-treesitter` should automatically install the grammars.
              auto_install = false;
              ensure_installed = [
                "git_config"
                "git_rebase"
                "gitattributes"
                "gitcommit"
                "gitignore"
              ];
            };
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
          gitblame = {
            enable = true;
            lazyLoad = { settings = { cmd = "GitBlameToggle"; }; };
          };
          flash = { enable = true; };
          airline = {
            enable = true;
            settings.theme = "tomorrow";
          };
          auto-session = { enable = true; };
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
                  __unkeyed-b = "<leader>b";
                  group = "Buffers";
                }
                {
                  __unkeyed-c = "<leader>c";
                  group = "Buffers";
                }
                {
                  __unkeyed-f = "<leader>f";
                  group = "Files";
                }
                {
                  __unkeyed-p = "<leader>p";
                  group = "Projects";
                }
                {
                  __unkeyed-leader = "<leader><leader>";
                  group = "Misc";
                }
              ];
            };
          };
          nvim-autopairs = { enable = true; };
          rainbow = { enable = true; };
          nvim-surround = { enable = true; };
          lspconfig = { enable = true; };
          cmp = {
            enable = true;
            autoEnableSources = true;
            settings = {
              sources = [
                { name = "nvim_lsp"; }
                { name = "path"; }
                { name = "buffer"; }
              ];
              mapping = {
                __raw = ''
                  {
                    ['<Up>'] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select}),
                    ['<Down>'] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select}),
                    ['<S-Tab>'] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert}),
                    ['<Tab>'] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert}),
                    ['<C-Space>'] = cmp.mapping.complete(),
                    ['<C-g>'] = cmp.mapping.close(),
                    ['<CR>'] = cmp.mapping.confirm({ select = true }),
                  }
                '';
              };
            };
          };
          cmp-nvim-lsp = { enable = true; };
          cmp-buffer = { enable = true; };
          cmp-path = { enable = true; };
          conform-nvim = {
            enable = true;
            settings = {
              formatters_by_ft = { nix = [ "nixfmt" ]; };
              format_on_save = {
                timeout_ms = 500;
                lsp_format = "fallback";
              };
            };
          };
          highlight-colors.enable = true;
        };
        extraPlugins = with pkgs.vimPlugins; [
          vim-rsi
          vim-airline-themes
          (pkgs.vimUtils.buildVimPlugin rec {
            pname = "nvim-clipper";
            version = "0.1";
            src = pkgs.fetchFromGitHub rec {
              owner = "wincent";
              repo = "nvim-clipper";
              rev = version;
              sha256 = "sha256-usaYu9Cd+/oXgKMDu76FGAqLW41NitX/Jfl0AptTNI0=";
            };
          })
        ];
        extraConfigLuaPre = ''
          get_selection = function()
            return vim.fn.getregion(
              vim.fn.getpos ".", vim.fn.getpos "v", { mode = vim.fn.mode() }
            )
          end
          vim.o.termguicolors = true
        '';
        extraConfigLua = ''
          require("project").setup()
          require("telescope").load_extension("projects")
          require("auto-session").setup({})
          vim.lsp.enable("nixd")
          require('wincent.clipper').setup({
            autocmd = false
          })
        '';
        dependencies = {
          git.enable = true;
          fzf.enable = true;
          ripgrep.enable = true;
          gcc.enable = true;
        };
      };
    }
    (mkIf cfg.viAlias { programs.zsh.shellAliases = { vi = "nvim"; }; })
  ]);
}
