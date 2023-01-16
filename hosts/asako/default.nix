{ config, pkgs, lib, mylib, hostname, ... }:

with lib;

let inherit (mylib) writeShellScriptFile templateFile;
in {
  system.stateVersion = "22.05";
  imports = [
    ./hardware-configuration.nix
    ../common/baseline.nix
    ../common/systemd-boot.nix
    ../common/zfs
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

  services.fwupd.enable = true;
  services.udisks2.enable = true;

  services.openssh.enable = false;

  networking = {
    hostName = hostname;
    domain = "mado.moe";
    networkmanager = { enable = true; };
    # https://nixos.wiki/wiki/WireGuard#Setting_up_WireGuard_with_NetworkManager
    firewall.checkReversePath = false;
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

  # Suspend must be triggered when lid is closed. Otherwise the trackpoint will stop working in OS and BIOS. https://www.reddit.com/r/thinkpad/comments/xk999r/trackpoint_issue_with_z13_help_needed_to_verify/
  services.logind = mkForce {
    lidSwitch = "suspend";
    lidSwitchDocked = "suspend";
    lidSwitchExternalPower = "suspend";
  };

  # Trackpoint
  hardware.trackpoint = {
    enable = true;
    sensitivity = 200;
    emulateWheel = true;
  };
  # ATTR{device/speed} is missing in z13 trackpoint so https://github.com/NixOS/nixpkgs/blob/9805c6163a99a8bfb99e09531e85cb1549899aad/nixos/modules/tasks/trackpoint.nix#LL80C4-L80C22 will fail.
  services.udev.extraRules = let cfg = config.hardware.trackpoint;
  in ''
    ACTION=="add|change", SUBSYSTEM=="input", ATTR{name}=="${cfg.device}",  ATTR{device/sensitivity}="${
      toString cfg.sensitivity
    }"
  '';

  # `psmouse` for the trackpoint issue. See the lidSwitch configs for details.
  # `ath11k_pci` for https://blog.15cm.net/2022/08/21/my_arch_linux_setup_on_thinkpad_z13_gen_1/#power-management---suspendresume-good-with-caveats
  system.activationScripts.systemdSuspendModules = ''
    mkdir -p /usr/lib/systemd/system-sleep
    ln -sf ${
      writeShellScriptFile "systemd-suspend-modules"
      ./systemd-suspend-modules.sh
    } /usr/lib/systemd/system-sleep/systemd-suspend-modules.sh
  '';

  my.services.zrepl = {
    enable = true;
    ports = { inherit (config.my.ports.zrepl.asako) push; };
    configTemplateFile = ./zrepl/zrepl.yaml.jinja;
    sopsCertFile = ./zrepl/asako.m.mado.moe.crt;
    sopsKeyFile = ./zrepl/asako.m.mado.moe.key;
  };

  my.services.tailscale.enable = true;
  my.services.gateway = {
    enable = true;
    enableDocker = true;
    internalDomain = "${hostname}.m.mado.moe";
  };
  my.services.metrics.enable = true;
  # Runs separate monitoring and alerts on machines that are not always online.
  my.services.monitoring = {
    enable = true;
    domain = "monitoring.${hostname}.m.mado.moe";
    datasourceHosts = [ hostname ];
    dataDir = "/var/lib/grafana";
  };
}
