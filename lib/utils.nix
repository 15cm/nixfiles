{ ... }:

rec {
  applyXwaylandEnvsToDesktopExec = config: exec:
    "env GDK_SCALE=${config.my.env.GDK_SCALE} GDK_DPI_SCALE=${config.my.env.GDK_DPI_SCALE} ${exec}";
  applyChromeFlagsToDesktopExec = exec:
    "${exec} --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-wayland-ime";
  applyElectronFlagsToDesktopExec = exec:
    applyChromeFlagsToDesktopExec exec + "--disable-gpu-sandbox";
}
