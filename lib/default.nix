args@{ ... }:

{
  inherit (import ./template.nix args)
    templateFile templateShellScriptFile writeShellScriptFile;
  inherit (import ./options.nix args) mkDefaultTrueEnableOption;
  inherit (import ./file.nix args) mkOutOfStoreSymlinkRecusively;
}
