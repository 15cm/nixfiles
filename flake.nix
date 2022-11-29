{
  description = "Nix Flakes of Sinkerine";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }@inputs:
    let
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      state = (import ./home/state);
      emacsOverlay = (import (builtins.fetchGit {
        url = "https://github.com/nix-community/emacs-overlay.git";
        ref = "master";
        rev = "c231c73992cf9a024070b841fdcfdf067da1a3dd";
      }));
    in rec {
      overlays = import ./overlays;
      legacyPackages = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = with overlays; [ additions emacsOverlay ];
          config.allowUnfree = true;
        });
      packages = forAllSystems
        (system: import ./pkgs { pkgs = legacyPackages.${system}; });
      homeConfigurationArgs = {
        "sinkerine@kazuki" = {
          pkgs = legacyPackages."x86_64-linux";
          modules = [ ./home/users/sinkerine/kazuki ./modules/home-manager ];
          extraSpecialArgs = { hostname = "kazuki"; };
        };
      };
      homeConfigurations = nixpkgs.lib.pipe homeConfigurationArgs [
        (builtins.mapAttrs (configName: v:
          v // {
            extraSpecialArgs = (v.extraSpecialArgs or { }) // {
              inherit configName;
              inherit (state) theme;
              projectRootUnderHome = ".nixfiles";
              mylib = (import ./lib {
                inherit (v) pkgs;
                inherit (v.pkgs) lib;
              });
            };
          }))
        (builtins.mapAttrs (_: v: home-manager.lib.homeManagerConfiguration v))
      ];
    };
}
