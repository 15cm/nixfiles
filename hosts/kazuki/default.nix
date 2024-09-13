{ config, pkgs, lib, mylib, hostname, ... }:

with lib;

{
  system.stateVersion = "22.05";
  imports = [
    ./hardware-configuration.nix
    ../common/baseline.nix
    ../common/boot-loader.nix
    ../common/users.nix
    ../common/linux-gui.nix
  ];

  environment.systemPackages = with pkgs; [ easyrsa i2c-tools ];

  # Blocked by vmware to support latest kernels https://github.com/NixOS/nixpkgs/issues/339507
  boot.kernelPackages = mkForce pkgs.linuxPackages_6_6;

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
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "560.28.03";
      sha256_64bit = "sha256-martv18vngYBJw1IFUCAaYr+uc65KtlHAMdLMdtQJ+Y=";
      sha256_aarch64 = "sha256-+u0ZolZcZoej4nqPGmZn5qpyynLvu2QSm9Rd3wLdDmM=";
      openSha256 = "sha256-asGpqOpU0tIO9QqceA8XRn5L27OiBFuI9RZ1NjSVwaM=";
      settingsSha256 = "sha256-b4nhUMCzZc3VANnNb0rmcEH6H7SK2D5eZIplgPV59c8=";
      persistencedSha256 =
        "sha256-MhITuC8tH/IPhCOUm60SrPOldOpitk78mH0rg+egkTE=";
    };
    modesetting.enable = true;
    powerManagement.enable = true;
    forceFullCompositionPipeline = true;
    # Open nvidia has issue with suspend. Ensure to use the proprietary drivers.
    open = false;
  };

  boot.kernelParams =
    [ "acpi_enforce_resources=lax" "transparent_hugepage=never" ];
  hardware = { i2c = { enable = true; }; };
  my.services.openrgb.enable = true;

  my.services.zrepl = {
    enable = true;
    ports = { inherit (config.my.ports.zrepl.kazuki) push; };
    configTemplateFile = ./zrepl/zrepl.yaml.jinja;
    sopsCertFile = ./zrepl/kazuki.m.mado.moe.crt;
    sopsKeyFile = ./zrepl/kazuki.m.mado.moe.key;
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
  hardware.graphics.enable32Bit = true;

  services.sunshine = {
    enable = true;
    capSysAdmin = true;
  };

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
