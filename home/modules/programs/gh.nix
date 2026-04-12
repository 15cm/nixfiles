{ config, lib, ... }:

with lib;
let
  cfg = config.my.programs.gh;
  hasGithubTokenSecret = hasAttrByPath [ "sops" "secrets" "githubToken" ] config;
in {
  options.my.programs.gh = {
    enable = mkEnableOption "GitHub CLI";
  };

  config = mkIf cfg.enable {
    programs.gh = {
      enable = true;
      settings = {
        git_protocol = "ssh";
      };
    };

    home.activation.configureGhCredentials = mkIf hasGithubTokenSecret (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        token="$(< ${config.sops.secrets.githubToken.path})"
        install -d -m 700 "$HOME/.config/gh"
        umask 077
        printf '%s\n' \
          'github.com:' \
          '  git_protocol: ssh' \
          "  oauth_token: $token" \
          > "$HOME/.config/gh/hosts.yml"
      ''
    );
  };
}
