{ lib, mylib, ... }:

with lib;
let inherit (mylib) attrsOption;
in {
  options = {
    my.ports = {
      gateway = attrsOption;
      zrepl = attrsOption;
      prometheus = attrsOption;
      headscale = attrsOption;
      tailscale = attrsOption;
      grafana = attrsOption;
    };
  };
  config.my.ports.gateway = { listen = 8080; };
  config.my.ports.zrepl = rec {
    asako = { push = sachi.sink; };
    kazuki = { push = sachi.sink; };
    sachi = {
      sink = 38888;
      source = 38889;
    };
    amane = { push = yumiko.sink; };
    yumiko = {
      sink = 38888;
      pull = sachi.source;
    };
  };
  config.my.ports.prometheus = {
    listen = 9090;
    headscale = 9812;
    zrepl = 9811;
  };
  config.my.ports.grafana = { listen = 9290; };
  config.my.ports.headscale = { listen = 7001; };
  config.my.ports.tailscale = { listen = 41641; };
}
