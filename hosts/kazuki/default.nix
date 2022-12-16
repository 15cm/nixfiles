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
    ../common/linux-gui.nix
    ../features/app/autofs
  ];

  environment.systemPackages = with pkgs; [ easyrsa ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = { hashedPassword.neededForUsers = true; };
    age = {
      keyFile = "/keys/age/kazuki.txt";
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
    networkmanager = { enable = true; };
  };

  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
  boot.kernelParams = [ "nvidia-drm.modeset=1" ];
}
