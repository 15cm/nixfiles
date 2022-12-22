# When the system it not booted via EFI (checked by `[ -d /sys/firmware/efi ]`), use grub.
{
  boot.loader.grub = {
    efiSupport = false;
    device = "/dev/vda";
    configurationLimit = 3;
  };
}
