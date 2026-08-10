{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.my.services.docker;
  initCfg = cfg.serviceInit;
  dockerServiceInit = pkgs.writeShellApplication {
    name = "docker-service-init";
    runtimeInputs = [
      config.boot.zfs.package
      pkgs.coreutils
    ];
    text = ''
      if [[ $# -ne 1 || ! $1 =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
        echo "usage: docker-service-init <service>" >&2
        exit 2
      fi

      service=$1
      dataset_root=${escapeShellArg initCfg.datasetRoot}
      mount_root=${escapeShellArg "${initCfg.rootDir}/available"}
      owner=${escapeShellArg "${initCfg.user}:${initCfg.group}"}
      dataset="$dataset_root/$service"
      mountpoint="$mount_root/$service"

      if zfs list -H -o name "$dataset" >/dev/null 2>&1; then
        echo "refusing existing dataset: $dataset" >&2
        exit 1
      fi

      created=false
      cleanup() {
        status=$?
        if [[ $status -ne 0 && $created == true ]]; then
          zfs destroy "$dataset" || true
        fi
        exit "$status"
      }
      trap cleanup EXIT

      zfs create "$dataset"
      created=true
      chown "$owner" "$mountpoint"
      created=false
      trap - EXIT

      echo "created $dataset at $mountpoint"
    '';
  };
in
{
  options.my.services.docker = {
    enable = mkEnableOption "docker";

    serviceInit = {
      enable = mkEnableOption "per-service Docker ZFS dataset initialization";
      rootDir = mkOption {
        type = types.str;
        example = "/pool/main/docker";
        description = "Docker Compose service root containing available and enabled directories.";
      };
      datasetRoot = mkOption {
        type = types.str;
        example = "main/docker/available";
        description = "ZFS dataset beneath which per-service datasets are created.";
      };
      user = mkOption {
        type = types.str;
        default = "sinkerine";
        description = "User allowed to initialize services and own new service mountpoints.";
      };
      group = mkOption {
        type = types.str;
        default = initCfg.user;
        description = "Group owning new service mountpoints.";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      virtualisation.docker = {
        enable = true;
        enableOnBoot = true;
        storageDriver = "overlay2";
        daemon.settings = {
          default-address-pools = [
            {
              base = config.my.ip.ranges.docker;
              size = 24;
            }
          ];
          ip-forward-no-drop = true;
          log-driver = mkForce "local";
        };
        autoPrune.enable = true;
      };

      users.groups.dockremap = {
        gid = config.my.ids.uids.dockremap;
      };
      users.users.dockremap = {
        isSystemUser = true;
        uid = config.my.ids.uids.dockremap;
        group = "dockremap";
        extraGroups = [ "docker" ];
      };

      systemd.services.createDockerNetowrk = {
        enable = true;
        description = "Create Docker network";
        wantedBy = [ "docker.service" ];
        after = [ "docker.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "create-docker-network.service" ''
            if ! ${pkgs.docker}/bin/docker network ls | grep -q g_proxy; then ${pkgs.docker}/bin/docker network create g_proxy; fi
          '';
        };
      };
    }

    (mkIf initCfg.enable {
      assertions = [
        {
          assertion = hasPrefix "/" initCfg.rootDir;
          message = "my.services.docker.serviceInit.rootDir must be absolute";
        }
        {
          assertion = initCfg.datasetRoot != "" && !(hasPrefix "/" initCfg.datasetRoot);
          message = "my.services.docker.serviceInit.datasetRoot must be a non-empty ZFS dataset name";
        }
      ];

      environment.systemPackages = [ dockerServiceInit ];

      security.sudo.extraRules = [
        {
          users = [ initCfg.user ];
          commands = [
            {
              command = "${dockerServiceInit}/bin/docker-service-init";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];
    })
  ]);
}
