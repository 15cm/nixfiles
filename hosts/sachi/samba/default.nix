{ config, pkgs, lib, ... }:

with lib; {
  sops.secrets.smbpasswd = {
    sopsFile = ./smbpasswd;
    format = "binary";
  };
  services.samba = {
    enable = true;
    securityType = "user";

    # This adds to the [global] section:
    extraConfig = ''
      client min protocol SMB3_11
      server min protocol = SMB3_11
      server smb encrypt = desired
      server multi channel support = yes
      deadtime = 30
      use sendfile = yes
      read raw = yes
      min receivefile size = 16384
      aio read size = 1
      aio write size = 1
      socket options = IPTOS_LOWDELAY TCP_NODELAY IPTOS_THROUGHPUT SO_RCVBUF=131072 SO_SNDBUF=131072
      browseable = yes
      writeable = yes
    '';
    openFirewall = true;

    # Smb sharing doesn't work well with zfs properties.
    shares = {
      "main-storage" = { path = "/mnt/main/storage"; };
      "main-music" = { path = "/mnt/main/media/music"; };
      "main-picture" = { path = "/mnt/main/media/picture"; };
      "main-photo" = { path = "/mnt/main/media/photo"; };
      "main-book" = { path = "/mnt/main/media/book"; };
      "sub-aria2" = { path = "/mnt/sub/download/aria2"; };
      "sub-aria2-baidu" = { path = "/mnt/sub/download/aria2-baidu"; };
      "sub-bangumi" = { path = "/mnt/sub/download/bangumi"; };
      "sub-torrent-download" = { path = "/mnt/sub/download/torrent/download"; };
      "sub-torrent-upload" = { path = "/mnt/sub/download/torrent/upload"; };
      "sub-tvshow" = { path = "/mnt/sub/media/tvshow"; };
      "sub-movie" = { path = "/mnt/sub/media/movie"; };
    };
  };
  systemd.targets.samba = {
    wantedBy = mkForce [ "zfs-load-key-and-mount.target" ];
    partOf = mkForce [ "zfs-load-key-and-mount.target" ];
    after = mkForce [ "network.target" "zfs-load-key-and-mount.target" ];
  };
  # Initialize smb password following https://serverfault.com/questions/1104310/how-do-i-import-an-smbpasswd-file-into-a-different-samba-server
  # The smbpasswd is generated via:
  # pdbedit -a -u <username>
  # pdbedit -L -w > /tmp/smbpasswd
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
