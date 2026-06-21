{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.services.fcitx5;
in
{
  options.my.services.fcitx5 = {
    enable = mkEnableOption "Fcitx5";

    package = mkOption {
      type = types.package;
      default = pkgs.qt6Packages.fcitx5-with-addons.override {
        addons = with pkgs; [
          fcitx5-rime
          fcitx5-mozc
          fcitx5-vinput
        ];
      };
    };

    enableWaylandEnv = mkEnableOption "https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland";
  };

  config = mkIf cfg.enable {

    home.packages = with pkgs; [
      fcitx5-gtk
      fcitx5-vinput
      kdePackages.fcitx5-qt
    ];

    home.sessionVariables = {
      QT_IM_MODULES = "wayland;fcitx";
      QT_IM_MODULE = "fcitx";
      XMODIFIERS = "@im=fcitx";
      QT_PLUGIN_PATH = "${cfg.package}/${pkgs.qt6.qtbase.qtPluginPrefix}:\${QT_PLUGIN_PATH}";
    };

    gtk = {
      gtk2.extraConfig = ''gtk-im-module="fcitx"'';
      gtk3.extraConfig = {
        gtk-im-module = "fcitx";
      };
      gtk4.extraConfig = {
        gtk-im-module = "fcitx";
      };
    };

    home.file.".local/share/fcitx5/themes/Material-Color-Pink/theme.conf".source = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/hosxy/Fcitx5-Material-Color/2256feeae48dcc87f19a3cfe98f171862f8fcace/theme-pink.conf";
      hash = "sha256-VbYvwAb3pxyReFzl7j3eqqUsMuSY32+XlEhBNb12ZRc=";
    };
    home.file.".local/share/vinput/providers/openai-compatible/streaming" = {
      source = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/xifan2333/vinput-registry/main/resources/providers/openai-compatible/streaming/entry.py";
        hash = "sha256-RQPa3xvz/G/+Jsi1/VJ6fE2Of8e5p0n2IOH3wSJbK3g=";
      };
      executable = true;
    };

    sops.secrets.vinputOpenAIAPIKey = { };
    sops.templates."vinput-config.json" = {
      path = "${config.xdg.configHome}/vinput/config.json";
      content = ''
        {
          "version": 1,
          "registry": {
            "base_urls": [
              "https://raw.githubusercontent.com/xifan2333/vinput-registry/main",
              "https://gh-proxy.com/https://raw.githubusercontent.com/xifan2333/vinput-registry/main",
              "https://ghfast.top/https://raw.githubusercontent.com/xifan2333/vinput-registry/main"
            ]
          },
          "global": {
            "default_language": "zh",
            "capture_device": ""
          },
          "asr": {
            "active_provider": "provider.openai-compatible.streaming",
            "normalize_audio": true,
            "input_gain": 1.0,
            "vad": {
              "enabled": true
            },
            "providers": [
              {
                "id": "sherpa-onnx",
                "type": "local",
                "model": "model.sherpa-onnx.qwen3-asr-0.6b-int8",
                "timeout_ms": 15000
              },
              {
                "id": "provider.openai-compatible.streaming",
                "type": "command",
                "command": "python3",
                "args": [
                  "${config.home.homeDirectory}/.local/share/vinput/providers/openai-compatible/streaming"
                ],
                "env": {
                  "VINPUT_ASR_API_KEY": "${config.sops.placeholder.vinputOpenAIAPIKey}",
                  "VINPUT_ASR_FINISH_GRACE_SECS": "2",
                  "VINPUT_ASR_MODEL": "gpt-realtime-whisper",
                  "VINPUT_ASR_SESSION_MODEL": "gpt-realtime"
                },
                "timeout_ms": 60000
              }
            ]
          },
          "llm": {
            "providers": [
              {
                "id": "OpenAI",
                "base_url": "https://api.openai.com/v1",
                "api_key": "${config.sops.placeholder.vinputOpenAIAPIKey}"
              }
            ],
            "adapters": []
          },
          "scenes": {
            "active_scene": "__command__",
            "definitions": [
              {
                "id": "__raw__",
                "candidate_count": 0
              },
              {
                "id": "__command__",
                "prompt": "# Command Mode Prompt\n\n## Role\n\nYou are an assistant that applies a spoken command to the user-provided text.\n\n## Context\n\n- The user message is the source text to operate on.\n- The spoken command may contain ASR errors.\n- The spoken command is appended at runtime in the `## Task` section.\n\n## Task\n",
                "provider_id": "OpenAI",
                "model": "gpt-5.4-mini"
              }
            ]
          }
        }
      '';
    };

    systemd.user.services.fcitx5-daemon = {
      Unit = {
        Description = "Fcitx5 input method editor";
        PartOf = mkForce [ "tray.target" ];
        After = mkForce [ "tray.target" ];
      };
      Service.ExecStart = "${cfg.package}/bin/fcitx5";
      Install.WantedBy = mkForce [ "tray.target" ];
    };

    systemd.user.services.vinput-daemon = {
      Unit = {
        Description = "Vinput voice input daemon";
        After = [ "pipewire.service" ];
      };
      Service = {
        Type = "dbus";
        BusName = "org.fcitx.Vinput";
        ExecStart = "${pkgs.fcitx5-vinput}/bin/vinput-daemon";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
