#!/bin/bash

set -euo pipefail

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

# PARTITON DISK:
# p1 4GB ESP+EFI
# p2 REST ZFS
info "Partitioning $DISK"
sgdisk --zap-all $DISK
sgdisk -n1:1M:+4G -t1:EF00 -c ESP $DISK
sgdisk -n2:0:0    -t2:BF00 -c ROOT $DISK
partprobe $DISK
sleep 1

export ESP_PART=${DISK}-part1
export ZFS_PART=${DISK}-part2

info "Creating zfs root pool"
export RPOOL="rpool"
zpool create \
    -o autotrim=on \
    -O relatime=on \
    -O acltype=posixacl \
    -O canmount=off \
    -O compression=lz4 \
    -O encryption=aes-256-gcm \

    -O keyformat=passphrase \
    -O keylocation=prompt \
    -O dnodesize=auto \
    -O normalization=formD \
    -O xattr=sa \
    -O devices=off \
    -O mountpoint=none \
    -R /mnt \
    $RPOOL \
    $ZFS_PART

info "Creating zfs datasets"
# Not mountable
# Ephemeral datasets. They don't need to have any data in a clean build.
zfs create -o mountpoint=none -o canmount=off $RPOOL/system
# Persistent datasets
zfs create -o mountpoint=/ -o canmount=off $RPOOL/data
# Mountable
# In a pure stateless system, we can only persist files under '/' that stateful. It's too aggresive for now. So keep '/' in 'data/' the dataset instead of the 'system/' dataset.
zfs create -o mountpoint=/ -o canmount=on $RPOOL/data/root
# Must be placed after root datasets to avoid the /mnt/boot is overwritten by the /mnt mountpoint.
zfs create -o mountpoint=/nix -o canmount=on $RPOOL/system/nix
zfs create -o canmount=on $RPOOL/data/nixfiles
zfs create -o canmount=on $RPOOL/data/keys
zfs create -o canmount=on $RPOOL/data/home
zfs create -o canmount=on $RPOOL/data/home/sinkerine
zfs create -o canmount=on $RPOOL/data/home/sinkerine/.cache
zfs create -o canmount=on $RPOOL/data/home/sinkerine/vmware

info "Creating a zfs zvol for the docker mount point"
zfs create \
    -o compression=lz4 \
    -V 60gb \
    $RPOOL/data/var-lib-docker
export ZDOCKER_VOL=/dev/zvol/$RPOOL/data/var-lib-docker
for i in {1..5}; do
  info "Waiting for $ZDOCKER_VOL to appear. $i out of 5 times..."
  sleep 2
  if [ -e $ZDOCKER_VOL ]; then
    break
  fi
done
if [ -e $ZDOCKER_VOL ]; then
  info "$ZDOCKER_VOL is found."
else
  err "$ZDOCKER_VOL not found. Abort."
  exit 1
fi
export ZDOCKER_DISK=$(readlink -f $ZDOCKER_VOL)
sgdisk --zap-all $ZDOCKER_DISK
sgdisk -n1:0:0 -t1:8300 -c DOCKER $ZDOCKER_DISK
partprobe $ZDOCKER_DISK
sleep 1
export ZDOCKER_PART=${ZDOCKER_DISK}p1
mkfs.ext4 $ZDOCKER_PART

info "Mounting zfs datasets"
zfs mount -a

info "Changing directory permissions"
USER_ID=1000
chown -R 1000:1000 /mnt/nixfiles /mnt/keys /mnt/home
chmod 700 /mnt/keys /mnt/keys/age
chmod 500 /mnt/keys/age/*

info "Formatting and mounting the esp"
mkfs.vfat -n ESP $ESP_PART
mkdir -p /mnt/boot
mount -t vfat $ESP_PART /mnt/boot

# Disable cache, stale cache will prevent system from booting
info "Disabling zfs cache"
mkdir -p /mnt/etc/zfs/
rm -f /mnt/etc/zfs/zpool.cache
touch /mnt/etc/zfs/zpool.cache
chmod a-w /mnt/etc/zfs/zpool.cache
chattr +i /mnt/etc/zfs/zpool.cache

info "Generating nix default configurations"
nixos-generate-config --root /mnt

info "Copying and updating hardware-configuration.nix"
export NIXFILES_HOST_DIR=/nixfiles/hosts/${_HOSTNAME}
mkdir -p ${NIXFILES_HOST_DIR}/generated
cp -f /mnt/etc/nixos/hardware-configuration.nix ${NIXFILES_HOST_DIR}/generated/hardware-configuration.nix
sed -i 's|fsType = "zfs";|fsType = "zfs";\n      options = [ "zfsutil" "X-mount.mkdir" ];\n      neededForBoot = true;|g' \
    ${NIXFILES_HOST_DIR}/generated/hardware-configuration.nix

info "Writing extra-configuration.nix"
export ZDOCKER_UUID=$(blkid --match-tag UUID --output value $ZDOCKER_PART)
cat << EOF > ${NIXFILES_HOST_DIR}/generated/extra-configuration.nix
{ ... }:

{
  # hostid is required by zfs.
  networking.hostId = "$(head -c 8 /etc/machine-id)";

  # Additional zfs mont points that are not auto generated.
  fileSystems."/var/lib/docker" = {
      device = "/dev/disk/by-uuid/${ZDOCKER_UUID}";
      fsType = "ext4";
      options = [
        "nodev"
        "nofail"
      ];
    };
}
EOF

info "Cleaning up useless files in /mnt"
rm -rf /mnt/etc/nixos

info "Copying necessary files to /mnt"
rsync -ahP /keys/ /mnt/keys
rsync -ahP /nixfiles/ /mnt/nixfiles

info "Installing nixos"
nixos-install --flake "path:/nixfiles#${_HOSTNAME}" --no-root-passwd -v --root /mnt
