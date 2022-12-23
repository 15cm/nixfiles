## Steps
For installation on VPS, use the image built by [nixos-minimal-vps.nix](../nixos-iso/nixos-minimal-vps.nix) to make sure virtio kernel modules are loaded.

### 1
Follow [steps 1 - 2 in nixos-root-on-zfs](../nixos-root-on-zfs/README.md#1).

### 2
SSH into the target host as root.

#### UEFI Boot
##### If Root and ZFS partitions are on different disks
Run `bash /nixfiles/bootstrap/nixos-root-on-ext4/install.sh <hostname> <disk_path>`

#### Else If Root and ZFS partitions are on the same disks
Run `bash /nixfiles/bootstrap/nixos-root-on-ext4/install.sh <hostname> <disk_path> <root_part_size>`

#### BIOS+GPT Boot
[Arch Wiki ref](https://wiki.archlinux.org/title/Partitioning#BIOS/GPT_layout_example)

##### If Root and ZFS partitions are on different disks
Run `BIOS_BOOT=1 bash /nixfiles/bootstrap/nixos-root-on-ext4/install.sh <hostname> <disk_path>`

#### Else If Root and ZFS partitions are on the same disks
Run `BIOS_BOOT=1 bash /nixfiles/bootstrap/nixos-root-on-ext4/install.sh <hostname> <disk_path> <root_part_size>`

### 3
Verify the content of /mnt. Then unmount:
```
umount -Rl /mnt
```

### [optional] 4 Create zpool
#### encrypted-send-to-untrusted-receiver
For the untrusted host where zfs key won't be loaded, create an unencrypted pool to [allow placeholder datasets to be created](https://zrepl.github.io/configuration/sendrecvoptions.html#placeholders).

```
sudo zpool create \
    -O relatime=on \
    -O acltype=posixacl \
    -O canmount=on \
    -O compression=lz4 \
    -O dnodesize=auto \
    -O normalization=formD \
    -O xattr=sa \
    -O devices=off \
    -O mountpoint=/pool/<pool_name> \
    -f \
    <pool_name> \
    <zfs_partition>
```

#### send-plain-encrypt-on-receive
For the trusted host where zfs key will be loaded, create an encrypted pool.

```
sudo zpool create \
    -O relatime=on \
    -O acltype=posixacl \
    -O canmount=on \
    -O compression=lz4 \
    -O encryption=aes-256-gcm \
    -O keyformat=passphrase \
    -O keylocation=prompt \
    -O dnodesize=auto \
    -O normalization=formD \
    -O xattr=sa \
    -O devices=off \
    -O mountpoint=/pool/<pool_name> \
    -f \
    <pool_name> \
    <zfs_partition>
```

### 5
Follow [steps 4 and 5 in nixos-root-on-zfs](../nixos-root-on-zfs/README.md#5).
