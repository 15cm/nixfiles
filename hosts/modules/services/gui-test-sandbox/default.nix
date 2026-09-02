{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.my.services.guiTestSandbox;
  pvePerl = lib.head (
    lib.splitString " " (
      lib.removePrefix "#!"
        (lib.head (lib.splitString "\n" (builtins.readFile "${pkgs.pve-ha-manager}/bin/.pct-wrapped")))
    )
  );
  pvePerlEnv = builtins.dirOf (builtins.dirOf pvePerl);
  pctCompat = pkgs.writeShellApplication {
    name = "gui-sandbox-pct";
    runtimeInputs = with pkgs; [
      binutils
      coreutils
      gnutar
      iproute2
      lxc
      openssh
      pve-ha-manager
      pve-storage
      systemd
      util-linux
      zfs
      zstd
    ];
    text = ''
      export PATH=${lib.makeBinPath [
        pkgs.binutils
        pkgs.coreutils
        pkgs.gnutar
        pkgs.iproute2
        pkgs.lxc
        pkgs.openssh
        pkgs.pve-ha-manager
        pkgs.pve-storage
        pkgs.systemd
        pkgs.util-linux
        pkgs.zfs
        pkgs.zstd
      ]}
      exec ${pvePerl} -T \
        -I${pvePerlEnv}/lib/perl5/site_perl \
        -I${pvePerlEnv}/lib/perl5/site_perl/5.40.0 \
        -I${pkgs.pve-ha-manager}/lib/perl5/site_perl \
        -I${pkgs.pve-ha-manager}/lib/perl5/site_perl/5.40.0 \
        -I${pkgs.pve-rados2}/lib/perl5/site_perl \
        -I${pkgs.pve-rados2}/lib/perl5/site_perl/5.40.0 \
        -e 'my ($path) = ($ENV{PATH} =~ /^(.*)$/); $ENV{PATH} = $path; require PVE::Tools; my $read = \&PVE::Tools::file_get_contents; no warnings "redefine"; *PVE::Tools::file_get_contents = sub { my ($path, @rest) = @_; $path = "${pkgs.lxc}/share/lxc/config/common.seccomp" if $path eq "${pkgs.pve-container}/share/lxc/config/common.seccomp"; return $read->($path, @rest); }; my $script = shift @ARGV; ($script) = ($script =~ /^(.*)$/); do $script; die $@ if $@;' \
        ${pkgs.pve-ha-manager}/bin/.pct-wrapped "$@"
    '';
  };
  defaultNvidiaVersion =
    if config.hardware.nvidia.package == null then "unset" else config.hardware.nvidia.package.version;
  nvidiaPackage =
    if config.hardware.nvidia.package == null then pkgs.emptyDirectory else config.hardware.nvidia.package;
  nvidiaBinPackage =
    if config.hardware.nvidia.package == null then pkgs.emptyDirectory else config.hardware.nvidia.package.bin;
  nvidiaEglExternalPlatformsSource = lib.findFirst
    (package: lib.hasInfix "nvidia-egl-external-platforms" (lib.getName package))
    pkgs.emptyDirectory
    config.hardware.graphics.extraPackages;
  nvidiaEglExternalPlatforms =
    if nvidiaEglExternalPlatformsSource == pkgs.emptyDirectory then
      pkgs.emptyDirectory
    else
      pkgs.runCommand "gui-sandbox-nvidia-egl-external-platforms" {} ''
        install -d "$out/lib"
        cp -L ${nvidiaEglExternalPlatformsSource}/lib/libnvidia-egl-*.so* "$out/lib/"
      '';
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
    + toString nvidiaEglExternalPlatforms
  ));
  guestProvision = pkgs.writeText "gui-sandbox-guest-provision.sh" (builtins.readFile ./guest-provision.sh);
  storageBootstrap = pkgs.writeShellApplication {
    name = "gui-sandbox-storage";
    runtimeInputs = with pkgs; [ coreutils gawk gnugrep gnused proxmox-ve zfs ];
    text = ''
      set -euo pipefail

      dataset=${escapeShellArg cfg.storageDataset}
      storage_mountpoint=${escapeShellArg cfg.storageMountpoint}
      storage_id=${escapeShellArg cfg.storageId}
      storage_config=/etc/pve/storage.cfg

      if ! zfs list -H -o name "$dataset" >/dev/null 2>&1; then
        zfs create -p -o mountpoint="$storage_mountpoint" "$dataset"
      fi
      [[ $(zfs get -H -o value type "$dataset") == filesystem ]] || {
        echo "gui-sandbox: $dataset is not a ZFS filesystem" >&2
        exit 1
      }
      current_mountpoint=$(zfs get -H -o value mountpoint "$dataset")
      case "$current_mountpoint" in
        "$storage_mountpoint") ;;
        none) zfs set "mountpoint=$storage_mountpoint" "$dataset" ;;
        *)
          echo "gui-sandbox: existing ZFS dataset $dataset has mountpoint $current_mountpoint" >&2
          exit 1
          ;;
      esac
      [[ $(zfs get -H -o value mounted "$dataset") == yes ]] || zfs mount "$dataset"

      command -v pvesm >/dev/null 2>&1 || {
        echo "gui-sandbox: pvesm is unavailable" >&2
        exit 1
      }
      if [[ -e $storage_config && ! -r $storage_config ]]; then
        echo "gui-sandbox: Proxmox storage config is not readable: $storage_config" >&2
        exit 1
      fi
      storage_type=$(awk -v expected="$storage_id" '
        /^[^[:space:]]/ && $2 == expected {
          type = $1
          sub(/:$/, "", type)
          print type
          exit
        }
      ' "$storage_config" 2>/dev/null || true)
      if [[ -n $storage_type ]]; then
        [[ $storage_type == zfspool ]] || {
          echo "gui-sandbox: existing Proxmox storage $storage_id is not zfspool" >&2
          exit 1
        }
        storage_block=$(awk -v expected="$storage_id" '
          /^[^[:space:]]/ {
            in_target = ($2 == expected)
            next
          }
          in_target { print }
        ' "$storage_config")
        awk -v expected="$dataset" '$1 == "pool" && $2 == expected { found = 1 } END { exit !found }' <<<"$storage_block" || {
          echo "gui-sandbox: existing Proxmox storage $storage_id points at a different pool" >&2
          exit 1
        }
        configured_mountpoint=$(awk '$1 == "mountpoint" { print $2; exit }' <<<"$storage_block")
        if [[ $configured_mountpoint != "$storage_mountpoint" ]]; then
          pvesm set "$storage_id" --mountpoint "$storage_mountpoint"
        fi
      else
        pvesm add zfspool "$storage_id" --pool "$dataset" --content rootdir --sparse 1 --mountpoint "$storage_mountpoint"
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
      lxc
      openssh
      proxmox-ve
      systemd
      util-linux
      zfs
    ];
    text = ''
      # shellcheck disable=SC2016
      GUI_SANDBOX_STATE_DIR=${escapeShellArg cfg.stateDirectory}
      GUI_SANDBOX_STORAGE_ID=${escapeShellArg cfg.storageId}
      GUI_SANDBOX_STORAGE_DATASET=${escapeShellArg cfg.storageDataset}
      GUI_SANDBOX_STORAGE_MOUNTPOINT=${escapeShellArg cfg.storageMountpoint}
      GUI_SANDBOX_ROOTFS_MOUNT=${escapeShellArg cfg.rootfsMount}
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
      GUI_SANDBOX_NVIDIA_EGL=${escapeShellArg (toString nvidiaEglExternalPlatforms)}
      GUI_SANDBOX_NVIDIA_VERSION=${escapeShellArg cfg.nvidiaDriverVersion}
      GUI_SANDBOX_TEMPLATE_IMAGE=${escapeShellArg cfg.templateImage}
      GUI_SANDBOX_TEMPLATE_URL=${escapeShellArg cfg.templateImageUrl}
      GUI_SANDBOX_TEMPLATE_SHA512=${escapeShellArg cfg.templateImageSha512}
      GUI_SANDBOX_CUA_ARCHIVE=${escapeShellArg (toString cuaDriverArchive)}
      GUI_SANDBOX_CUA_VERSION=${escapeShellArg cfg.cuaDriverVersion}
      GUI_SANDBOX_CUA_SHA256=${escapeShellArg cfg.cuaDriverArchiveSha256}
      GUI_SANDBOX_PROVISION_SCHEMA=${escapeShellArg provisioningSchema}
      GUI_SANDBOX_GUEST_PROVISION=${escapeShellArg (toString guestProvision)}
      GUI_SANDBOX_PCT=${escapeShellArg (lib.getExe pctCompat)}
      GUI_SANDBOX_RUN0=${escapeShellArg "${pkgs.systemd}/bin/run0"}
      ${builtins.readFile ./gui-sandbox.sh}
    '';
  };
in
{
  options.my.services.guiTestSandbox = {
    enable = mkEnableOption "GPU-backed unprivileged LXC GUI test sandbox";

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

    storageMountpoint = mkOption {
      type = types.str;
      default = "/var/lib/gui-test-sandbox/storage";
      description = "Private host mountpoint inherited by Proxmox ZFS subvolumes.";
    };

    rootfsMount = mkOption {
      type = types.str;
      default = "/run/gui-test-sandbox/rootfs";
      description = "Writable parent for LXC's temporary root filesystem mounts.";
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
        assertion = nvidiaEglExternalPlatformsSource != pkgs.emptyDirectory;
        message = "GPU GUI test sandbox requires nvidia-egl-external-platforms in hardware.graphics.extraPackages";
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
      "d ${cfg.rootfsMount} 0755 root root -"
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
