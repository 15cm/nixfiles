{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.my.services.guiTestSandbox;
  defaultNvidiaVersion =
    if config.hardware.nvidia.package == null then "unset" else config.hardware.nvidia.package.version;
  nvidiaPackage =
    if config.hardware.nvidia.package == null then pkgs.emptyDirectory else config.hardware.nvidia.package;
  nvidiaBinPackage =
    if config.hardware.nvidia.package == null then pkgs.emptyDirectory else config.hardware.nvidia.package.bin;
  cuaDriverArchive = pkgs.fetchurl {
    name = "cua-driver-rs-v${cfg.cuaDriverVersion}-linux-x86_64.tar.gz";
    url = cfg.cuaDriverArchiveUrl;
    sha256 = cfg.cuaDriverArchiveSha256;
  };
  provisioningSchema = builtins.substring 0 16 (builtins.hashString "sha256" (
    builtins.readFile ./guest-provision.sh
    + cfg.cuaDriverVersion
    + cfg.nvidiaDriverVersion
    + cfg.nvidiaGpuName
    + cfg.templateImage
    + cfg.templateImageSha512
  ));
  guestProvision = pkgs.writeText "gui-sandbox-guest-provision.sh" (builtins.readFile ./guest-provision.sh);
  storageBootstrap = pkgs.writeShellApplication {
    name = "gui-sandbox-storage";
    runtimeInputs = with pkgs; [ coreutils gawk gnugrep gnused proxmox-ve zfs ];
    text = ''
      set -euo pipefail

      dataset=${escapeShellArg cfg.storageDataset}
      storage_id=${escapeShellArg cfg.storageId}

      if ! zfs list -H -o name "$dataset" >/dev/null 2>&1; then
        zfs create -p -o mountpoint=none "$dataset"
      fi
      [[ $(zfs get -H -o value type "$dataset") == filesystem ]] || {
        echo "gui-sandbox: $dataset is not a ZFS filesystem" >&2
        exit 1
      }

      command -v pvesm >/dev/null 2>&1 || {
        echo "gui-sandbox: pvesm is unavailable" >&2
        exit 1
      }
      if pvesm config "$storage_id" >/dev/null 2>&1; then
        storage_config=$(pvesm config "$storage_id")
        grep -Fxq "zfspool: $storage_id" <<<"$storage_config" || {
          echo "gui-sandbox: existing Proxmox storage $storage_id is not zfspool" >&2
          exit 1
        }
        awk -v expected="$dataset" '$1 == "pool" && $2 == expected { found = 1 } END { exit !found }' <<<"$storage_config" || {
          echo "gui-sandbox: existing Proxmox storage $storage_id points at a different pool" >&2
          exit 1
        }
      else
        pvesm add zfspool "$storage_id" --pool "$dataset" --content rootdir --sparse 1
      fi
    '';
  };
  guiSandbox = pkgs.writeShellApplication {
    name = "gui-sandbox";
    excludeShellChecks = [ "SC2016" ];
    runtimeInputs = with pkgs; [
      bash
      coreutils
      curl
      findutils
      gawk
      gnugrep
      gnused
      git
      gnutar
      jq
      openssh
      proxmox-ve
      sudo
      util-linux
      zfs
    ];
    text = ''
      # shellcheck disable=SC2016
      GUI_SANDBOX_ALLOWED_WORKTREE_ROOT=${escapeShellArg cfg.allowedWorktreeRoot}
      GUI_SANDBOX_STATE_DIR=${escapeShellArg cfg.stateDirectory}
      GUI_SANDBOX_STORAGE_ID=${escapeShellArg cfg.storageId}
      GUI_SANDBOX_STORAGE_DATASET=${escapeShellArg cfg.storageDataset}
      GUI_SANDBOX_TEMPLATE_CACHE=${escapeShellArg cfg.templateCache}
      GUI_SANDBOX_TEMPLATE_VMID=${toString cfg.templateVmid}
      GUI_SANDBOX_FIRST_VMID=${toString cfg.firstVmid}
      GUI_SANDBOX_LAST_VMID=${toString cfg.lastVmid}
      GUI_SANDBOX_BRIDGE=${escapeShellArg cfg.bridge}
      GUI_SANDBOX_CORES=${toString cfg.cores}
      GUI_SANDBOX_MEMORY_MIB=${toString cfg.memoryMiB}
      GUI_SANDBOX_ROOTFS_GIB=${toString cfg.rootfsGiB}
      GUI_SANDBOX_LEASE_SECONDS=${toString ((builtins.fromJSON (toString cfg.leaseHours)) * 3600)}
      GUI_SANDBOX_GUEST_UID=${toString cfg.guestUid}
      GUI_SANDBOX_GUEST_GID=${toString cfg.guestGid}
      GUI_SANDBOX_SUBID_START=${toString cfg.subordinateIdStart}
      GUI_SANDBOX_SUBID_COUNT=${toString cfg.subordinateIdCount}
      GUI_SANDBOX_RENDER_NODE=${escapeShellArg cfg.nvidiaRenderNode}
      GUI_SANDBOX_GPU_NAME=${escapeShellArg cfg.nvidiaGpuName}
      GUI_SANDBOX_NVIDIA_PACKAGE=${escapeShellArg (toString nvidiaPackage)}
      GUI_SANDBOX_NVIDIA_BIN=${escapeShellArg (toString nvidiaBinPackage)}
      GUI_SANDBOX_NVIDIA_VERSION=${escapeShellArg cfg.nvidiaDriverVersion}
      GUI_SANDBOX_TEMPLATE_IMAGE=${escapeShellArg cfg.templateImage}
      GUI_SANDBOX_TEMPLATE_URL=${escapeShellArg cfg.templateImageUrl}
      GUI_SANDBOX_TEMPLATE_SHA512=${escapeShellArg cfg.templateImageSha512}
      GUI_SANDBOX_CUA_ARCHIVE=${escapeShellArg (toString cuaDriverArchive)}
      GUI_SANDBOX_CUA_VERSION=${escapeShellArg cfg.cuaDriverVersion}
      GUI_SANDBOX_CUA_SHA256=${escapeShellArg cfg.cuaDriverArchiveSha256}
      GUI_SANDBOX_PROVISION_SCHEMA=${escapeShellArg provisioningSchema}
      GUI_SANDBOX_GUEST_PROVISION=${escapeShellArg (toString guestProvision)}
      ${builtins.readFile ./gui-sandbox.sh}
    '';
  };
in
{
  options.my.services.guiTestSandbox = {
    enable = mkEnableOption "GPU-backed unprivileged LXC GUI test sandbox";

    allowedWorktreeRoot = mkOption {
      type = types.str;
      default = "/home/sinkerine/orca/workspaces";
      description = "Canonical root below which task worktrees may be mounted read-write.";
    };

    stateDirectory = mkOption {
      type = types.str;
      default = "/var/lib/gui-test-sandbox";
      description = "Root-owned state, SSH material, and artifact directory.";
    };

    storageDataset = mkOption {
      type = types.str;
      default = "rpool/proxmox/agent-sandbox";
      description = "ZFS filesystem handed to Proxmox zfspool storage.";
    };

    storageId = mkOption {
      type = types.str;
      default = "agent-sandbox";
      description = "Proxmox storage ID for task root filesystems.";
    };

    templateCache = mkOption {
      type = types.str;
      default = "/var/lib/vz/template/cache";
      description = "Host directory containing the verified Ubuntu template archive.";
    };

    templateVmid = mkOption {
      type = types.ints.between 1 999999999;
      default = 9000;
      description = "Reserved Proxmox VMID for the immutable GUI sandbox template.";
    };

    firstVmid = mkOption {
      type = types.ints.between 1 999999999;
      default = 9100;
      description = "First managed task VMID, inclusive.";
    };

    lastVmid = mkOption {
      type = types.ints.between 1 999999999;
      default = 9199;
      description = "Last managed task VMID, inclusive.";
    };

    bridge = mkOption {
      type = types.str;
      default = "vmbr0";
      description = "DHCP bridge attached to each task LXC.";
    };

    cores = mkOption {
      type = types.ints.positive;
      default = 8;
      description = "Default task vCPU count.";
    };

    memoryMiB = mkOption {
      type = types.ints.positive;
      default = 16384;
      description = "Default task memory in MiB.";
    };

    rootfsGiB = mkOption {
      type = types.ints.positive;
      default = 64;
      description = "Default sparse task root filesystem size in GiB.";
    };

    leaseHours = mkOption {
      type = types.ints.positive;
      default = 12;
      description = "Task lease duration before the targeted reaper may clean it up.";
    };

    guestUid = mkOption {
      type = types.ints.between 0 65535;
      default = 1000;
      description = "Guest agent UID, mapped to the host task-user UID.";
    };

    guestGid = mkOption {
      type = types.ints.between 0 65535;
      default = 1000;
      description = "Guest agent GID, mapped to the host task-user GID.";
    };

    subordinateIdStart = mkOption {
      type = types.ints.positive;
      default = 100000;
      description = "Root subordinate UID/GID range start used by the unprivileged mappings.";
    };

    subordinateIdCount = mkOption {
      type = types.ints.positive;
      default = 65536;
      description = "Root subordinate UID/GID range size.";
    };

    nvidiaRenderNode = mkOption {
      type = types.str;
      default = "/dev/dri/renderD128";
      description = "NVIDIA DRM render node. Physical DRM card nodes are rejected.";
    };

    nvidiaGpuName = mkOption {
      type = types.str;
      default = "NVIDIA GeForce RTX 5070 Ti";
      description = "Renderer identity required by guest health checks.";
    };

    nvidiaDriverVersion = mkOption {
      type = types.str;
      default = defaultNvidiaVersion;
      description = "Host NVIDIA version that guest renderer checks must report.";
    };

    templateImage = mkOption {
      type = types.str;
      default = "ubuntu-24.04-standard_24.04-2_amd64.tar.zst";
      description = "Pinned Proxmox Ubuntu 24.04 LXC template filename.";
    };

    templateImageUrl = mkOption {
      type = types.str;
      default = "http://download.proxmox.com/images/system/ubuntu-24.04-standard_24.04-2_amd64.tar.zst";
      description = "Pinned template download URL; content is verified by SHA-512 before use.";
    };

    templateImageSha512 = mkOption {
      type = types.strMatching "[0-9a-f]{128}";
      default = "45c2978e6b97fe292ada95fe06834276015e5739a594db4de2fdfd830fa0c37942e8ae118fc1e32ffd9154b3f9378b592738b668ea3957db41f2907b86f219de";
      description = "Published SHA-512 for the pinned Proxmox template.";
    };

    cuaDriverVersion = mkOption {
      type = types.strMatching "[0-9]+\\.[0-9]+\\.[0-9]+";
      default = "0.21.0";
      description = "Pinned CUA Driver release installed in each template.";
    };

    cuaDriverArchiveUrl = mkOption {
      type = types.str;
      default = "https://github.com/trycua/cua/releases/download/cua-driver-rs-v0.21.0/cua-driver-rs-0.21.0-linux-x86_64.tar.gz";
      description = "Pinned CUA Driver Linux archive URL.";
    };

    cuaDriverArchiveSha256 = mkOption {
      type = types.strMatching "[0-9a-f]{64}";
      default = "b269df39141bf873a583913cf59c18b867f8ac880ba43d781ca276b2632a6f55";
      description = "SHA-256 for the pinned CUA Driver archive.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.firstVmid <= cfg.lastVmid;
        message = "my.services.guiTestSandbox.firstVmid must be <= lastVmid";
      }
      {
        assertion = cfg.guestUid == 1000 && cfg.guestGid == 1000;
        message = "GUI test sandbox currently requires guest UID/GID 1000 passthrough";
      }
      {
        assertion = config.hardware.nvidia.package != null;
        message = "GPU GUI test sandbox requires hardware.nvidia.package";
      }
      {
        assertion = !(hasInfix "/card" cfg.nvidiaRenderNode);
        message = "GUI test sandbox accepts only an NVIDIA render node, never /dev/dri/card*";
      }
    ];

    environment.systemPackages = [ guiSandbox ];

    users.users.root.subUidRanges = [
      {
        startUid = cfg.subordinateIdStart;
        count = cfg.subordinateIdCount;
      }
    ];
    users.users.root.subGidRanges = [
      {
        startGid = cfg.subordinateIdStart;
        count = cfg.subordinateIdCount;
      }
    ];

    systemd.tmpfiles.rules = [
      "d ${cfg.stateDirectory} 0750 root sinkerine -"
      "d ${cfg.stateDirectory}/tasks 0700 root root -"
      "d ${cfg.stateDirectory}/ssh 0750 root sinkerine -"
      "d ${cfg.stateDirectory}/artifacts 0750 root sinkerine -"
    ];

    security.sudo.extraRules = [
      {
        users = [ "sinkerine" ];
        commands = [
          {
            command = "/run/current-system/sw/bin/gui-sandbox";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];

    systemd.services.gui-test-sandbox-storage = {
      description = "Bootstrap GUI test sandbox ZFS and Proxmox storage";
      wantedBy = [ "multi-user.target" ];
      wants = [ "pve-cluster.service" "zfs.target" ];
      after = [ "pve-cluster.service" "zfs.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${storageBootstrap}/bin/gui-sandbox-storage";
        RemainAfterExit = true;
      };
    };

    systemd.services.gui-test-sandbox-reaper = {
      description = "Reap expired managed GUI test sandboxes";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${guiSandbox}/bin/gui-sandbox reap";
      };
    };

    systemd.timers.gui-test-sandbox-reaper = {
      description = "Reap expired managed GUI test sandboxes every 15 minutes";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "15m";
        OnUnitActiveSec = "15m";
        Persistent = true;
      };
    };
  };
}
