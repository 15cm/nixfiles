#!/bin/bash

set -euox pipefail

################################################################################

COLOR_RESET="\033[0m"
RED_BG="\033[41m"
BLUE_BG="\033[44m"

function err {
  echo -e "${RED_BG}$1${COLOR_RESET}"
}

function info {
  echo -e "${BLUE_BG}$1${COLOR_RESET}"
}

################################################################################

export _HOSTNAME=$1
export DISK=$2

if ! [[ -v _HOSTNAME ]]; then
  err "Missing argument <_HOSTNAME> as \$1."
  exit 1
fi
if ! [[ -v DISK ]]; then
  err "Missing argument <DISK> as \$2. Expected device path, e.g. /dev/disk/by-id/..."
  exit 1
fi
if [[ "$EUID" > 0 ]]; then
  err "Must run as root"
  exit 1
fi

info "Unmounting /mnt"
umount -Rl /mnt

# PARTITON DISK:
# p1 1GB ESP+EFI
# p2 REST EXT4
info "Partitioning $DISK"
sgdisk --zap-all $DISK
sgdisk -n1:1M:+1G -t1:EF00 -c ESP $DISK
sgdisk -n2:0:0    -t2:8300 -c ROOT $DISK
sleep 1
partprobe $DISK

export ESP_PART=${DISK}-part1
export EXT4_PART=${DISK}-part2

info "Mounting root"
mkfs.ext4 $EXT4_PART
mkdir -p /mnt
mount --mkdir $EXT4_PART /mnt

info "Formatting and mounting the esp"
mkfs.vfat -n ESP $ESP_PART
mount --mkdir -t vfat $ESP_PART /mnt/boot

info "Changing directory permissions"
USER_ID=1000
chown -R 1000:1000 /nixfiles /keys
chmod 700 /keys /keys/age
chmod 500 /keys/age/*

info "Generating nix default configurations"
nixos-generate-config --root /mnt

info "Copying hardware-configuration.nix"
export NIXFILES_HOST_DIR=/nixfiles/hosts/${_HOSTNAME}
mkdir -p ${NIXFILES_HOST_DIR}/generated
cp -f /mnt/etc/nixos/hardware-configuration.nix ${NIXFILES_HOST_DIR}/generated/hardware-configuration.nix

info "Writing extra-configuration.nix"
cat << EOF > ${NIXFILES_HOST_DIR}/generated/extra-configuration.nix
{ ... }:

{
  # hostid is required by zfs.
  networking.hostId = "$(head -c 8 /etc/machine-id)";
}
EOF

info "Cleaning up useless files in /mnt"
rm -rf /mnt/etc/nixos

info "Copying necessary files to /mnt"
rsync -ahP /keys/ /mnt/keys
rsync -ahP /nixfiles/ /mnt/nixfiles

info "Installing nixos"
nixos-install --flake "path:/nixfiles#${_HOSTNAME}" --no-root-passwd -v --root /mnt
