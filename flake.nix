{
  description = "Nix Flakes of Sinkerine";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.05";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur = { url = "github:nix-community/NUR"; };
    flake-utils.url = "github:numtide/flake-utils";
    # nixgl is needed for alacritty outside of nixOS
    # refer to https://github.com/NixOS/nixpkgs/issues/122671
    # https://github.com/guibou/nixGL/#use-an-overlay
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    nixgl = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:guibou/nixGL";
    };
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs-stable";
    };
    kmonad = {
      url = "github:kmonad/kmonad?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs-stable.follows = "nixpkgs-stable";
    };
    nixos-hardware = { url = "github:NixOS/nixos-hardware/master"; };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nur, nixgl, flake-utils, sops-nix
    , kmonad, nixos-hardware, deploy-rs, emacs-overlay, hyprland, ... }:
    let
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      state = (import ./home/state);
    in rec {
      overlays = import ./overlays { inherit nixpkgs; };
      packages = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = with overlays; [
            additions
            modifications
            nixgl.overlays.default
            kmonad.overlays.default
            emacs-overlay.overlays.default
          ];
          config.allowUnfree = true;
          config.permittedInsecurePackages = [ "electron-24.8.6" ];
        });

      homeConfigurationArgs = {
        "sinkerine@kazuki" = {
          pkgs = packages."x86_64-linux";
          modules = [ ./home/users/sinkerine/kazuki ];
          extraSpecialArgs = {
            hostname = "kazuki";
            isLinuxGui = true;
          };
        };
        "sinkerine@asako" = {
          pkgs = packages."x86_64-linux";
          modules = [ ./home/users/sinkerine/asako ];
          extraSpecialArgs = {
            hostname = "asako";
            isLinuxGui = true;
          };
        };
        "sinkerine@sachi" = {
          pkgs = packages."x86_64-linux";
          modules = [ ./home/users/sinkerine/sachi ];
          extraSpecialArgs = {
            hostname = "sachi";
            isLinuxGui = false;
          };
        };
        "sinkerine@yumiko" = {
          pkgs = packages."x86_64-linux";
          modules = [ ./home/users/sinkerine/yumiko ];
          extraSpecialArgs = {
            hostname = "yumiko";
            isLinuxGui = false;
          };
        };
        "sinkerine@amane" = {
          pkgs = packages."x86_64-linux";
          modules = [ ./home/users/sinkerine/amane ];
          extraSpecialArgs = {
            hostname = "amane";
            isLinuxGui = false;
          };
        };
        "work@desktop" = {
          pkgs = packages."x86_64-linux";
          modules = [ ./home/users/work/desktop/default.nix ];
          extraSpecialArgs = {
            hostname = "desktop";
            isLinuxGui = true;
          };
        };
      };
      homeConfigurations = nixpkgs.lib.pipe homeConfigurationArgs [
        (builtins.mapAttrs (configName: v:
          v // {
            modules = v.modules ++ [
              ./modules/home-manager
              ./home/modules
              hyprland.homeManagerModules.default
              { imports = [ nur.hmModules.nur ]; }
            ];
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
        # TODO: migrate to unencrypted pool + encrypted dataset.
        "kazuki" = rec {
          system = "x86_64-linux";
          pkgs = builtins.getAttr system packages;
          modules = [ ./hosts/kazuki hyprland.nixosModules.default ]
            ++ (with nixos-hardware.nixosModules;
              [ common-gpu-nvidia-nonprime ]);
          specialArgs = { hostname = "kazuki"; };
        };
        # TODO: migrate to unencrypted pool + encrypted dataset.
        "asako" = rec {
          system = "x86_64-linux";
          pkgs = builtins.getAttr system packages;
          modules = [
            ./hosts/asako
            hyprland.nixosModules.default
            kmonad.nixosModules.default
          ] ++ (with nixos-hardware.nixosModules; [ lenovo-thinkpad-z13-gen1 ]);
          specialArgs = { hostname = "asako"; };
        };
        # TODO: migrate to unencrypted pool + encrypted dataset.
        "sachi" = rec {
          system = "x86_64-linux";
          pkgs = builtins.getAttr system packages;
          modules = [ ./hosts/sachi ];
          specialArgs = { hostname = "sachi"; };
        };
        "yumiko" = rec {
          system = "x86_64-linux";
          pkgs = builtins.getAttr system packages;
          modules = [ ./hosts/yumiko ];
          specialArgs = { hostname = "yumiko"; };
        };
        "amane" = rec {
          system = "x86_64-linux";
          pkgs = builtins.getAttr system packages;
          modules = [ ./hosts/amane ];
          specialArgs = { hostname = "amane"; };
        };
      };
      nixosConfigurations = builtins.mapAttrs (_: v:
        nixpkgs.lib.nixosSystem (v // {
          modules = v.modules
            ++ [ ./modules/nixos ./hosts/modules sops-nix.nixosModules.sops ];
          specialArgs = v.specialArgs // {
            inherit (self) inputs;
            mylib = (import ./lib {
              inherit (v) pkgs;
              inherit (v.pkgs) lib;
            });
          };
        })) nixosConfigurationArgs;

      deploy = {
        nodes = nixpkgs.lib.genAttrs [ "sachi" "amane" "yumiko" "asako" ]
          (hostname: {
            inherit hostname;
            profilesOrder = [ "system" "home" ];
            profiles = {
              system = {
                sshUser = "root";
                path = deploy-rs.lib.x86_64-linux.activate.nixos
                  (builtins.getAttr hostname self.nixosConfigurations);
              };
              home = {
                sshUser = "sinkerine";
                path = deploy-rs.lib.x86_64-linux.activate.home-manager
                  (builtins.getAttr "sinkerine@${hostname}"
                    self.homeConfigurations);
              };
            };
          });
      };
      checks = builtins.mapAttrs
        (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
      devShells = forAllSystems (system: {
        python-dev = import ./shell/python-dev.nix {
          pkgs = builtins.getAttr system packages;
        };
      });
    };
}
