{ config, pkgs, lib, mylib, hostname, ... }:

with lib;

{
  system.stateVersion = "22.05";
  imports = [
    ./hardware-configuration.nix
    ../common/baseline.nix
    ../common/boot-loader.nix
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
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  my.essentials.zfs = {
    enable = true;
    enableNonRootEncryption = true;
    enableZed = true;
    nonRootPools = [ "main" "sub" ];
    encryptedZfsPath = "main";
  };

  networking = {
    hostName = hostname;
    domain = "mado.moe";
    useDHCP = true;
    # Delegate home firewall to the router.
    firewall.enable = mkForce false;
    # Disable the 1G NIC to make sure the 10G NIC is always used.
    interfaces.eno1.useDHCP = false;
    interfaces.eno2.useDHCP = false;
    interfaces.eno3.useDHCP = false;
    interfaces.eno4.useDHCP = false;
  };

  my.services.docker = { enable = true; };
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
    lanOnlyIpRanges = [
      config.my.ip.ranges.local
      config.my.ip.ranges.lan
      config.my.ip.ranges.wireguard
      config.my.ip.ranges.tailscale
      config.my.ip.ranges.docker
      config.my.ip.ranges.dockerRootless
    ];
  };
  services.traefik.dynamicConfigOptions.http.middlewares.mastodon-auth-proxy.redirectRegex =
    {
      permanent = true;
      regex = "^https://mado.moe/\\.well-known/webfinger";
      replacement = "https://mastodon.mado.moe/.well-known/webfinger";
    };
  my.services.headscale.enable = true;
  my.services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
  };

  my.services.smartd.enable = true;
  my.services.metrics = {
    enable = true;
    enableScrapeHeadscale = true;
    enableScrapeSmartctl = true;
  };
  my.services.monitoring = {
    enable = true;
    domain = "monitoring.${hostname}.m.mado.moe";
    datasourceHosts = [ "sachi" "kazuki" "amane" "yumiko" "asako" ];
    dataDir = "/pool/main/appdata/grafana";
  };
  my.services.aria2 = {
    enable = true;
    downloadDir = "/pool/sub/download/aria2";
    enableSession = true;
    enableReverseProxy = true;
  };
  my.services.vsftpd = {
    enable = true;
    enableSsl = true;
    sopsCertFile = ./ftp/vsftpd.pem;
    sopsKeyFile = ./ftp/vsftpd.key;
  };
}
