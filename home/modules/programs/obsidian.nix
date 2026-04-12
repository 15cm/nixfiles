{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.programs.obsidian;
  mkObsidianPlugin =
    {
      pname,
      version,
      repo,
      mainHash,
      manifestHash,
      hasStyles ? true,
      stylesHash ? "",
    }:
    let
      baseUrl = "https://github.com/${repo}/releases/download/${version}";
      mainJs = pkgs.fetchurl {
        url = "${baseUrl}/main.js";
        hash = mainHash;
        name = "${pname}-main.js";
      };
      manifestJson = pkgs.fetchurl {
        url = "${baseUrl}/manifest.json";
        hash = manifestHash;
        name = "${pname}-manifest.json";
      };
      stylesCss = optional hasStyles (
        pkgs.fetchurl {
          url = "${baseUrl}/styles.css";
          hash = stylesHash;
          name = "${pname}-styles.css";
        }
      );
    in
    pkgs.stdenvNoCC.mkDerivation {
      inherit pname version;
      dontUnpack = true;
      dontBuild = true;
      dontFixup = true;
      installPhase = ''
        runHook preInstall
        mkdir -p "$out"
        cp ${mainJs} "$out/main.js"
        cp ${manifestJson} "$out/manifest.json"
        ${optionalString hasStyles ''cp ${builtins.head stylesCss} "$out/styles.css"''}
        runHook postInstall
      '';
    };
  obsidianLocalRestApi = mkObsidianPlugin {
    pname = "obsidian-local-rest-api";
    version = "3.6.1";
    repo = "coddingtonbear/obsidian-local-rest-api";
    mainHash = "sha256-7z5zqg3VsEXz9GnVnPelpq7XCScNhvh9bISgQFZhsr4=";
    manifestHash = "sha256-f8SUGFKSR6M8mF7oidWjWPEuztG9L+PLCNmruB2TiJ0=";
    hasStyles = true;
    stylesHash = "sha256-nBHUcyA4Spr5fKZ+eDhPm/4bRlENYR3j58hQdCXSDfs=";
  };
in
{
  options.my.programs.obsidian = {
    enable = mkEnableOption "Obsidian";
    personalVaultTarget = mkOption {
      type = types.str;
      default = "obsidian/personal";
      description = "Relative target path for the personal Obsidian vault.";
    };
    localRestApi.enableInsecureServer = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable insecure server mode for obsidian-local-rest-api.";
    };
  };

  config = mkIf cfg.enable {
    programs.obsidian = {
      enable = true;
      defaultSettings.communityPlugins = [
        {
          pkg = obsidianLocalRestApi;
          settings = mkForce {
            enableInsecureServer = cfg.localRestApi.enableInsecureServer;
          };
        }
      ];
      vaults.personal.target = cfg.personalVaultTarget;
    };

    home.file."${cfg.personalVaultTarget}/.obsidian/plugins/obsidian-local-rest-api/data.json".force = true;
  };
}
