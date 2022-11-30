{withArgs, ...}:

let inherit (withArgs) kbdName;
{
  xdg.configFile."kmonad/laptop.kbd".source = ./laptop.kdb;
}
