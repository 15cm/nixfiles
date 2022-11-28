{ config, ...}:

{
  socket = rec {
    dir = "${config.home.homeDirectory}/local/run/emacs";
    name = "misc";
    path = "${dir}/name";
  };
}
