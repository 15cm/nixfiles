args@{ ... }:

import ../../features/app/zrepl (args // {
  configTemplatePath = ./zrepl.yaml.jinja;
  sopsCertPath = ./asako.machine.mado.moe.crt;
  sopsKeyPath = ./asako.machine.mado.moe.key;
})
