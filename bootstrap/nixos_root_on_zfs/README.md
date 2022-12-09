## Steps
### 1
The nix config files should be copied into /nixfiles like:
```
rsync -ahP ~/.nixfiles/ root@<host>:/nixfiles
```

### 2
The sops secret files '/keys/age/<hostname>.txt" should be copied to the machine first like:
```
rsync -ahP --relative /keys/age/<hostname>.txt root@<host>:/
```

### 3
In `install.sh`, before `nixos-install`, you might want to verify the configuration first by
```
nix build --experimental-features 'nix-command flakes' "path:/nixfiles#nixosConfigurations.<target_hostname>.config.system.build.toplevel"
```

### 4
The `neededForBoot=true` in the sed replacement of hardware-configuration.nix is important to allow sops-nix to access the encryption keys in its activation script. ([ref](https://github.com/Mic92/sops-nix/issues/24))

### 5
After `install.sh`, fix the permissions of these folders and link them into your home directory as needed:
- Link /mnt/keys/age/<hostname>.txt to /mnt/home/<hostname>/.config/sops/age/keys.txt
- Change permissions of /mnt/nixfiles

### 6
At last, before rebooting the machine, export the zfs pool:
```
umount -Rl /mnt
zpool export -a
```

### 7
After reboot, switch to tty and setup home manager:
```
nix build --no-link --impure 'path:/nixfiles#homeConfigurations.sinkerine@<hostname>.activationPackage'
"$(nix path-info --impure 'path:/nixfiles#homeConfigurations.sinkerine@asako.activationPackage')"/activate
```

Copy the configs out side of nixfiles:
```
# For hosts that have access to my git repo, get ssh keys and then:
git clone git@github.com:15cm/spacemacs-config.git ~/.spacemacs.d
# Otherwise
git clone https://github.com/15cm/spacemacs-config.git ~/.spacemacs.d
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

## Ref
- [gist -- NixOS with ZFS](https://gist.github.com/lucasvo/35e0745b72dd384dcb9b9ee5bae5fecb)
- [ZFS Datasets for NixOS](https://grahamc.com/blog/nixos-on-zfs)
- [Erase your darlings ](https://grahamc.com/blog/erase-your-darlings)
- [Docker on ZFS without ZFS](https://www.dominicdoty.com/2020/10/24/dockeronzvol.html)
