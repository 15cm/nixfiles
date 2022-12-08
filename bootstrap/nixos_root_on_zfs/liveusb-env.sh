export DISK=</dev/disk/by-id/...>

zpool import -a -f -N -R /mnt
zfs load-key rpool
zfs mount -a
export ESP_PART=${DISK}-part1
mkdir -p /mnt/boot
mount -t vfat $ESP_PART /mnt/boot
