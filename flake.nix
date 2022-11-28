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
      homeConfigurations = nixpkgs.lib.trivial.pipe homeConfigurationArgs [
        (builtins.mapAttrs (name: value:
          value // {
            inherit pkgs;
            extraSpecialArgs = (value.extraSpecialArgs or { }) // {
              inherit (state) colorScheme;
              projectRootUnderHome = ".nixfiles";
            };
          }))
        (builtins.mapAttrs
          (name: value: home-manager.lib.homeManagerConfiguration value))
      ];
    };
}
