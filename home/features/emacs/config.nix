homeDirectory:

{
  socket = rec {
    dir = "${homeDirectory}/local/run/emacs";
    name = "misc";
    path = "${dir}/name";
  };
}
