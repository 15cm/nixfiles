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
    secrets = {
      hashedPassword.neededForUsers = true;
      smbpasswd.mode = "400";
    };
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

  services.samba = {
    enable = true;
    securityType = "user";

    # This adds to the [global] section:
    extraConfig = ''
      browseable = yes
    '';
    openFirewall = true;

    shares.global = { "server min protocol" = "SMB2_02"; };

    # Smb sharing doesn't work well with zfs properties.
    shares = {
      "main_storage" = {
        path = "/mnt/main/storage";
        writeable = "yes";
      };
    };
  };
  # Initialize smb password following https://unix.stackexchange.com/questions/204975/script-samba-password-but-securely
  system.activationScripts = mkIf config.services.samba.enable {
    sambaUserSetup = {
      text = ''
        ${pkgs.samba}/bin/pdbedit \
          -i smbpasswd:/run/secrets/smbpasswd \
          -e tdbsam:/var/lib/samba/private/passdb.tdb
      '';
      deps = [ "setupSecrets" ];
    };
  };

  services.nfs.server.enable = true;
  networking.firewall.allowedTCPPorts = [
    # nfs ports
    2049
  ];
}
