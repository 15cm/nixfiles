{ modulesPath, ... }:
{
  imports = [
    ./aria-ng.nix
    (modulesPath + "/programs/proxychains.nix")
  ];
}
