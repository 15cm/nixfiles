{ ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  users.mutableUsers = false;
}
