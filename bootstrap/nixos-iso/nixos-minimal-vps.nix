{ modulesPath, ... }:

{
  imports = [ ./nixos-minimal.nix "${modulesPath}/profiles/qemu-guest.nix" ];
}
