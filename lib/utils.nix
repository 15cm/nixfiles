{ ... }:

{
  applyXwaylandEnvsToDesktopExec = config: exec:
    "env GDK_SCALE=${config.my.env.GDK_SCALE} GDK_DPI_SCALE=${config.my.env.GDK_DPI_SCALE} GTK_IM_MODULE=fcitx ${exec}";
}
