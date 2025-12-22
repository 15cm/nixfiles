{ nixvimLib, config, lib, pkgs, ... }:

with lib;
let
  cfg = config.my.programs.nvim.textEdit;
  nvimCfg = config.my.programs.nvim;
  spellDir = config.xdg.dataHome + "/nvim/site/spell";
  baseUrl = "https://ftp.nluug.nl/pub/vim/runtime/spell/";
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
        default = "en";
        description = "Spell check language";
      };

      spellfile = mkOption {
        type = types.nullOr types.str;
        default = "${spellDir}/en.utf-8.spl";
        description = "Custom spell file location";
      };
    };
  };

  config = mkIf (nvimCfg.enable && cfg.enable) {
    home.file = mkIf cfg.spell.enable {
      "en-spl" = {
        enable = true;
        source = pkgs.fetchurl {
          url = baseUrl + "/en.utf-8.spl";
          sha256 =
            "sha256-/sq9yUm2o50ywImfolReqyXmPy7QozxK0VEUJjhNMHA="; # Placeholder, will need actual hash
        };
        target = spellDir + "/en.utf8.spl";
      };
    };

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
            key = "<leader>!";
            action = ":set spell!<CR>";
            options.desc = "Spell Check";
          }
          {
            key = "<leader>!n";
            action = "]s";
            options.desc = "Next misspelled word";
          }
          {
            key = "<leader>!p";
            action = "[s";
            options.desc = "Previous misspelled word";
          }
          {
            key = "<leader>!a";
            action = "zg";
            options.desc = "Add word to spell file";
          }
          {
            key = "<leader>!r";
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
      opts = mkIf cfg.spell.enable {
        spell = false;
        spelllang = cfg.spell.spelllang;
      } // (lib.optionalAttrs (cfg.spell.spellfile != null) {
        spellfile = cfg.spell.spellfile;
      });
    };
  };
}

