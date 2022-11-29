sleep 5

# Sync with ~/.xprofile
systemd_envs=(
  DISPLAY
  XAUTHORITY
  QT_QPA_PLATFORMTHEME
  GTK2_RC_FILES
  XCURSOR_PATH
  QT_SCREEN_SCALE_FACTORS
  QT_AUTO_SCREEN_SCALE_FACTOR
  GDK_SCALE
  GDK_DPI_SCALE
  WINIT_HIDPI_FACTOR
  INPUT_METHOD
  GTK_IM_MODULE
  QT_IM_MODULE
  XMODIFIERS
  XDG_RUNTIME_DIR
  DBUS_SESSION_BUS_ADDRESS
)

systemctl --user import-environment ${systemd_envs[@]}

# Starting things with i3
systemctl --user start i3-session.target
systemctl --user start xsession.target
