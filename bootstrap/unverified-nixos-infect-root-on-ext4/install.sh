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

export _HOSTNAME=$1

if ! [[ -v _HOSTNAME ]]; then
  err "Missing argument <_HOSTNAME> as \$1."
  exit 1
fi
if [[ "$EUID" > 0 ]]; then
  err "Must run as root"
  exit 1
fi

info "Changing directory permissions"
USER_ID=1000
chown -R 1000:1000 /nixfiles /keys
chmod 700 /keys /keys/age
chmod 500 /keys/age/*

info "Copying hardware-configuration.nix"
export NIXFILES_HOST_DIR=/nixfiles/hosts/${_HOSTNAME}
mkdir -p ${NIXFILES_HOST_DIR}/generated
cp -f /etc/nixos/hardware-configuration.nix ${NIXFILES_HOST_DIR}/generated/hardware-configuration.nix

info "Writing extra-configuration.nix"
cat << EOF > ${NIXFILES_HOST_DIR}/generated/extra-configuration.nix
{ ... }:

{
  # hostid is required by zfs.
  networking.hostId = "$(head -c 8 /etc/machine-id)";
}
EOF

info "Cleaning up useless files in /etc"
rm -rf /mnt/etc/nixos

info "Rebuilding nixos"
nixos-rebuild switch --flake "path:/nixfiles#${_HOSTNAME}"

info "Creating symlink of sops keys to ~/.config/sops/age/"
HOME_DIR=/home/sinkerine
mkdir -p ${HOME_DIR}/.config/sops/age
ln -sf /keys/age/${_HOSTNAME}.txt ${HOME_DIR}/.config/sops/age/keys.txt
chown 1000:1000 ${HOME_DIR} ${HOME_DIR}/.config
chown -R 1000:1000 ${HOME_DIR}/.config/sops
