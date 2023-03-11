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
    ./hardware-configuration.nix
    ../common/baseline.nix
    ../common/systemd-boot.nix
    ../common/zfs
    ../common/users.nix
    ../common/linux-gui.nix
  ];

  environment.systemPackages = with pkgs; [
    easyrsa
    i2c-tools
    wineWowPackages.stable
    winetricks
    dolphin-emu-beta
    ryujinx
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
      passwordAuthentication = false;
      kbdInteractiveAuthentication = false;
      permitRootLogin = "no";
    };
  };

  networking = {
    hostName = hostname;
    domain = "mado.moe";
    networkmanager = { enable = true; };
    firewall.enable = mkForce false;
  };

  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "acpi_enforce_resources=lax"
    "transparent_hugepage=never"
  ];
  boot.kernelModules = [
    # Ensure we can access i2c bus for RGB memory
    "i2c-dev"
    "i2c-piix4"
  ];
  services.udev.extraRules = builtins.readFile openrgb-rules;

  my.services.zrepl = {
    enable = true;
    ports = { inherit (config.my.ports.zrepl.kazuki) push; };
    configTemplateFile = ./zrepl/zrepl.yaml.jinja;
    sopsCertFile = ./zrepl/kazuki.m.mado.moe.crt;
    sopsKeyFile = ./zrepl/kazuki.m.mado.moe.key;
  };
  my.services.shadowsocks-client = {
    enable = true;
    serverAddress = "amane.m.mado.moe";
  };

  virtualisation.vmware.host = {
    enable = true;
    extraPackages = with pkgs; [ open-vm-tools ];
    extraConfig = ''
      # Fit all virtual machine memory to be swapped
      prefvmx.minVmMemPct = "100"
      # Disable background snapshots
      mainMem.partialLazySave = "FALSE"
      mainMem.partialLazyRestore = "FALSE"
    '';
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall =
      true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall =
      true; # Open ports in the firewall for Source Dedicated Server
  };

  my.services.tailscale.enable = true;
  my.services.gateway = {
    enable = true;
    enableDocker = true;
    internalDomain = "${hostname}.m.mado.moe";
    lanOnlyIpRanges = [
      config.my.ip.ranges.local
      config.my.ip.ranges.lan
      config.my.ip.ranges.wireguard
      config.my.ip.ranges.tailscale
    ];
  };

  my.services.smartd.enable = true;
  my.services.metrics = {
    enable = true;
    enableScrapeSmartctl = true;
  };
  # Runs separate monitoring and alerts on machines that are not always online.
  my.services.monitoring = {
    enable = true;
    domain = "monitoring.${hostname}.m.mado.moe";
    datasourceHosts = [ hostname ];
    dataDir = "/var/lib/grafana";
  };
}
