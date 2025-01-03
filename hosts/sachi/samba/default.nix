{ config, pkgs, lib, ... }:

with lib; {
  sops.secrets.smbpasswd = {
    sopsFile = ./smbpasswd;
    format = "binary";
  };
  services.samba = {
    enable = true;

    # This adds to the [global] section:
    settings = {
      global = {
        "security" = "user";
        "client min protocol" = "SMB3_11";
        "server min protocol" = "SMB3_11";
        "server smb encrypt" = "desired";
        "server multi channel support" = "yes";
        "deadtime" = 30;
        "use sendfile" = "yes";
        "read raw" = "yes";
        "min receivefile size" = 16384;
        "aio read size" = 1;
        "aio write size" = 1;
        "socket options" =
          "IPTOS_LOWDELAY TCP_NODELAY IPTOS_THROUGHPUT SO_RCVBUF=131072 SO_SNDBUF=131072";
        "browseable" = "yes";
        "writeable" = "yes";
      };
    };
    openFirewall = true;

    # Smb sharing doesn't work well with zfs properties.
    settings = {
      "main-storage" = { path = "/pool/main/storage"; };
      "main-music" = { path = "/pool/main/media/music"; };
      "main-picture" = { path = "/pool/main/media/picture"; };
      "main-photo" = { path = "/pool/main/media/photo"; };
      "main-book" = { path = "/pool/main/media/book"; };
      "main-sync" = { path = "/pool/main/sync"; };
      "sub-aria2" = { path = "/pool/sub/download/aria2"; };
      "sub-aria2-baidu" = { path = "/pool/sub/download/aria2-baidu"; };
      "sub-arr" = { path = "/pool/sub/arr"; };
      "sub-torrent-download" = {
        path = "/pool/sub/download/torrent/download";
      };
      "sub-download" = { path = "/pool/sub/download"; };
      "sub-tvshow" = { path = "/pool/sub/media/tvshow"; };
      "sub-movie" = { path = "/pool/sub/media/movie"; };
    };
  };
  # Initialize smb password following https://serverfault.com/questions/1104310/how-do-i-import-an-smbpasswd-file-into-a-different-samba-server
  # The smbpasswd is generated via:
  # sudo pdbedit -a -u <username>
  # sudo pdbedit -L -w > /tmp/smbpasswd
  system.activationScripts = mkIf config.services.samba.enable {
    sambaUserSetup = {
      text = ''
        ${pkgs.samba}/bin/pdbedit \
          -i smbpasswd:/run/secrets/smbpasswd
      '';
      deps = [ "setupSecrets" ];
    };
  };
}
