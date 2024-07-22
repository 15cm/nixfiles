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
    ../common/boot-loader.nix
    ../common/users.nix
    ../common/linux-gui.nix
  ];

  environment.systemPackages = with pkgs; [
    easyrsa
    i2c-tools
    wineWowPackages.stable
    winetricks
    dolphin-emu-beta
    rpcs3
    (retroarch.override { cores = with libretro; [ mgba ]; })
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
      PermitRootLogin = "no";
    };
  };

  my.essentials.zfs = {
    enable = true;
    enableZed = true;
  };

  networking = {
    hostName = hostname;
    domain = "mado.moe";
    networkmanager = { enable = true; };
    firewall.enable = mkForce false;
  };

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    modesetting.enable = true;
    powerManagement.enable = true;
    forceFullCompositionPipeline = true;
    # Open nvidia has issue with suspend. Ensure to use the proprietary drivers.
    open = false;
  };

  boot.kernelParams =
    [ "acpi_enforce_resources=lax" "transparent_hugepage=never" ];
  boot.kernelModules = [
    # Ensure we can access i2c bus for RGB memory
    "i2c-dev"
    "i2c-piix4"
  ];
  services.udev.extraRules = builtins.readFile openrgb-rules;
  hardware = { i2c = { enable = true; }; };
  services = {
    hardware.openrgb = {
      enable = true;
      motherboard = "amd";
    };
  };

  my.services.zrepl = {
    enable = true;
    ports = { inherit (config.my.ports.zrepl.kazuki) push; };
    configTemplateFile = ./zrepl/zrepl.yaml.jinja;
    sopsCertFile = ./zrepl/kazuki.m.mado.moe.crt;
    sopsKeyFile = ./zrepl/kazuki.m.mado.moe.key;
  };

  # Blocked by https://github.com/NixOS/nix/pull/9053
  # virtualisation.vmware.host = {
  #   enable = true;
  #   package = (pkgs.vmware-workstation.overrideAttrs (old: rec {
  #     src = builtins.fetchTree {
  #       url =
  #         "https://softwareupdate.vmware.com/cds/vmw-desktop/ws/${old.version}/${old.build}/linux/core/VMware-Workstation-${old.version}-${old.build}.x86_64.bundle.tar";
  #       sha256 = "sha256-4kA5zi9roCOHWSpHwEsRehzrlAgrm/lugSLpznPIYRw=";
  #     };

  #     unpackPhase = let
  #       vmware-unpack-env = pkgs.buildFHSEnv rec {
  #         name = "vmware-unpack-env";
  #         targetPkgs = pkgs: [ pkgs.zlib ];
  #       };
  #     in ''
  #       ${vmware-unpack-env}/bin/vmware-unpack-env -c "sh ${src}/VMware-Workstation-${old.version}-{old.build}.x86_64.bundle --extract unpacked"
  #       # If you need it, copy the enableMacOSGuests stuff here as well.
  #     '';
  #   }));

  #   extraPackages = with pkgs; [ open-vm-tools ];
  #   extraConfig = ''
  #     # Fit all virtual machine memory to be swapped
  #     prefvmx.minVmMemPct = "100"
  #     # Disable background snapshots
  #     mainMem.partialLazySave = "FALSE"
  #     mainMem.partialLazyRestore = "FALSE"
  #   '';
  # };

  hardware.graphics.enable32Bit = true;
  virtualisation.docker.enableNvidia = true;

  services.ollama = {
    enable = false;
    acceleration = "cuda";
    host = "0.0.0.0";
  };

  my.services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };
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
  my.services.shadowsocks-client = {
    enable = true;
    serverAddress = "direct.15cm.net";
  };

  my.services.smartd.enable = true;
  my.services.metrics = {
    enable = true;
    enableScrapeSmartctl = true;
  };
}
