{
  ssh = {
    keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIp+lvf7SQBnU+zC/uEwG/uerIdqjDzRtC1LLFsNrvwH sinkerine@kazuki"
    ];
  };
  zrepl = { caCertPath = ./zrepl-ca.crt; };
}
