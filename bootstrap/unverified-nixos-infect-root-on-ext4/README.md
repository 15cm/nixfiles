## Steps
### 1
Reinstall the system to make a partition for ZFS in the boot OS image.

### 2
Deploy an SSH key for the root user by `ssh-copy-id`.

### 3
Follow [steps 1 - 2 in nixos-root-on-zfs](../nixos-root-on-zfs/README.md#1).

### 4
SSH into the target host and run:
```
curl https://raw.githubusercontent.com/elitak/nixos-infect/master/nixos-infect | NIX_CHANNEL=nixos-22.05 bash -x
```

### 4
Run `bash install.sh <hostname>`

Follow [steps 5 in nixos-root-on-zfs](../nixos-root-on-zfs/README.md#5).
