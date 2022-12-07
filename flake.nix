{
  description = "Nix Flakes of Sinkerine";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:15cm/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    # nixgl is needed for alacritty outside of nixOS
    # refer to https://github.com/NixOS/nixpkgs/issues/122671
    # https://github.com/guibou/nixGL/#use-an-overlay
    nixgl = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:guibou/nixGL";
    };
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, emacs-overlay, nixgl, flake-utils, sops-nix
    , ... }@inputs:
    let
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      state = (import ./home/state);
    in rec {
      overlays = import ./overlays;
      legacyPackages = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = with overlays; [
            additions
            modifications
            emacs-overlay.overlay
            nixgl.overlays.default
          ];
          config.allowUnfree = true;
          config.permittedInsecurePackages = [
            # For goldendict
            "qtwebkit-5.212.0-alpha4"
          ];
        });

      homeConfigurationArgs = {
        "sinkerine@kazuki" = rec {
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

      nixosConfigurationArgs = {
        "kazuki" = rec {
          system = "x86_64-linux";
          pkgs = builtins.getAttr system legacyPackages;
          modules = [ ./hosts/kazuki ];
          specialArgs = { hostname = "kazuki"; };
        };
      };
      nixosConfigurations = builtins.mapAttrs (_: v:
        nixpkgs.lib.nixosSystem
        (v // { modules = v.modules ++ [ sops-nix.nixosModules.sops ]; }))
        nixosConfigurationArgs;
    };
}
