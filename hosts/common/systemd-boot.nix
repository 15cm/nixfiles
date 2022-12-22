{
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 3;
  };
  boot.loader.efi.canTouchEfiVariables = true;
}
