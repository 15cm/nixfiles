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
    kmonad = {
      url = "github:kmonad/kmonad?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    envfs = {
      url = "github:Mic92/envfs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, emacs-overlay, nixgl, flake-utils, sops-nix
    , kmonad, nixos-hardware, envfs, ... }@inputs:
    let
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      state = (import ./home/state);
    in rec {
      overlays = import ./overlays;
      packages = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = with overlays; [
            additions
            modifications
            emacs-overlay.overlay
            nixgl.overlays.default
            kmonad.overlays.default
          ];
          config.allowUnfree = true;
          config.permittedInsecurePackages = [
            # For goldendict
            "qtwebkit-5.212.0-alpha4"
          ];
        });

      homeConfigurationArgs = {
        "sinkerine@kazuki" = {
          pkgs = packages."x86_64-linux";
          modules = [ ./home/users/sinkerine/kazuki ];
          extraSpecialArgs = { hostname = "kazuki"; };
        };
        "sinkerine@asako" = {
          pkgs = packages."x86_64-linux";
          modules = [ ./home/users/sinkerine/asako ];
          extraSpecialArgs = { hostname = "asako"; };
        };
        "sinkerine@sachi" = {
          pkgs = packages."x86_64-linux";
          modules = [ ./home/users/sinkerine/sachi ];
          extraSpecialArgs = { hostname = "sachi"; };
        };
      };
      homeConfigurations = nixpkgs.lib.pipe homeConfigurationArgs [
        (builtins.mapAttrs (configName: v:
          v // {
            modules = v.modules ++ [ ./modules/home-manager ];
            extraSpecialArgs = (v.extraSpecialArgs or { }) // rec {
              inherit state;
              nixinfo = {
                inherit configName;
                projectRoot = "/nixfiles";
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
          pkgs = builtins.getAttr system packages;
          modules = [ ./hosts/kazuki ] ++ (with nixos-hardware.nixosModules;
            [ common-gpu-nvidia-nonprime ]);
          specialArgs = { hostname = "kazuki"; };
        };
        "asako" = rec {
          system = "x86_64-linux";
          pkgs = builtins.getAttr system packages;
          modules = [ ./hosts/asako kmonad.nixosModules.default ]
            ++ (with nixos-hardware.nixosModules; [ lenovo-thinkpad-z13 ]);
          specialArgs = { hostname = "asako"; };
        };
        "sachi" = rec {
          system = "x86_64-linux";
          pkgs = builtins.getAttr system packages;
          modules = [ ./hosts/sachi ];
          specialArgs = {
            hostname = "sachi";
            encryptedZfsPool = "main";
          };
        };
      };
      nixosConfigurations = builtins.mapAttrs (_: v:
        nixpkgs.lib.nixosSystem (v // {
          modules = v.modules ++ [
            ./modules/nixos
            sops-nix.nixosModules.sops
            envfs.nixosModules.envfs
          ];
          specialArgs = v.specialArgs // {
            mylib = (import ./lib {
              inherit (v) pkgs;
              inherit (v.pkgs) lib;
            });
          };
        })) nixosConfigurationArgs;
    };
}
