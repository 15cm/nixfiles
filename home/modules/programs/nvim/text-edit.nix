{ nixvimLib, config, lib, ... }:

with lib;
let
  cfg = config.my.programs.nvim.textEdit;
  nvimCfg = config.my.programs.nvim;
in {
  options.my.programs.nvim.textEdit = {
    enable = mkEnableOption "Text editing enhancements for Neovim" // {
      default = true;
    };

    flash = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Flash jump navigation";
      };

      jumpKey = mkOption {
        type = types.str;
        default = "t";
        description = "Key binding for flash jump";
      };

      toggleKey = mkOption {
        type = types.str;
        default = "<C-/>";
        description = "Key binding for flash toggle in command mode";
      };
    };

    surround = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable nvim-surround for text object manipulation";
      };
    };

    autopairs = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable automatic bracket/quote pairing";
      };
    };

    yanky = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable yanky for enhanced yank/paste functionality";
      };
    };

    wrapping = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable wrapping.nvim for text wrapping functionality";
      };
    };

    spell = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable spell check functionality";
      };

      spelllang = mkOption {
        type = types.str;
        default = "en_us";
        description = "Spell check language";
      };

      spellfile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Custom spell file location";
      };
    };
  };

  config = mkIf (nvimCfg.enable && cfg.enable) {
    programs.nixvim = {
      keymaps = mkMerge [
        (mkIf cfg.flash.enable [
          {
            key = cfg.flash.jumpKey;
            action = nixvimLib.mkRaw ''function() require("flash").jump() end'';
            options.desc = "Flash";
          }
          {
            mode = "c";
            key = cfg.flash.toggleKey;
            action =
              nixvimLib.mkRaw ''function() require("flash").toggle() end'';
            options.desc = "Toggle Flash Search";
          }
        ])
        (mkIf cfg.yanky.enable [{
          mode = [ "" "!" ];
          key = "<A-c>";
          action = "<cmd>Telescope yank_history<CR>";
        }])
        (mkIf cfg.spell.enable [
          {
            key = "<leader>ss";
            action = ":set spell!<CR>";
            options.desc = "Toggle spell check";
          }
          {
            key = "<leader>sn";
            action = "]s";
            options.desc = "Next misspelled word";
          }
          {
            key = "<leader>sp";
            action = "[s";
            options.desc = "Previous misspelled word";
          }
          {
            key = "<leader>sa";
            action = "zg";
            options.desc = "Add word to spell file";
          }
          {
            key = "<leader>sr";
            action = "zw";
            options.desc = "Remove word from spell file";
          }
        ])
      ];

      plugins = {
        flash = mkIf cfg.flash.enable { enable = true; };
        nvim-surround = mkIf cfg.surround.enable { enable = true; };
        nvim-autopairs = mkIf cfg.autopairs.enable { enable = true; };
        yanky = mkIf cfg.yanky.enable {
          enable = true;
          enableTelescope = true;
        };
        wrapping = mkIf cfg.wrapping.enable {
          enable = true;
          settings = {
            auto_set_mode_filetype_allowlist = [ "markdown" "org" ];
            softener = {
              markdown = true;
              org = true;
            };
          };
        };
        multicursors = { enable = true; };
      };

      # Spell check configuration
      opt = mkIf cfg.spell.enable {
        spell = true;
        spelllang = cfg.spell.spelllang;
      } // (lib.optionalAttrs (cfg.spell.spellfile != null) {
        spellfile = cfg.spell.spellfile;
      });
    };
  };
}

