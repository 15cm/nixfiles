## Steps
### 1
The nix config files should be copied into /nixfiles like:
```
rsync -ahP /nixfiles root@<host>:/
```

### 2
The sops secret files '/keys/age/<hostname>.txt" should be copied to the machine first like:
```
rsync -ahP --relative /keys/age/<hostname>.txt root@<host>:/
```

### 3
SSH into the target host as root and run the install script for help and then fill in the params.

``` sh
bash /nixfiles/bootstrap/nixos-root-on-zfs/install-linux.sh
```

### 3.1 Windows dual boot on the same disk
Optionally, create the windows partitions:

``` sh
bash /nixfiles/bootstrap/nixos-root-on-zfs/install-windows.sh
```

### 3.2 Windows dual boot on the 2nd disk

``` sh
bash /nixfiles/bootstrap/nixos-root-on-zfs/install-windows.sh --separate_esp
```

After installing Windows on the 2nd disk, if Windows format and label the dummy ESP partition as ESP,

``` sh
fatlabel <2st_disk_esp_partition> ESP2
fatlabel <1st_disk_esp_partition> ESP
```

and consider using efibootmgr to clean up the entries like

``` sh
efibootmgr -b <entry_number> -B
```

### 4
Verify the content of /mnt. Then export the zfs pool:
```
umount -Rl /mnt
zpool export -a
```

### 5
Reboot the machine. After reboot, switch to tty and setup home manager:
```
nix build --no-link path:/nixfiles#homeConfigurations.${USER}@$(hostname).activationPackage
"$(nix path-info path:/nixfiles#homeConfigurations.${USER}@$(hostname).activationPackage)"/activate
```

If the machine is a remote headless machine, we always want to deploy it via deploy-rs, so remove the nixfiles (/keys shouldn't be removed because sops decrypt in activation scripts):
```
rm -rf /nixfiles
```

## Notes
### Mount the existing system
For rescuing an existing system in the live usb, mounts the directories:
```
DISK=</dev/disk/by-path/...>

zpool import -a -f -N -R /mnt
zfs load-key rpool
zfs mount -a
ESP_PART=${DISK}-part1
mkdir -p /mnt/boot
mount -t vfat $ESP_PART /mnt/boot
```

### Verify configuration
In `install-linux.sh`, before `nixos-install`, you might want to verify the configuration first by
```
nix build --experimental-features 'nix-command flakes' "path:/nixfiles#nixosConfigurations.<target_hostname>.config.system.build.toplevel"
```

### neededForBoot
The `neededForBoot=true` in the sed replacement of hardware-configuration.nix is important to allow sops-nix to access the encryption keys in its activation script. ([ref](https://github.com/Mic92/sops-nix/issues/24))

### To restore from an existing snapshot data

On the new machine, destroy the existing dataset:
``` sh
zfs destroy -r rpool/data/home/sinkerine
```

On the machine that has the backup, run:
``` sh
sudo zfs send -c <backup@snapshot> | ssh <root@new_machine_host> "zfs recv rpool/data/home/sinkerine"
```

Create the backup-disabled datasets back as needed:

``` sh
zfs create -o canmount=on rpool/data/home/sinkerine/.cache
zfs create -o canmount=on rpool/data/home/sinkerine/vmware
chown -R 1000:1000 /mnt/home/sinkerine/.cache /mnt/home/sinkerine/vmware
```

### More than one matching pool found
zpool can find more than one matching pool by the pool name if there are leftover zpool label on the disk with old data. It's probably caused by forgetting to `zpool labelclear` or `wipefs -a` on the existing zpool device and then create a new partition table on the device. dd zero to the device to clear all data:

``` sh
dd if=/dev/zero of=</dev/disk/by-path/disk> bs=1M status=progress
```

### Troubleshottings when initialization home manger

> Nix-env error opening lock file

Solution: `rm ~/.nix-profile`. [ref](https://discourse.nixos.org/t/nix-env-error-opening-lock-file/3556/1)

> Activating dconfSettings.
> Error receiving data: Connection reste by peer

Solution: `sudo systemctl restart user@1000.service`

## Ref
- [gist -- NixOS with ZFS](https://gist.github.com/lucasvo/35e0745b72dd384dcb9b9ee5bae5fecb)
- [ZFS Datasets for NixOS](https://grahamc.com/blog/nixos-on-zfs)
- [Erase your darlings ](https://grahamc.com/blog/erase-your-darlings)
- [Docker on ZFS without ZFS](https://www.dominicdoty.com/2020/10/24/dockeronzvol.html)
