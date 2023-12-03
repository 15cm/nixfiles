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

usage() {
  cat << EOF
Usage: ${0} [OPTIONS] [ARGUMENTS]
Options:
  --help         Display this help and exit
  -h, --hostname       <hostname> of the machine
  -d, --disk           </dev/disk/by-path/disk> of the disk for installation
  [-s, --size]         <size> of the zfs data partition in sgdisk end section format. Default value: use all remaining space of the partition.
  [-c, --compression]  <compression> of the zfs data partition. Default value: zstd
  [-ds, --docker_size] <size> of the docker zfs vol. Default value: 60GB.
EOF
}

docker_size="60GB"
zfs_compression="zstd"
while (("$#")); do
  case "$1" in
    -h|--hostname)
      host_name="$2"
      shift 2
      ;;
    -d|--disk)
      disk="$2"
      shift 2
      ;;
    -c|--compression)
      zfs_compression="$2"
      shift 2
      ;;
    -s|--size)
      size="$2"
      shift 2
      ;;
    -ds|--docker_size)
      docker_size="$2"
      shift 2
      ;;
    --help)
      help=true
      shift
      ;;
    *)
      shift
      ;;
  esac
done

if [[ -n $help || -z $host_name || -z $disk ]]; then
  usage
  exit 0
fi

# Partition the disk:
# p1 1GB ESP+EFI
# p2 REST ZFS
info "Partitioning $disk"
sgdisk --zap-all $disk
sgdisk -n1:1M:+1G        -t1:EF00 $disk
if [ -n $size ]; then
  sgdisk -n2:0:+${size}  -t2:BF00 $disk
else
  sgdisk -n2::           -t2:BF00 $disk
fi
sleep 3
partprobe $disk

esp_part=${disk}-part1
zfs_part=${disk}-part2

for i in {1..10}; do
  info "Waiting for esp and zfs partitions to be ready. $i out of 10 retries"
  sleep 3
  if [[ -e $esp_part && -e $zfs_part ]]; then
    break
  fi
done

info "Unmounting /mnt"
umount -Rl /mnt || :

rpool="rpool"
if [ zpool list -o name | tail -n +2 | grep -q $rpool ]; then
  info "ZFS root pool '$RPOOL' already exists. Destroying it."
  zpool destroy -f $rpool
fi
info "Creating zfs root pool"
zpool create \
    -o autotrim=on \
    -O relatime=on \
    -O acltype=posixacl \
    -O canmount=off \
    -O compression=${zfs_compression} \
    -O encryption=aes-256-gcm \
    -O keyformat=passphrase \
    -O keylocation=prompt \
    -O dnodesize=auto \
    -O normalization=formD \
    -O xattr=sa \
    -O devices=off \
    -O mountpoint=none \
    -R /mnt \
    -f \
    $rpool \
    $zfs_part

info "Creating zfs datasets"
# Not mountable
# Ephemeral datasets. They don't need to have any data in a clean build.
zfs create -o mountpoint=none -o canmount=off $rpool/system
# Persistent datasets
zfs create -o mountpoint=/ -o canmount=off $rpool/data
# Mountable
# In a pure stateless system, we can only persist files under '/' that stateful. It's too aggresive for now. So keep '/' in 'data/' the dataset instead of the 'system/' dataset.
zfs create -o mountpoint=/ -o canmount=on $rpool/data/root
# Must be placed after root datasets to avoid the /mnt/boot is overwritten by the /mnt mountpoint.
zfs create -o mountpoint=/nix -o canmount=on $rpool/system/nix
zfs create -o canmount=on $rpool/data/nixfiles
zfs create -o canmount=on $rpool/data/keys
zfs create -o canmount=on $rpool/data/home
zfs create -o canmount=on $rpool/data/home/sinkerine
zfs create -o canmount=on $rpool/data/home/sinkerine/.cache
zfs create -o canmount=on $rpool/data/home/sinkerine/vmware

info "Creating a zfs zvol for the docker mount point"
zfs create \
    -o compression=${zfs_compression} \
    -V ${docker_size} \
    $rpool/data/var-lib-docker
zdocker_vol=/dev/zvol/$rpool/data/var-lib-docker
for i in {1..5}; do
  info "Waiting for $zdocker_vol to appear. $i out of 5 times..."
  sleep 2
  if [ -e $zdocker_vol ]; then
    break
  fi
done
if [ -e $zdocker_vol ]; then
  info "$zdocker_vol is found."
else
  err "$zdocker_vol not found. Abort."
  exit 1
fi
zdocker_disk=$(readlink -f $zdocker_vol)
sgdisk --zap-all $zdocker_disk
sgdisk -n1:0:0 -t1:8300 $zdocker_disk
partprobe $zdocker_disk
sleep 1
zdocker_part=${zdocker_disk}p1
mkfs.ext4 -L DOCKER $zdocker_part

info "Mounting zfs datasets"
zfs mount -a

info "Changing directory permissions"
USER_ID=1000
chown -R 1000:1000 /nixfiles /keys /mnt/home
chmod 700 /keys /keys/age
chmod 500 /keys/age/*

info "Formatting and mounting the esp"
mkfs.vfat -n ESP $esp_part
mount --mkdir -t vfat $esp_part /mnt/boot

# Disable cache, stale cache will prevent system from booting
info "Disabling zfs cache"
mkdir -p /mnt/etc/zfs/
rm -f /mnt/etc/zfs/zpool.cache
touch /mnt/etc/zfs/zpool.cache
chmod a-w /mnt/etc/zfs/zpool.cache
chattr +i /mnt/etc/zfs/zpool.cache

info "Copying necessary files to /mnt"
rsync -ahP /keys/ /mnt/keys
rsync -ahP /nixfiles/ /mnt/nixfiles

info "Installing nixos"
nixos-install --flake "path:/nixfiles#${host_name}" --no-root-passwd -v --root /mnt

info "Creating symlink of sops keys to ~/.config/sops/age/"
home_dir=/mnt/home/sinkerine
mkdir -p ${home_dir}/.config/sops/age
ln -sf /keys/age/${host_name}.txt ${home_dir}/.config/sops/age/keys.txt
chown 1000:1000 ${home_dir} ${home_dir}/.config
chown -R 1000:1000 ${home_dir}/.config/sops
