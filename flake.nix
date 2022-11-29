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
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      state = (import ./home/state);
    in rec {
      overlays = import ./overlays;
      legacyPackages = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = with overlays; [ additions ];
          config.allowUnfree = true;
        });
      packages = forAllSystems
        (system: import ./pkgs { pkgs = legacyPackages.${system}; });
      homeConfigurationArgs = {
        "sinkerine@kazuki" = {
          pkgs = legacyPackages."x86_64-linux";
          modules = [ ./home/users/sinkerine/kazuki ./modules/home-manager ];
        };
      };
      homeConfigurations = nixpkgs.lib.pipe homeConfigurationArgs [
        (builtins.mapAttrs (configName: v:
          v // {
            extraSpecialArgs = (v.extraSpecialArgs or { }) // {
              inherit configName;
              inherit (state) colorScheme;
              projectRootUnderHome = ".nixfiles";
            };
          }))
        (builtins.mapAttrs (_: v: home-manager.lib.homeManagerConfiguration v))
      ];
    };
}
