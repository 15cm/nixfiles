args@{ ... }:

import ../../features/zrepl (args // {
  configTemplatePath = ./zrepl.yaml.jinja;
  sopsCertPath = ./yumiko.machine.15cm.net.crt;
  sopsKeyPath = ./yumiko.machine.15cm.net.key;
})
