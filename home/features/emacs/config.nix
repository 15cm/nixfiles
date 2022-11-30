{ config, ... }:

{
  socket = rec {
    dir = "${config.home.homeDirectory}/local/run/emacs";
    cli = rec {
      name = "misc";
      path = "${dir}/${name}";
    };
    gui = rec {
      name = "server";
      path = "${dir}/${name}";
    };
  };
}
