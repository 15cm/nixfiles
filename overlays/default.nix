{
  # Adds my custom packages
  additions = final: _prev: import ../pkgs { pkgs = final; };

  modifications = final: prev: {
    # The original zplug package writes directly to $out/, i.e. .nix-profile/, which causes conflicts.
    zplug = prev.zplug.overrideAttrs (old: {
      installPhase = ''
        outdir=$out/share/zplug
        mkdir -p $outdir
        cp -r $src/* $outdir/
      '';
    });
  };
}
