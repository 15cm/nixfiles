{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.my.programs.firefox;
  jsonFormat = pkgs.formats.json { };
in {
  options.my.programs.firefox = {
    enable = mkEnableOption "Firefox";
    package = mkOption {
      type = types.package;
      default = pkgs.firefox;
    };
    searchEngines = mkOption {
      type = with types;
        listOf (submodule {
          options.name = mkOption { type = types.str; };
          options.value =
            mkOption { type = with types; attrsOf jsonFormat.type; };
        });
      default = [ ];
      example = literalExpression ''
        [{
            name = "Github";
            value = {
                      urls = [{
                        template =
                          "https://github.com/search?q={searchTerms}&type=repositories";
                      }];
                      iconUpdateURL =
                        "https://github.githubassets.com/favicons/favicon.svg";
                      updateInterval = 24 * 60 * 60 * 1000; # every day
                      definedAliases = [ "@gh" ];
                    };
         }]
      '';
      description = "Search engines in order.";
    };
    searchEnginesOrderPrepend = mkOption {
      type = with types; listOf str;
      default = [ ];
      example = literalExpression ''
        ["google"]
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.firefox = {
      enable = true;
      package = cfg.package;
      profiles.default = {
        id = 0;
        name = "default";
        userChrome = (builtins.readFile ./userChrome.css);
        search = {
          force = true;
          default = "google";
          privateDefault = "google";
          engines = {
            "bing".metaData.hidden = true;
            "ebay".metaData.hidden = true;
            "ddg".metaData.hidden = true;
            "amazondotcom-us".metaData.hidden = true;
            "google".metaData.alias = "@gg";
            "wikipedia".metaData.alias = "@wiki";
          } // (builtins.listToAttrs cfg.searchEngines);
          order = cfg.searchEnginesOrderPrepend
            ++ (map (kv: kv.name) cfg.searchEngines);
        };
      };
    };
  };
}
