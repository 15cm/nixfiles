args@{ withArgs, ... }:

{
  imports = [
    (import ../features/emacs (args // { inherit withArgs; }))
    ../features/tmux
  ];
}
