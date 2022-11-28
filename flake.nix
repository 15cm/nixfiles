{
  description = "Nix Flakes of Sinkerine";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      state = (import ./home/state);
      homeConfigurationArgs = {
        "sinkerine@kazuki" = {
          modules = [ ./home/users/sinkerine/kazuki ./modules/home-manager ];
        };
      };
    in {
      homeConfigurations = nixpkgs.lib.pipe homeConfigurationArgs [
        (builtins.mapAttrs (_: v:
          v // {
            inherit pkgs;
            extraSpecialArgs = (v.extraSpecialArgs or { }) // {
              inherit (state) colorScheme;
              projectRootUnderHome = ".nixfiles";
            };
          }))
        (builtins.mapAttrs (_: v: home-manager.lib.homeManagerConfiguration v))
      ];
    };
}
