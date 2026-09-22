{
  config,
  pkgs,
  lib,
  mylib,
  hostname,
  ...
}:

with lib;

let
  inherit (mylib) writeShellScriptFile templateFile;
in
{
  system.stateVersion = "22.05";
  imports = [
    ./hardware-configuration.nix
    ../common/baseline.nix
    ../common/boot-loader.nix
    ../common/users.nix
    ../common/trusted.nix
  ];

  environment.systemPackages = with pkgs; [
    easyrsa
    brightnessctl
    xray
  ];

  programs.proxychains = {
    enable = true;
    package = pkgs.proxychains-ng;
    chain.type = "strict";
    proxyDNS = true;
    proxies.xray-http = {
      enable = true;
      type = "http";
      host = "127.0.0.1";
      port = 10808;
    };
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      hashedPassword.neededForUsers = true;
      xrayClientId = {
        owner = "xray";
        group = "xray";
      };
    };
    templates."xray.json" = {
      owner = "xray";
      group = "xray";
      content = builtins.toJSON {
        log.loglevel = "warning";
        inbounds = [
          {
            tag = "socks-in";
            listen = "127.0.0.1";
            port = 10809;
            protocol = "socks";
            settings = {
              auth = "noauth";
              udp = true;
            };
          }
          {
            tag = "http-in";
            listen = "127.0.0.1";
            port = 10808;
            protocol = "http";
          }
        ];
        outbounds = [
          {
            tag = "amane";
            protocol = "vless";
            settings.vnext = [
              {
                address = "direct.15cm.net";
                port = config.my.ports.xray.listen;
                users = [
                  {
                    id = config.sops.placeholder.xrayClientId;
                    encryption = "none";
                    flow = "xtls-rprx-vision";
                  }
                ];
              }
            ];
            streamSettings = {
              network = "tcp";
              security = "reality";
              realitySettings = {
                fingerprint = "chrome";
                serverName = "www.cloudflare.com";
                publicKey = "IM4pgDQbcql0ZIrzUWeU0HKE8GWbqsAV1t3c-PC20ks";
                shortId = "a1b2c3d4";
              };
            };
          }
          {
            tag = "sachi";
            protocol = "vless";
            settings.vnext = [
              {
                address = "mado.moe";
                port = config.my.ports.xray.listen;
                users = [
                  {
                    id = config.sops.placeholder.xrayClientId;
                    encryption = "none";
                    flow = "xtls-rprx-vision";
                  }
                ];
              }
            ];
            streamSettings = {
              network = "tcp";
              security = "reality";
              realitySettings = {
                fingerprint = "chrome";
                serverName = "www.cloudflare.com";
                publicKey = "-6pvY7DzL_M7q-7fNeZZrnxosjIFyNPltVCo4rFu1yo";
                shortId = "e5f60718";
              };
            };
          }
          {
            tag = "direct";
            protocol = "freedom";
          }
        ];
        routing = {
          domainStrategy = "IPIfNonMatch";
          balancers = [
            {
              tag = "servers";
              selector = [ "amane" "sachi" ];
            }
          ];
          rules = [
            {
              type = "field";
              inboundTag = [ "socks-in" "http-in" ];
              domain = [ "geosite:cn" ];
              outboundTag = "direct";
            }
            {
              type = "field";
              inboundTag = [ "socks-in" "http-in" ];
              ip = [ "geoip:cn" ];
              outboundTag = "direct";
            }
            {
              type = "field";
              inboundTag = [ "socks-in" "http-in" ];
              balancerTag = "servers";
            }
          ];
        };
      };
      restartUnits = [ "xray.service" ];
    };
    age = {
      keyFile = "/keys/age/${hostname}.txt";
      sshKeyPaths = [ ];
    };
    # https://github.com/Mic92/sops-nix/issues/167
    gnupg.sshKeyPaths = [ ];
  };

  users.users.xray = {
    group = "xray";
    isSystemUser = true;
  };
  users.groups.xray = { };
  services.xray = {
    enable = true;
    settingsFile = config.sops.templates."xray.json".path;
  };
  systemd.services.xray.serviceConfig = {
    DynamicUser = mkForce false;
    User = "xray";
    Group = "xray";
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

  boot.kernelPackages = mkForce pkgs.linuxPackages_6_18;
  # Work around amdgpu eDP/display hangs by disabling Panel Self Refresh.
  boot.kernelParams = [ "amdgpu.dcdebugmask=0x10" ];
  my.essentials.zfs = {
    enable = true;
    enableZed = true;
    enableZfsUnstable = true;
    arcMaxBytes = 8 * 1024 * 1024 * 1024;
  };
  my.essentials.gui.enable = true;

  networking = {
    hostName = hostname;
    domain = "mado.moe";
    networkmanager = {
      enable = true;
    };
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
    RestartSec = "5";
  };

  # Disable the Radeon outputs in Pipewire so that the laptop speaker is selected by default.
  services.pipewire.wireplumber.extraConfig = {
    "disable-radeon-devices" = {
      "monitor.alsa.rules" = [
        {
          "matches" = [ { "device.name" = "alsa_card.pci-0000_63_00.1"; } ];
          "actions" = {
            "update-props" = {
              "device.disabled" = true;
            };
          };
        }
      ];
    };
  };

  # Laptop backlight brightness control via brightnessctl package
  # Laptop battery
  services.upower.enable = true;
  programs.virt-manager.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;

  my.services.lock = {
    enable = true;
    lockService = "noctalia-lock.service";
  };

  services.logind.settings.Login = mkForce {
    HandleLidSwitch = "suspend";
    HandleLidSwitchDocked = "suspend";
    HandleLidSwitchExternalPower = "ignore";
  };

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
