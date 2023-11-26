args@{ ... }:

{
  inherit (import ./template.nix args)
    templateFile templateShellScriptFile writeShellScriptFile toJSONFile;
  inherit (import ./options.nix args) mkDefaultTrueEnableOption attrsOption;
  inherit (import ./assert.nix args) assertNotNull;
  inherit (import ./utils.nix args)
    applyXwaylandEnvsToDesktopExec applyChromeFlagsToDesktopExec
    applyElectronFlagsToDesktopExec;
}
