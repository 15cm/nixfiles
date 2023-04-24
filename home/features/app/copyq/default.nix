{ pkgs, ... }:

let package = pkgs.copyq;
in {
  home.packages = [ package ];
  # systemd.user.services.copyq = {
  #   Unit = {
  #     Description = "Copyq";
  #     PartOf = [ "graphical-session.target" ];
  #     After = [ "graphical-session.target" ];
  #   };
  #   Install = { WantedBy = [ "graphical-session.target" ]; };
  #   Service = {
  #     Type = "simple";
  #     ExecStart = "${package}/bin/copyq";
  #   };
  # };
}
