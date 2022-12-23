args@{ ... }:

import ../../features/zrepl (args // {
  configTemplatePath = ./zrepl.yaml.jinja;
  sopsCertPath = ./sachi.machine.mado.moe.crt;
  sopsKeyPath = ./sachi.machine.mado.moe.key;
})
