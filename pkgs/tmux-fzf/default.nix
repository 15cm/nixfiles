{
  lib,
  fetchFromGitHub,
  fzf,
  gnused,
  ncurses,
  tmuxPlugins,
}:

tmuxPlugins.mkTmuxPlugin {
  pluginName = "tmux-fzf";
  rtpFilePath = "main.tmux";
  version = "unstable-2025-09-24";

  src = fetchFromGitHub {
    owner = "sainnhe";
    repo = "tmux-fzf";
    rev = "05af76daa2487575b93a4f604693b00969f19c2f";
    hash = "sha256-ay7z0MkeDCpxdwNTKFrkxi/hUE7a5K7P7oFhfn94aLA=";
  };

  postInstall = ''
    find "$target" -type f -print0 | xargs -0 sed -i -e 's|fzf |${fzf}/bin/fzf |g'
    find "$target" -type f -print0 | xargs -0 sed -i -e 's|sed |${gnused}/bin/sed |g'
    find "$target" -type f -print0 | xargs -0 sed -i -e 's|tput |${ncurses}/bin/tput |g'
  '';

  meta = {
    homepage = "https://github.com/sainnhe/tmux-fzf";
    description = "Use fzf to manage your tmux work environment!";
    longDescription = ''
      Features:
      * Manage sessions (attach, detach*, rename, kill*).
      * Manage windows (switch, link, move, swap, rename, kill*).
      * Manage panes (switch, break, join*, swap, layout, kill*, resize).
      * Multiple selection (support for actions marked by *).
      * Search commands and append to command prompt.
      * Search key bindings and execute.
      * User menu.
      * Popup window support.
    '';
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
