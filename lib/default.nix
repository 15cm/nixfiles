args@{ ... }:

{
  inherit (import ./template.nix args) templateFile templateShellScriptFile;
  inherit (import ./options.nix args) mkDefaultTrueEnableOption;
}
