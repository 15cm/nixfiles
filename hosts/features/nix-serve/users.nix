{ config, ... }:

{

  users.extraUsers.nix-serve = {
    description = "Nix-serve user";
    uid = config.my.ids.uids.nix-serve;
    group = "nix-serve";
  };
  users.groups.nix-serve = { gid = config.my.ids.uids.nix-serve; };
}
