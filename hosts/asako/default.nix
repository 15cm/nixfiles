{ config, pkgs, lib, mylib, hostname, ... }:

with lib;

let inherit (mylib) writeShellScriptFile templateFile;
in {
  system.stateVersion = "22.05";
  imports = [
    ./hardware-configuration.nix
    ../common/baseline.nix
    ../common/boot-loader.nix
    ../common/users.nix
    ../common/linux-gui.nix
  ];

  environment.systemPackages = with pkgs; [ easyrsa ];

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
    extraConfig = ''
      AllowUsers *@100.64.*.*
      AllowUsers *@192.168.88.*
    '';
  };

  my.essentials.zfs = {
    enable = true;
    enableZed = true;
  };

  networking = {
    hostName = hostname;
    domain = "mado.moe";
    networkmanager = { enable = true; };
  };

  services.fwupd.enable = true;
  services.udisks2.enable = true;
  services.kmonad = {
    enable = true;
    keyboards = {
      laptop = {
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
  systemd.services.kmonad-laptop.serviceConfig = {
    Restart = "always";
    RestartSec = "3";
  };

  # Removes the unused rocm opencl packages in https://github.com/NixOS/nixos-hardware/blob/master/common/gpu/amd/default.nix
  hardware.graphics.extraPackages = with pkgs; mkForce [ amdvlk ];

  # Laptop backlight
  programs.light.enable = true;

  # Laptop battery
  services.upower.enable = true;

  services.logind = mkForce {
    lidSwitch = "suspend";
    lidSwitchDocked = "suspend";
    lidSwitchExternalPower = "ignore";
  };

  # Trackpoint
  hardware.trackpoint = {
    enable = true;
    sensitivity = 128;
    emulateWheel = true;
  };
  # ATTR{device/speed} is missing in z13 trackpoint so https://github.com/NixOS/nixpkgs/blob/9805c6163a99a8bfb99e09531e85cb1549899aad/nixos/modules/tasks/trackpoint.nix#LL80C4-L80C22 will fail.
  services.udev.extraRules = let cfg = config.hardware.trackpoint;
  in ''
    ACTION=="add|change", SUBSYSTEM=="input", ATTR{name}=="${cfg.device}",  ATTR{device/sensitivity}="${
      toString cfg.sensitivity
    }"
  '';

  my.services.zrepl = {
    enable = true;
    ports = { inherit (config.my.ports.zrepl.asako) push; };
    configTemplateFile = ./zrepl/zrepl.yaml.jinja;
    sopsCertFile = ./zrepl/asako.m.mado.moe.crt;
    sopsKeyFile = ./zrepl/asako.m.mado.moe.key;
  };

  my.services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };
  my.services.gateway = {
    enable = true;
    enableDocker = true;
    internalDomain = "${hostname}.m.mado.moe";
  };
  my.services.smartd.enable = true;
  my.services.metrics = {
    enable = true;
    enableScrapeSmartctl = true;
  };
}
