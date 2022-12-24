{ config, pkgs, lib, mylib, hostname, ... }:

with lib;

let
  openrgb-rules = pkgs.fetchurl {
    url =
      "https://gitlab.com/CalcProgrammer1/OpenRGB/-/raw/ca3c2ad54188c604c7626136ceda574e9fde3bc0/60-openrgb.rules";
    hash = "sha256:0s0cdjdc5yndzwl0l2lccbqv08r0js7laln0slncb7h1lj6k5imf";
  };
in {
  system.stateVersion = "22.05";
  imports = [
    ./generated/hardware-configuration.nix
    ./generated/extra-configuration.nix
    ../common/baseline.nix
    ../common/systemd-boot.nix
    ../common/zfs
    ../common/users.nix
    ../common/linux-gui.nix
  ];

  environment.systemPackages = with pkgs; [ easyrsa i2c-tools ];

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
    permitRootLogin = "no";
  };

  networking = {
    hostName = hostname;
    domain = "mado.moe";
    networkmanager = { enable = true; };
  };

  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
  boot.kernelParams = [ "nvidia-drm.modeset=1" "acpi_enforce_resources=lax" ];
  boot.kernelModules = [
    # Ensure we can access i2c bus for RGB memory
    "i2c-dev"
    "i2c-piix4"
  ];
  services.udev.extraRules = builtins.readFile openrgb-rules;

  my.services.zrepl = {
    enable = true;
    configTemplateFile = ./zrepl/zrepl.yaml.jinja;
    sopsCertFile = ./zrepl/kazuki.machine.mado.moe.crt;
    sopsKeyFile = ./zrepl/kazuki.machine.mado.moe.key;
  };
  my.services.shadowsocks-client = {
    enable = true;
    serverAddress = "amane.machine.15cm.net";
  };
}
