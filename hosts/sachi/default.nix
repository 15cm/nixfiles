{ config, pkgs, lib, mylib, hostname, ... }:

with lib;

{
  system.stateVersion = "22.05";
  imports = [
    ./hardware-configuration.nix
    ../common/baseline.nix
    ../common/systemd-boot.nix
    ../common/zfs
    ../common/zfs/encrypted-non-root.nix
    ../common/users.nix
    ./samba
  ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = { hashedPassword.neededForUsers = true; };
    age = {
      keyFile = "/keys/age/${hostname}.txt";
      sshKeyPaths = [ ];
    };
    # https://github.com/Mic92/sops-nix/issues/167
    gnupg.sshKeyPaths = [ ];
  };

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    kbdInteractiveAuthentication = false;
    permitRootLogin = "prohibit-password";
  };

  networking = {
    hostName = hostname;
    domain = "mado.moe";
    useDHCP = true;
    # Delegate home firewall to the router.
    firewall.enable = mkForce false;
  };

  my.services.docker = {
    enable = true;
    waitForManualZfsLoadKey = true;
  };
  my.services.zrepl = {
    enable = true;
    ports = { inherit (config.my.ports.zrepl.sachi) sink source; };
    openFirewallForPorts = [ "sink" "source" ];
    configTemplateFile = ./zrepl/zrepl.yaml.jinja;
    sopsCertFile = ./zrepl/sachi.m.mado.moe.crt;
    sopsKeyFile = ./zrepl/sachi.m.mado.moe.key;
  };

  my.services.gateway = {
    enable = true;
    enableDocker = true;
    internalDomain = "${hostname}.m.mado.moe";
    externalDomain = "mado.moe";
  };
  services.traefik.dynamicConfigOptions.http.middlewares.mastodon-auth-proxy.redirectRegex =
    {
      permanent = true;
      regex = "^https://mado.moe/\\.well-known/webfinger";
      replacement = "https://mastodon.mado.moe/.well-known/webfinger";
    };
  my.services.headscale.enable = true;
  my.services.tailscale.enable = true;

  my.services.metrics = {
    enable = true;
    enableScrapeHeadscale = true;
    enableScrapeNut = true;
  };
  my.services.monitoring = {
    enable = true;
    domain = "monitoring.${hostname}.m.mado.moe";
    dataDir = "/pool/main/appdata/grafana";
    waitForManualZfsLoadKey = true;
  };
  my.services.ups.enable = true;
}
