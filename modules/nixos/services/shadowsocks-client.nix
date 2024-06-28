{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.my.shadowsocks-client;

  opts = {
    server = cfg.serverAddress;
    server_port = cfg.port;
    local_port = cfg.localPort;
    method = cfg.encryptionMethod;
    user = "nobody";
  } // optionalAttrs (cfg.plugin != null) {
    plugin = cfg.plugin;
    plugin_opts = cfg.pluginOpts;
  } // optionalAttrs (cfg.password != null) { password = cfg.password; }
    // cfg.extraConfig;

  configFile = pkgs.writeText "shadowsocks.json" (builtins.toJSON opts);

in {
  options.services.my.shadowsocks-client = {

    enable = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc ''
        Whether to run shadowsocks-libev shadowsocks server.
      '';
    };

    serverAddress = mkOption {
      type = with types; nullOr str;
      default = null;
      description = lib.mdDoc ''
        your hostname or server IP (IPv4/IPv6).
      '';
    };

    port = mkOption {
      type = types.port;
      default = 8388;
      description = lib.mdDoc ''
        Port which the server uses.
      '';
    };

    localPort = mkOption {
      type = types.port;
      default = 1080;
      description = lib.mdDoc ''
        Local port.
      '';
    };

    password = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = lib.mdDoc ''
        Password for connecting clients.
      '';
    };

    passwordFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = lib.mdDoc ''
        Password file with a password for connecting clients.
      '';
    };

    encryptionMethod = mkOption {
      type = types.str;
      default = "chacha20-ietf-poly1305";
      description = lib.mdDoc ''
        Encryption method. See <https://github.com/shadowsocks/shadowsocks-org/wiki/AEAD-Ciphers>.
      '';
    };

    plugin = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = literalExpression
        ''"''${pkgs.shadowsocks-v2ray-plugin}/bin/v2ray-plugin"'';
      description = lib.mdDoc ''
        SIP003 plugin for shadowsocks
      '';
    };

    pluginOpts = mkOption {
      type = types.str;
      default = "";
      example = "server;host=example.com";
      description = lib.mdDoc ''
        Options to pass to the plugin if one was specified
      '';
    };

    extraConfig = mkOption {
      type = types.attrs;
      default = { };
      example = { nameserver = "8.8.8.8"; };
      description = lib.mdDoc ''
        Additional configuration for shadowsocks that is not covered by the
        provided options. The provided attrset will be serialized to JSON and
        has to contain valid shadowsocks options. Unfortunately most
        additional options are undocumented but it's easy to find out what is
        available by looking into the source code of
        <https://github.com/shadowsocks/shadowsocks-libev/blob/master/src/jconf.c>
      '';
    };

  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.serverAddress != null;
        message = "Missing required option server address";
      }
      {
        assertion = cfg.password == null || cfg.passwordFile == null;
        message =
          "Cannot use both password and passwordFile for shadowsocks-libev";
      }
    ];

    systemd.services.shadowsocks-libev-client = {
      description = "shadowsocks-libev Client Daemon";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      restartIfChanged = false;
      path = [ pkgs.shadowsocks-libev ]
        ++ optional (cfg.plugin != null) cfg.plugin
        ++ optional (cfg.passwordFile != null) pkgs.jq;
      serviceConfig.PrivateTmp = true;
      script = ''
        ${optionalString (cfg.passwordFile != null) ''
          cat ${configFile} | jq --arg password "$(cat "${cfg.passwordFile}")" '. + { password: $password }' > /tmp/shadowsocks.json
        ''}
        exec ss-local -c ${
          if cfg.passwordFile != null then
            "/tmp/shadowsocks.json"
          else
            configFile
        }
      '';
    };
  };
}
