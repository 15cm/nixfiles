{
  description = "Nix Flakes of Sinkerine";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      homeConfigurationArgs = {
        "sinkerine@kazuki" = {
          modules = [ ./home/users/sinkerine/kazuki ./modules/home-manager ];
        };
      };
    in {
      # Generated configurations:
      # "<username@hostname/colorScheme> = {}"
      homeConfigurations =
        nixpkgs.lib.trivial.pipe [ "default" "dark" "light" ] [
          (map (colorScheme:
            # By default use dark color scheme.
            nixpkgs.lib.attrsets.mapAttrs' (name: value:
              nixpkgs.lib.attrsets.nameValuePair (name
                + (if colorScheme == "default" then "" else "/" + colorScheme))
              (value // {
                extraSpecialArgs = {
                  colorScheme =
                    (if colorScheme == "default" then "dark" else colorScheme);
                };
              })) homeConfigurationArgs))
          (builtins.foldl' (x: y: x // y) { })
          # Got parameterized home configurations args.
          # Add shared attributes.
          (builtins.mapAttrs (name: value:
            value // {
              inherit pkgs;
            }))
          (builtins.mapAttrs
            (name: value: home-manager.lib.homeManagerConfiguration value))
        ];
    };
}
