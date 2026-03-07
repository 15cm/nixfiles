{ pkgs }:

{
  mkJailedShellConfig = extraPkgs: {
    extraPkgs = with pkgs; [
      git
      gh
    ] ++ extraPkgs;
    extraReadonlyDirs = [
      "~/.config/git"
      "/nix/store"
    ];
  };
}
