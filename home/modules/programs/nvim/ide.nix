{ nixvimLib, config, lib, ... }:

with lib;
let
  cfg = config.my.programs.nvim.ide;
  nvimCfg = config.my.programs.nvim;
in {
  options.my.programs.nvim.ide = {
    enable = mkEnableOption "IDE features for Neovim" // { default = true; };
  };

  config = mkIf (nvimCfg.enable && cfg.enable) {
    programs.nixvim = {
      plugins.trouble = { enable = true; };

      keymaps = [{
        key = "<leader>xx";
        action = "<cmd>Trouble<CR>";
        options.desc = "Trouble";
      }];
    };
  };
}
