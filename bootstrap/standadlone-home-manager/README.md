# Steps
## 1 Clone Repo
sudo git clone https://github.com/15cm/nixfiles /nixfiles
sudo chown -R ${USER} /nixfiles

## 2 Install Nix
```
curl -L https://nixos.org/nix/install > /tmp/install-nix.sh
export NIX_FIRST_BUILD_UID=2147483000
export NIX_BUILD_GROUP_ID=2147483000
sh /tmp/install-nix.sh --daemon
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf
```

Then reboot the system.

Note: The Nix uid/gid avoid collisions with existing user (e.g. in /etc/passwd.cache) in systems that uses LDAP.

## 3 [Optional] If it's a work profile
Fill in the `home.username` and `home.homeDirectory`of the config with your username in the corporation, e.g. /nixfiles/home/users/work/desktop/default.nix

```
cp /nixfiles/home/state/default.example.nix /nixfiles/home/state/default.nix
```

## 4 Initialize Home Manager
```
nix build --no-link --impure path:/nixfiles#homeConfigurations.<username>@<hostname>.activationPackage
"$(nix path-info --impure path:/nixfiles#homeConfigurations.<username>@<hostname>.activationPackage)"/activate
```

