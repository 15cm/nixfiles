{ lib, ... }:

with lib; {
  options.my.trusts = {
    cache.pubKeys = mkOption {
      default = [ ];
      type = with types; listOf str;
    };
    ssh.pubKeys = mkOption {
      default = [ ];
      type = with types; listOf str;
    };
  };

  config.my.trusts = {
    ssh.pubKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIp+lvf7SQBnU+zC/uEwG/uerIdqjDzRtC1LLFsNrvwH sinkerine@id"
    ];

    cache.pubKeys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixcache.mado.moe:IBuIrS2YNmuED0qWC5wq0FGliFX2s7loTgdGRpD81hk="
    ];
  };
}
