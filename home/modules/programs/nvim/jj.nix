{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.programs.nvim.jj;
  nvimCfg = config.my.programs.nvim;
in
{
  options.my.programs.nvim.jj = {
    enable = mkEnableOption "jj.nvim integration for Neovim" // {
      default = true;
    };
  };

  config = mkIf (nvimCfg.enable && cfg.enable) {
    programs.nixvim = {
      keymaps = [
        {
          key = "<leader>js";
          action = "<cmd>J status<CR>";
          options.desc = "jj status";
        }
        {
          key = "<leader>jl";
          action = "<cmd>J log<CR>";
          options.desc = "jj log";
        }
        {
          key = "<leader>jd";
          action = "<cmd>J diff<CR>";
          options.desc = "jj diff";
        }
        {
          key = "<leader>jc";
          action = "<cmd>J commit<CR>";
          options.desc = "jj commit";
        }
        {
          key = "<leader>jn";
          action = "<cmd>J new<CR>";
          options.desc = "jj new";
        }
        {
          key = "<leader>jf";
          action = "<cmd>J fetch<CR>";
          options.desc = "jj fetch";
        }
        {
          key = "<leader>jp";
          action = "<cmd>J push<CR>";
          options.desc = "jj push";
        }
        {
          key = "<leader>jb";
          action = "<cmd>Jbrowse<CR>";
          options.desc = "jj browse";
        }
        {
          key = "<leader>jo";
          action = "<cmd>J open_pr<CR>";
          options.desc = "jj open PR";
        }
      ];

      plugins.which-key.settings.spec = [
        {
          __unkeyed-j = "<leader>j";
          group = "Jujutsu";
        }
      ];

      extraPlugins = with pkgs.vimPlugins; [
        jj-nvim
      ];

      extraConfigLua = ''
        require("jj").setup({})
      '';
    };
  };
}
