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
      aria2 = attrsOption;
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
    zrepl = 9811;
    headscale = 9812;
    nut = 9813;
    node = 9814;
    smartctl = 9815;
  };
  config.my.ports.grafana = { listen = 9290; };
  config.my.ports.headscale = { listen = 7001; };
  config.my.ports.tailscale = { listen = 41641; };
  config.my.ports.aria2 = { listen = 6800; };
}
