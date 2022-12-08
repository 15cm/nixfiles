{ ... }:

{
  users.groups.uinput = { };
  users.users.sinkerine = { extraGroups = [ "input" "uinput" ]; };
}
