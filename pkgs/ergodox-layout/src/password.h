#ifndef PASSWORD_MY_H
#define PASSWORD_MY_H

#include QMK_KEYBOARD_H

enum MY_CUSTOM_KEYCODES {
  _KC_PWD = SAFE_RANGE
};

#ifndef MISC_MY_H
#define MISC_MY_H

bool process_record_user(uint16_t keycode, keyrecord_t *record) {
    switch (keycode) {
        // dynamically generate these.
    case _KC_PWD:
        if (record->event.pressed) {
            SEND_STRING(MY_PWD);
        }
        break;
    }
    return true;
}
#endif

#endif
