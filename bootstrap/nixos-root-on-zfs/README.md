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
SSH into the target host as root and run 

``` sh
bash /nixfiles/bootstrap/nixos-root-on-zfs/install-linux.sh -h <host_name> -d </dev/disk/by-path/disk_path> [-s] <size>
```

### 4
Verify the content of /mnt. Then export the zfs pool:
```
umount -Rl /mnt
zpool export -a
```

### 4
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
### 1
For rescuing an existing system in the live usb, mounts the directories:
```
export DISK=</dev/disk/by-id/...>

zpool import -a -f -N -R /mnt
zfs load-key rpool
zfs mount -a
export ESP_PART=${DISK}-part1
mkdir -p /mnt/boot
mount -t vfat $ESP_PART /mnt/boot
```

### 2
In `install-linux.sh`, before `nixos-install`, you might want to verify the configuration first by
```
nix build --experimental-features 'nix-command flakes' "path:/nixfiles#nixosConfigurations.<target_hostname>.config.system.build.toplevel"
```

### 3
The `neededForBoot=true` in the sed replacement of hardware-configuration.nix is important to allow sops-nix to access the encryption keys in its activation script. ([ref](https://github.com/Mic92/sops-nix/issues/24))


## Ref
- [gist -- NixOS with ZFS](https://gist.github.com/lucasvo/35e0745b72dd384dcb9b9ee5bae5fecb)
- [ZFS Datasets for NixOS](https://grahamc.com/blog/nixos-on-zfs)
- [Erase your darlings ](https://grahamc.com/blog/erase-your-darlings)
- [Docker on ZFS without ZFS](https://www.dominicdoty.com/2020/10/24/dockeronzvol.html)
