{ nixvimLib, config, lib, pkgs, ... }:

with lib;
let
  cfg = config.my.programs.nvim.clipper;
  nvimCfg = config.my.programs.nvim;
in {
  options.my.programs.nvim.clipper = {
    enable = mkEnableOption "Clipper integration for Neovim" // {
      default = true;
    };

    autocmd = mkOption {
      type = types.bool;
      default = false;
      description = "Enable automatic clipboard integration";
    };
  };

  config = mkIf (nvimCfg.enable && cfg.enable) {
    programs.nixvim = {
      keymaps = [
        {
          mode = [ "" "!" ];
          key = "<C-y>";
          action = nixvimLib.mkRaw ''require("wincent.clipper.clip") '';
        }
      ];

      extraPlugins = with pkgs.vimPlugins; [
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

      extraConfigLua = ''
        require('wincent.clipper').setup({
          autocmd = ${boolToString cfg.autocmd}
        })
      '';
    };
  };
}

