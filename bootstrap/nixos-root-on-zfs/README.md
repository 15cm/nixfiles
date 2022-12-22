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
SSH into the target host as root and run `bash /nixfiles/bootstrap/nixos-root-on-zfs/install.sh <hostname> <disk_path>`.

### 4
Verify the content of /mnt. Then export the zfs pool:
```
umount -Rl /mnt
zpool export -a
```

### 5
Reboot the matchine. After reboot, switch to tty and setup home manager:
```
nix build --no-link --impure 'path:/nixfiles#homeConfigurations.sinkerine@<hostname>.activationPackage'
"$(nix path-info --impure 'path:/nixfiles#homeConfigurations.sinkerine@<hostname>.activationPackage')"/activate
```

### 6
Pull the configs out side of nixfiles.

#### Emacs
```
# For hosts that have access to my git repo, get ssh keys and then:
git clone git@github.com:15cm/spacemacs-config.git ~/.spacemacs.d
# Otherwise
git clone https://github.com/15cm/spacemacs-config.git ~/.spacemacs.d
```

Import the gpg of `i@15cm.net` or `share@15cm.net`. Then
```
cd ~/.spacemacs.d
git-secret reveal
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
In `install.sh`, before `nixos-install`, you might want to verify the configuration first by
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
