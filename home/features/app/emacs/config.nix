{ config, ... }:

{
  socket = rec {
    dir = "${config.home.homeDirectory}/local/run/emacs";
    cli = rec {
      name = "cli";
      path = "${dir}/${name}";
    };
    gui = rec {
      name = "server";
      path = "${dir}/${name}";
    };
  };
}
