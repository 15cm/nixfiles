{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.services.vinput;
in
{
  options.my.services.vinput = {
    enable = mkEnableOption "Vinput voice input";

    enableStreaming = mkEnableOption "streaming ASR through the OpenAI Realtime API";
  };

  config = mkIf cfg.enable (
    let
      asrProvider = if cfg.enableStreaming then "streaming" else "batch";
      asrProviderId =
        if cfg.enableStreaming then
          "provider.openai-compatible.streaming"
        else
          "provider.openai-compatible";
      asrProviderUrl =
        if cfg.enableStreaming then
          "https://raw.githubusercontent.com/xifan2333/vinput-registry/main/resources/providers/openai-compatible/streaming/entry.py"
        else
          "https://raw.githubusercontent.com/xifan2333/vinput-registry/main/resources/providers/openai-compatible/batch/entry.py";
      asrProviderHash =
        if cfg.enableStreaming then
          "sha256-RQPa3xvz/G/+Jsi1/VJ6fE2Of8e5p0n2IOH3wSJbK3g="
        else
          "sha256-Dvf9IlGTsq5gChHBw+tTRzkA/IXIdw2K6pS4v56MC4A=";
      asrEnv = {
        VINPUT_ASR_API_KEY = config.sops.placeholder.vinputOpenAIAPIKey;
        VINPUT_ASR_MODEL = if cfg.enableStreaming then "gpt-realtime-whisper" else "gpt-4o-transcribe";
        VINPUT_ASR_URL =
          if cfg.enableStreaming then
            "wss://api.openai.com/v1/realtime"
          else
            "https://api.openai.com/v1/audio/transcriptions";
      }
      // optionalAttrs cfg.enableStreaming {
        VINPUT_ASR_FINISH_GRACE_SECS = "2";
      };
    in
    {
      my.services.fcitx5.addons = [ pkgs.fcitx5-vinput ];

      home.packages = [ pkgs.fcitx5-vinput ];

      home.file.".local/share/vinput/providers/openai-compatible/${asrProvider}" = {
        source = pkgs.fetchurl {
          url = asrProviderUrl;
          hash = asrProviderHash;
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
              "active_provider": "${asrProviderId}",
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
                  "id": "${asrProviderId}",
                  "type": "command",
                  "command": "python3",
                  "args": [
                    "${config.home.homeDirectory}/.local/share/vinput/providers/openai-compatible/${asrProvider}"
                  ],
                  "env": ${builtins.toJSON asrEnv},
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
    }
  );
}
