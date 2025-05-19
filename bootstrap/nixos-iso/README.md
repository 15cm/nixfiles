# Usage
NIXPKGS_ALLOW_BROKEN=1 NIX_PATH=nixpkgs=https://github.com/NixOS/nixpkgs/archive/refs/tags/24.11.tar.gz nix-shell -p nixos-generators --run "nixos-generate --format iso --configuration ./nixos-minimal.nix -o /tmp/nixos-install-image"
