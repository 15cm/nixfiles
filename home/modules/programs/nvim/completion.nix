{ nixvimLib, config, lib, mylib, ... }:

with lib;
let
  cfg = config.my.programs.nvim;
  completionCfg = cfg.completion;
in {
  options.my.programs.nvim.completion = {
    enable = mylib.mkDefaultTrueEnableOption "Completion";
  };

  config = mkIf (cfg.enable && completionCfg.enable) {
    programs.nixvim = {
      plugins = {
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
                  ['<Up>'] = cmp.mapping.select_prev_item(),
                  ['<Down>'] = cmp.mapping.select_next_item(),
                  ['<S-Tab>'] = cmp.mapping.select_prev_item(),
                  ['<Tab>'] = cmp.mapping.select_next_item(),
                  ['<C-Space>'] = cmp.mapping.complete(),
                  ['<C-g>'] = cmp.mapping.close(),
                  ['<CR>'] = cmp.mapping.confirm({ select = false }),
                }
              '';
            };
          };
        };
        cmp-nvim-lsp = { enable = true; };
        cmp-buffer = { enable = true; };
        cmp-path = { enable = true; };
      };
    };
  };
}

