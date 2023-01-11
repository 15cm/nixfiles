{ lib, ... }:

with lib; {
  options = {
    my.ports.zrepl = mkOption {
      default = { };
      type = types.attrs;
    };
    my.ports.prometheus = mkOption {
      default = { };
      type = types.attrs;
    };
  };
  config.my.ports.zrepl = rec {
    global = { monitoring = 9811; };
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
  config.my.ports.prometheus = { serve = 9090; };
}
