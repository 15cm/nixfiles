{ nixvimLib, config, lib, ... }:

with lib;
let
  cfg = config.my.programs.nvim.nix;
  nvimCfg = config.my.programs.nvim;
in {
  options.my.programs.nvim.nix = {
    enable = mkEnableOption "Nix language support for Neovim" // {
      default = true;
    };
  };

  config = mkIf (nvimCfg.enable && cfg.enable) {
    programs.nixvim = {
      plugins = {
        nix = { enable = true; };
        conform-nvim.settings.formatters_by_ft.nix = [ "nixfmt" ];
      };

      extraConfigLua = ''
        vim.lsp.enable("nixd")
      '';
    };
  };
}

