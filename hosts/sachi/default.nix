{ config, pkgs, lib, mylib, hostname, ... }:

with lib;

{
  system.stateVersion = "22.05";
  imports = [
    ./generated/hardware-configuration.nix
    ./generated/extra-configuration.nix
    ../common/baseline.nix
    ../common/systemd-boot.nix
    ../common/zfs
    ../common/zfs/non-root.nix
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
  my.services.gateway.enable = true;
  my.services.nix-serve.enable = true;
  my.services.zrepl = {
    enable = true;
    ports = { inherit (config.my.ports.zrepl.sachi) sink source; };
    openFirewallForPorts = [ "sink" "source" ];
    configTemplateFile = ./zrepl/zrepl.yaml.jinja;
    sopsCertFile = ./zrepl/sachi.machine.mado.moe.crt;
    sopsKeyFile = ./zrepl/sachi.machine.mado.moe.key;
  };
}
