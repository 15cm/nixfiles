{ nixpkgs, ... }:

with nixpkgs.lib; {
  # Adds my custom packages
  additions = self: _super: import ../pkgs { pkgs = self; };

  modifications = self: super: {
    # The original zplug package writes directly to $out/, i.e. .nix-profile/, which causes conflicts.
    zplug = super.zplug.overrideAttrs (old: {
      installPhase = ''
        outdir=$out/share/zplug
        mkdir -p $outdir
        cp -r $src/* $outdir/
      '';
    });
  };
}
