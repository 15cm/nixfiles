{ config, pkgs, lib, mylib, hostname, ... }:

with lib;

{
  system.stateVersion = "22.05";
  imports = [
    ../common/baseline.nix
    ../common/zfs.nix
    ../common/users/sinkerine.nix
    ../common/linux-gui.nix
    ./generated/hardware-configuration.nix
    ./generated/extra-configuration.nix
  ];

  environment.systemPackages = with pkgs; [ systemd ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = { hashedPassword.neededForUsers = true; };
    age = {
      keyFile = "/keys/age/asako.txt";
      sshKeyPaths = [ ];
    };
    # https://github.com/Mic92/sops-nix/issues/167
    gnupg.sshKeyPaths = [ ];
  };

  # TODO: disable ssh after configuration is done.
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

  services.kmonad = {
    enable = true;
    keyboards = {
      "laptop" = {
        device = "/dev/input/by-path/platform-i8042-serio-0-event-kbd";
        defcfg = {
          enable = true;
          fallthrough = true;
          allowCommands = false;
        };
        config = builtins.readFile ./kmonad/laptop.kbd;
      };
    };
  };

  # Removes the unused rocm opencl packages in https://github.com/NixOS/nixos-hardware/blob/master/common/gpu/amd/default.nix
  hardware.opengl.extraPackages = with pkgs; mkForce [ amdvlk ];

  # Laptop backlight
  programs.light.enable = true;

  # Laptop battery
  services.upower.enable = true;
}
