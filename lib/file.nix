{ lib, nixinfo, ... }:

with lib; {
  mkOutOfStoreSymlinkRecusively =
    config: configDirRelativeUnderProjectRoot: namePrefix:
    let
      configRoot =
        "${nixinfo.projectRoot}/${configDirRelativeUnderProjectRoot}";
    in pipe configRoot [
      filesystem.listFilesRecursive
      (map (builtins.replaceStrings [ "${configRoot}/" ] [ "" ]))
      (map (relativePath: {
        name = "${namePrefix}/${relativePath}";
        value = "${configRoot}/${relativePath}";
      }))
      builtins.listToAttrs
      (builtins.mapAttrs
        (_: v: { source = config.lib.file.mkOutOfStoreSymlink v; }))
    ];
}
