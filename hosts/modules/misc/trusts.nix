{ lib, ... }:

with lib;
let
  fcitx5VinputCache = {
    substituter = "https://fcitx5-vinput.cachix.org";
    pubKey = "fcitx5-vinput.cachix.org-1:XpX3AA6+dDIX4qJhb1QM7sbTwX6/qSlGvW8Z5NK6XdU=";
  };
in
{
  options.my.trusts = {
    cache.pubKeys = mkOption {
      default = [ ];
      type = with types; listOf str;
    };
    cache.fcitx5Vinput = {
      substituter = mkOption {
        type = types.str;
        default = fcitx5VinputCache.substituter;
      };
      pubKey = mkOption {
        type = types.str;
        default = fcitx5VinputCache.pubKey;
      };
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
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      "proxmox-nixos:D9RYSWpQQC/msZUWphOY2I5RLH5Dd6yQcaHIuug7dWM="
    ];
  };
}
