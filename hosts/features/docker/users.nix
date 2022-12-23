{ config, pkgs, ... }:

{
  # uid/gid matches the default one used by NixOS https://github.com/NixOS/nixpkgs/blob/bb31220cca6d044baa6dc2715b07497a2a7c4bc7/nixos/modules/config/update-users-groups.pl#L325
  users.groups.dockremap = { gid = 100000; };
  users.users.dockremap = {
    isSystemUser = true;
    uid = 100000;
    group = "dockremap";
  };
}
