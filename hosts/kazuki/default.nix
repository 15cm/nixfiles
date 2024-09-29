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

  # TODO: remove after vmware is support on latest kernels
  # https://github.com/NixOS/nixpkgs/issues/339507
  nixpkgs.overlays = [
    (final: prev: {
      linuxPackages_6_10 = prev.linuxPackages_6_10.extend (_lpfinal: _lpprev: {
        vmware = prev.linuxPackages_6_10.vmware.overrideAttrs (_oldAttrs: {
          version = "workstation-17.5.2-k6.9+-unstable-2024-08-22";
          src = final.fetchFromGitHub {
            owner = "nan0desu";
            repo = "vmware-host-modules";
            rev = "b489870663afa6bb60277a42a6390c032c63d0fa";
            hash = "sha256-9t4a4rnaPA4p/SccmOwsL0GsH2gTWlvFkvkRoZX4DJE=";
          };
        });
      });
    })
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
    # https://github.com/NixOS/nixpkgs/blob/1925c603f17fc89f4c8f6bf6f631a802ad85d784/pkgs/os-specific/linux/nvidia-x11/default.nix#L53-L60
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "560.31.02";
      sha256_64bit = "sha256-0cwgejoFsefl2M6jdWZC+CKc58CqOXDjSi4saVPNKY0=";
      sha256_aarch64 = "sha256-m7da+/Uc2+BOYj6mGON75h03hKlIWItHORc5+UvXBQc=";
      openSha256 = "sha256-X5UzbIkILvo0QZlsTl9PisosgPj/XRmuuMH+cDohdZQ=";
      settingsSha256 = "sha256-A3SzGAW4vR2uxT1Cv+Pn+Sbm9lLF5a/DGzlnPhxVvmE=";
      persistencedSha256 =
        "sha256-BDtdpH5f9/PutG3Pv9G4ekqHafPm3xgDYdTcQumyMtg=";
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
