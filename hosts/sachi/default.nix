{ config, pkgs, lib, mylib, hostname, ... }:

with lib;

{
  system.stateVersion = "22.05";
  imports = [
    ./generated/hardware-configuration.nix
    ./generated/extra-configuration.nix
    ../common/baseline.nix
    ../common/zfs.nix
    ../common/users/sinkerine.nix
    ../features/app/docker
  ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = { hashedPassword.neededForUsers = true; };
    age = {
      keyFile = "/keys/age/sachi.txt";
      sshKeyPaths = [ ];
    };
    # https://github.com/Mic92/sops-nix/issues/167
    gnupg.sshKeyPaths = [ ];
  };

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    kbdInteractiveAuthentication = false;
    permitRootLogin = "no";
  };

  networking = {
    hostName = hostname;
    domain = "mado.moe";
    useDHCP = true;
  };

  # You will still need to set up the user accounts to begin with:
  # $ sudo smbpasswd -a yourusername
  services.samba = {
    enable = true;

    # This adds to the [global] section:
    extraConfig = ''
      browseable = yes
      smb encrypt = required
    '';
  };
  services.nfs.server.enable = true;
  networking.firewall.allowedTCPPorts = [
    # smb ports
    445
    139
    # nfs ports
    2049
  ];
  # smb ports
  networking.firewall.allowedUDPPorts = [ 137 138 ];
}
