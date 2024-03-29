{ lib, mylib, ... }:

with lib;
let inherit (mylib) attrsOption;
in {
  options = {
    my.ip = {
      ranges = attrsOption;
      addrs = attrsOption;
    };
  };
  config.my.ip.ranges = {
    local = "127.0.0.1/32";
    lan = "192.168.88.0/24";
    wireguard = "192.168.100.0/24";
    tailscale = "100.64.0.0/10";
    docker = "172.16.0.0/16";
    dockerRootless = "172.20.0.0/16";
  };
}
