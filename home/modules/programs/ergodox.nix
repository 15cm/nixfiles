{
  pkgs,
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.my.programs.ergodox;
  hasPwdSecret = hasAttrByPath [ "sops" "secrets" "myPwd" ] config;
in
{
  options.my.programs.ergodox = {
    enable = mkEnableOption "ErgoDox EZ QMK layout";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.qmk
      pkgs.dos2unix
    ];

    home.file = {
      ".config/qmk/keyboards/ergodox_ez/keymaps/home/keymap.c".source = "${pkgs.ergodox-layout}/keymap.c";
      ".config/qmk/keyboards/ergodox_ez/keymaps/home/keymap.json".source =
        "${pkgs.ergodox-layout}/keymap.json";
      ".config/qmk/keyboards/ergodox_ez/keymaps/home/config.h".source = "${pkgs.ergodox-layout}/config.h";
      ".config/qmk/keyboards/ergodox_ez/keymaps/home/rules.mk".source = "${pkgs.ergodox-layout}/rules.mk";
      ".config/qmk/keyboards/ergodox_ez/keymaps/home/password.h".source =
        "${pkgs.ergodox-layout}/password.h";
    };

    home.file."local/bin/flash-ergodox.sh".source =
      let
        pwdSecretPath = optionalString hasPwdSecret config.sops.secrets.myPwd.path;
      in
      pkgs.writeShellScript "flash-ergodox.sh" ''
        set -e
        echo "==> Switching nix home..."
        switch-nix-home.sh
        if [ ! -d "$HOME/qmk_firmware" ]; then
          echo "==> Setting up QMK firmware..."
          qmk setup --yes
        fi
        echo "==> Copying keymap into qmk_firmware..."
        kmdir="$HOME/qmk_firmware/keyboards/ergodox_ez/keymaps/home"
        mkdir -p "$kmdir"
        chmod -R u+w "$kmdir" 2>/dev/null || true
        cp "$HOME/.config/qmk/keyboards/ergodox_ez/keymaps/home/"* "$kmdir/"
        ${optionalString hasPwdSecret ''
          MY_PWD="$(cat ${pwdSecretPath})"
          {
            printf '#ifndef PASSWORD_MY_H\n'
            printf '#define PASSWORD_MY_H\n'
            printf '#include QMK_KEYBOARD_H\n'
            printf 'enum MY_CUSTOM_KEYCODES { _KC_PWD = SAFE_RANGE };\n'
            printf '#ifndef MISC_MY_H\n'
            printf '#define MISC_MY_H\n'
            printf 'bool process_record_user(uint16_t keycode, keyrecord_t *record) {\n'
            printf '    switch (keycode) {\n'
            printf '    case _KC_PWD:\n'
            printf '        if (record->event.pressed) { SEND_STRING("%s"); }\n' "$MY_PWD\n"
            printf '        break;\n'
            printf '    }\n'
            printf '    return true;\n'
            printf '}\n'
            printf '#endif\n'
            printf '#endif\n'
          } > "$kmdir/password.h"
        ''}
        echo "==> Compiling and flashing ErgoDox EZ (press reset when prompted)..."
        qmk flash -kb ergodox_ez -km home
        rm -f "$HOME/qmk_firmware/ergodox_ez_base_home.hex"
      '';
  };
}
