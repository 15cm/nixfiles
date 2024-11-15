#!/bin/bash

set -eox pipefail

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
# An optional param to specify the size of the root partition. If provided, it assume the ZFS partition is on the same disk and occupies the remaining space of the disk.
export ROOT_PART_SIZE=$3

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
umount -Rl /mnt || :

# Disk partition (UEFI):
# p1 512MB ESP+EFI
# p2 EXT4
# [optional] p3 ZFS
#
# Disk partition (BIOS+GPT):
# p1 512MB BIOS boot
# p2 EXT4
# [optional] p3 ZFS
info "Partitioning $DISK"
sgdisk --zap-all $DISK
if [ -v BIOS_BOOT ]; then
  sgdisk -n1:1M:+512M -t1:ef02 $DISK
else
  sgdisk -n1:1M:+512M -t1:EF00 $DISK
fi
if [[ -v ROOT_PART_SIZE ]]; then
  sgdisk -n2:0:+${ROOT_PART_SIZE} -t2:8300 $DISK
  sgdisk -n3:0:0 -t3:BF00 $DISK
else
  sgdisk -n2:0:0 -t2:8300 $DISK
fi
partprobe $DISK

export ESP_PART=${DISK}-part1
export EXT4_PART=${DISK}-part2

for i in {1..10}; do
  info "Waiting for esp and ext4 partitions to be ready. $i out of 10 retries"
  sleep 3
  if [ -e "$ESP_PART" ] && [ -e "$EXT4_PART" ]; then
    break
  fi
done

info "Mounting root"
mkfs.ext4 -L ROOT $EXT4_PART
mkdir -p /mnt
mount --mkdir $EXT4_PART /mnt

info "Formatting and mounting the esp"
mkfs.vfat -n ESP $ESP_PART
if [ -z "$BIOS_BOOT" ]; then
mount --mkdir -t vfat $ESP_PART /mnt/boot
fi

info "Changing directory permissions"
USER_ID=1000
chown -R 1000:1000 /nixfiles /keys
chmod 700 /keys /keys/age
chmod 500 /keys/age/*

info "Copying necessary files to /mnt"
rsync -ahP /keys/ /mnt/keys
rsync -ahP /nixfiles/ /mnt/nixfiles

info "Installing nixos"
nixos-install --flake "path:/nixfiles#${_HOSTNAME}" --no-root-passwd -v --root /mnt

info "Creating symlink of sops keys to ~/.config/sops/age/"
HOME_DIR=/mnt/home/sinkerine
mkdir -p ${HOME_DIR}/.config/sops/age
ln -sf /keys/age/${_HOSTNAME}.txt ${HOME_DIR}/.config/sops/age/keys.txt
chown 1000:1000 ${HOME_DIR} ${HOME_DIR}/.config
chown -R 1000:1000 ${HOME_DIR}/.config/sops
