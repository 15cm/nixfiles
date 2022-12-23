args@{ ... }:

import ../../features/zrepl (args // {
  configTemplatePath = ./zrepl.yaml.jinja;
  sopsCertPath = ./kazuki.machine.mado.moe.crt;
  sopsKeyPath = ./kazuki.machine.mado.moe.key;
})
