{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.my.programs.claude-code;
  guiEnabled = config.my.essentials.gui.enable;
  caveman = pkgs.caveman;
  ccstatusline = pkgs.ccstatusline;
  claude-notify = pkgs.claude-notify;
  rtkRewrite = pkgs.writeShellScript "rtk-rewrite.sh" ''
    #!${pkgs.bash}/bin/bash
    # rtk-hook-version: 3
    # RTK Claude Code hook — rewrites commands to use rtk for token savings.
    # Requires: rtk >= 0.23.0, jq
    #
    # This is a thin delegating hook: all rewrite logic lives in `rtk rewrite`,
    # which is the single source of truth.

    if ! command -v jq >/dev/null 2>&1; then
      echo "[rtk] WARNING: jq is not installed. Hook cannot rewrite commands. Install jq: https://jqlang.github.io/jq/download/" >&2
      exit 0
    fi

    if ! command -v rtk >/dev/null 2>&1; then
      echo "[rtk] WARNING: rtk is not installed or not in PATH. Hook cannot rewrite commands. Install: https://github.com/rtk-ai/rtk#installation" >&2
      exit 0
    fi

    CACHE_DIR=''${XDG_CACHE_HOME:-$HOME/.cache}
    CACHE_FILE="$CACHE_DIR/rtk-hook-version-ok"
    if [ ! -f "$CACHE_FILE" ]; then
      RTK_VERSION_RAW=$(rtk --version 2>/dev/null)
      RTK_VERSION=''${RTK_VERSION_RAW#rtk }
      RTK_VERSION=''${RTK_VERSION%% *}
      if [ -n "$RTK_VERSION" ]; then
        IFS=. read -r MAJOR MINOR PATCH <<<"$RTK_VERSION"
        if [ "$MAJOR" -eq 0 ] && [ "$MINOR" -lt 23 ]; then
          echo "[rtk] WARNING: rtk $RTK_VERSION is too old (need >= 0.23.0). Upgrade: cargo install rtk" >&2
          exit 0
        fi
      fi
      mkdir -p "$CACHE_DIR" 2>/dev/null
      touch "$CACHE_FILE" 2>/dev/null
    fi

    INPUT=$(cat)
    CMD=$(jq -r '.tool_input.command // empty' <<<"$INPUT")

    if [ -z "$CMD" ]; then
      exit 0
    fi

    REWRITTEN=$(rtk rewrite "$CMD" 2>/dev/null)
    EXIT_CODE=$?

    case $EXIT_CODE in
      0)
        [ "$CMD" = "$REWRITTEN" ] && exit 0
        ;;
      1)
        exit 0
        ;;
      2)
        exit 0
        ;;
      3)
        ;;
      *)
        exit 0
        ;;
    esac

    if [ "$EXIT_CODE" -eq 3 ]; then
      jq -c --arg cmd "$REWRITTEN" \
        '.tool_input.command = $cmd | {
          "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "updatedInput": .tool_input
          }
        }' <<<"$INPUT"
    else
      jq -c --arg cmd "$REWRITTEN" \
        '.tool_input.command = $cmd | {
          "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
            "permissionDecisionReason": "RTK auto-rewrite",
            "updatedInput": .tool_input
          }
        }' <<<"$INPUT"
    fi
  '';
  claudeHooks = pkgs.runCommandLocal "claude-hooks" {} ''
    mkdir -p "$out"
    cp -r ${caveman}/hooks/. "$out/"
    cp ${rtkRewrite} "$out/rtk-rewrite.sh"
    chmod +x "$out/rtk-rewrite.sh"
  '';
  rtkClaudeHookCommand = "${config.home.homeDirectory}/.claude/hooks/rtk-rewrite.sh";
in
{
  options.my.programs.claude-code = {
    enable = mkEnableOption "Claude Code";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.jq ];

    home.file.".claude/hooks" = {
      source = claudeHooks;
    };

    home.file.".claude/commands" = {
      source = "${caveman}/commands";
    };

    programs.claude-code.skills = {
      caveman = "${caveman}/skills/caveman";
      caveman-commit = "${caveman}/skills/caveman-commit";
      caveman-help = "${caveman}/skills/caveman-help";
      caveman-review = "${caveman}/skills/caveman-review";
      caveman-compress = "${caveman}/caveman-compress";
    };

    programs.claude-code = {
      enable = true;
      settings = {
        permissions.defaultMode = "bypassPermissions";
        includeCoAuthoredBy = false;
        skipDangerousModePermissionPrompt = true;
        hooks = {
          PreToolUse = [
            {
              matcher = "Bash";
              hooks = [
                {
                  type = "command";
                  command = rtkClaudeHookCommand;
                }
              ];
            }
          ];
          SessionStart = [
            {
              hooks = [
                {
                  type = "command";
                  command = "if [ -f ~/.claude/hooks/caveman-activate.js ]; then node ~/.claude/hooks/caveman-activate.js; fi";
                  timeout = 5;
                  statusMessage = "Loading caveman mode...";
                }
              ];
            }
          ];
          UserPromptSubmit = [
            {
              hooks = [
                {
                  type = "command";
                  command = "if [ -f ~/.claude/hooks/caveman-mode-tracker.js ]; then node ~/.claude/hooks/caveman-mode-tracker.js; fi";
                  timeout = 5;
                  statusMessage = "Tracking caveman mode...";
                }
              ];
            }
          ];
        }
        // optionalAttrs guiEnabled {
          Stop = [
            {
              hooks = [
                {
                  type = "command";
                  command = "${lib.getExe claude-notify}";
                  async = true;
                }
              ];
            }
          ];
        };
        statusLine = {
          type = "command";
          command = "${lib.getExe ccstatusline}";
        };
      };
    };

    programs.zsh.shellAliases = {
      cc = "claude";
    };
  };
}
