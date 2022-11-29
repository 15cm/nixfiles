{
  description = "Nix Flakes of Sinkerine";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, emacs-overlay, ... }@inputs:
    let
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      state = (import ./home/state);
    in rec {
      overlays = import ./overlays;
      legacyPackages = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = with overlays; [ additions emacs-overlay.overlay ];
          config.allowUnfree = true;
        });
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
              inherit state;
              nixinfo = {
                inherit configName;
                projectRoot = ".nixfiles";
              };
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
