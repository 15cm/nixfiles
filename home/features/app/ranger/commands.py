# This is a sample commands.py.  You can add your own commands here.
#
# Please refer to commands_full.py for all the default commands and a complete
# documentation.  Do NOT add them all here, or you may end up with defunct
# commands when upgrading ranger.

# A simple command for demonstration purposes follows.
# -----------------------------------------------------------------------------

from __future__ import absolute_import, division, print_function

import distutils.spawn
# You can import any python module as needed.
import os
import os.path
import subprocess
from sys import platform

# You always need to import ranger.api.commands here to get the Command class:
from ranger.api.commands import Command


# Any class that is a subclass of "Command" will be integrated into ranger as a
# command.  Try typing ":my_edit<ENTER>" in ranger!
class my_edit(Command):
    # The so-called doc-string of the class will be visible in the built-in
    # help that is accessible by typing "?c" inside ranger.
    """:my_edit <filename>

    A sample command for demonstration purposes that opens a file in an editor.
    """

    # The execute method is called when you run this command in ranger.
    def execute(self):
        # self.arg(1) is the first (space-separated) argument to the function.
        # This way you can write ":my_edit somefilename<ENTER>".
        if self.arg(1):
            # self.rest(1) contains self.arg(1) and everything that follows
            target_filename = self.rest(1)
        else:
            # self.fm is a ranger.core.filemanager.FileManager object and gives
            # you access to internals of ranger.
            # self.fm.thisfile is a ranger.container.file.File object and is a
            # reference to the currently selected file.
            target_filename = self.fm.thisfile.path

        # This is a generic function to print text in ranger.
        self.fm.notify("Let's edit the file " + target_filename + "!")

        # Using bad=True in fm.notify allows you to print error messages:
        if not os.path.exists(target_filename):
            self.fm.notify("The given file does not exist!", bad=True)
            return

        # This executes a function from ranger.core.acitons, a module with a
        # variety of subroutines that can help you construct commands.
        # Check out the source, or run "pydoc ranger.core.actions" for a list.
        self.fm.edit_file(target_filename)

    # The tab method is called when you press tab, and should return a list of
    # suggestions that the user will tab through.
    # tabnum is 1 for <TAB> and -1 for <S-TAB> by default
    def tab(self, tabnum):
        # This is a generic tab-completion function that iterates through the
        # content of the current directory.
        return self._tab_directory_content()


# helpers
is_osx = platform == "darwin"


def merge_two_dicts(x, y):
    z = x.copy()  # start with x's keys and values
    z.update(y)  # modifies z with y's keys and values & returns None
    return z


def exec_exists(f):
    return True if distutils.spawn.find_executable(f) else False


tree_cmd = "tree -C"
fd_default_cmd = "fd -H --no-ignore-vcs"
fzf_default_opt = "--height 40% -m --reverse --bind 'ctrl-d:page-down,ctrl-u:page-up,ctrl-k:kill-line,pgup:preview-page-up,pgdn:preview-page-down,alt-a:toggle-all' "
fzf_default_cmd = "fzf {0}".format(fzf_default_opt)


def send_to_fzf(self, command):
    fzf = self.fm.execute_command(command, stdout=subprocess.PIPE)
    stdout, stderr = fzf.communicate()
    if fzf.returncode == 0:
        fzf_file = os.path.abspath(stdout.decode("utf-8").rstrip("\n"))
        if os.path.isdir(fzf_file):
            self.fm.cd(fzf_file)
        else:
            self.fm.select_file(fzf_file)


class fzf_select(Command):
    """
    :fzf_select

    Find a file using fzf.

    See: https://github.com/junegunn/fzf
    """

    def execute(self):
        pass

        # match files
        command = (
            "{0} -t f  | ".format(fd_default_cmd)
            + fzf_default_cmd
            + "--preview '([ -f {} ] && (highlight -O ansi -l {} 2> /dev/null || cat {})) | head -200'"
        )
        send_to_fzf(self, command)


class fzf_cd_dir(Command):
    """
    :fzf_cd_dir

    Cd a dir using fzf.
    """

    def execute(self):
        # match directories
        command = (
            "{0} -t d | ".format(fd_default_cmd)
            + fzf_default_cmd
            + "--preview '([ -d {{}} ] && {0} {{}}) | head -200'".format(tree_cmd)
        )
        send_to_fzf(self, command)


class fzf_z(Command):
    """
    :fzf_z

    Cd by z with fzf
    """

    def execute(self):
        global tree_cmd
        command = (
            'source $HOME/.z/z.sh; _z -l 2>&1 | sed "s/^[0-9,.]* *//" | '
            + fzf_default_cmd
            + '--tac --reverse --preview "{0} {{}} | head -200" --preview-window right:30%'.format(
                tree_cmd
            )
        )
        send_to_fzf(self, command)


class fzf_mdfind(Command):
    """
    :fzf_mdfind

    mdfind with fzf
    """

    def execute(self):
        global tree_cmd
        command = 'mdfind "kind:folder" \
        | fzf --tac --reverse --preview "{0} {{}} | head -200"  --preview-window right:30%'.format(
            tree_cmd
        )
        send_to_fzf(self, command)


class delete_files(Command):
    """
    :delete_files

    Delete selected files
    """

    def execute(self):
        if is_osx or exec_exists("trash-put"):
            paths = list(map(lambda f: f.path, self.fm.thistab.get_selection()))
            for p in paths:
                if is_osx:
                    subprocess.check_output(["trash", p])
                else:
                    subprocess.check_output(["trash-put", p])
            self.fm.notify(
                "trashed {0}".format(" ".join(map(lambda p: '"{0}"'.format(p), paths)))
            )
        else:
            self.fm.execute_console("delete")


class open_files(Command):
    """
    :open_files

    Open selected files(use 'open' on macOS, 'xdg-open' on Linux)
    """

    def execute(self):
        files = (
            self.fm.thistab.get_selection()
            if self.args[-1] != "--open-from-move-right"
            else [self.fm.thisfile]
        )
        open_command = "open" if is_osx else "xdg-open"
        for f in files:
            p = f.path
            self.fm.notify("open {0}".format(p))
            subprocess.Popen(
                [open_command, p], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
            )


shell_emacs_cmd = "emacsclient -s $HOME/local/run/emacs/misc -t -a vim"
shell_vim_cmd = "vim"


class open_files_shell_emacs(Command):
    """
    :open_files_shell_emacs

    Open selected files with shell Emacs
    """

    def execute(self):
        global shell_emacs_cmd
        files = (
            self.fm.thistab.get_selection()
            if self.args[-1] != "--open-from-move-right"
            else [self.fm.thisfile]
        )
        for f in files:
            p = f.path
            command = 'shell {0} "{1}"'.format(shell_emacs_cmd, p)
            self.fm.notify("open emacs: {0}".format(p))
            self.fm.execute_console(command)


class open_files_shell_emacs_tmux(Command):
    """
    :open_files_shell_emacs_tmux

    Open selected files in tmux with shell Emacs
    """

    def execute(self):
        global shell_emacs_cmd
        files = (
            self.fm.thistab.get_selection()
            if self.args[-1] != "--open-from-move-right"
            else [self.fm.thisfile]
        )
        for f in files:
            p = f.path
            command = "shell tmux splitw -v '{0} \"{1}\"'".format(shell_emacs_cmd, p)
            self.fm.notify("open {0} with shell emacs tmux".format(p))
            self.fm.execute_console(command)


class open_files_shell_vim(Command):
    """
    :open_files_shell_vim

    Open selected files with shell Vim
    """

    def execute(self):
        global shell_vim_cmd
        files = (
            self.fm.thistab.get_selection()
            if self.args[-1] != "--open-from-move-right"
            else [self.fm.thisfile]
        )
        for f in files:
            p = f.path
            command = 'shell {0} "{1}"'.format(shell_vim_cmd, p)
            self.fm.notify("open vim: {0}".format(p))
            self.fm.execute_console(command)


class open_files_shell_vim_tmux(Command):
    """
    :open_files_shell_vim_tmux

    Open selected files in tmux with shell Vim
    """

    def execute(self):
        global shell_vim_cmd
        files = (
            self.fm.thistab.get_selection()
            if self.args[-1] != "--open-from-move-right"
            else [self.fm.thisfile]
        )
        for f in files:
            p = f.path
            command = "shell tmux splitw -v '{0} \"{1}\"'".format(shell_vim_cmd, p)
            self.fm.notify("open {0} with shell vim tmux".format(p))
            self.fm.execute_console(command)


open_option_keymap_general = {
    "o": "open_files",
    "O": "open_files_file_browser",
    "e": "open_files_shell_emacs_tmux",
    "E": "open_files_shell_emacs",
    "v": "open_files_shell_vim_tmux",
    "V": "open_files_shell_vim",
    "q": "cancel",
}

open_option_keymap_mac = {}

open_option_keymap = merge_two_dicts(
    open_option_keymap_general, open_option_keymap_mac if is_osx else {}
)


class draw_command_open_option_keymap(Command):
    """
    :draw_command_open_option_keymap
    """

    def execute(self):
        global open_option_keymap

        keymap = [
            "{0} | {1}".format(k, v.replace("open_files_", ""))
            for (k, v) in open_option_keymap.items()
        ]
        self.fm.ui.browser.draw_info = keymap


class open_files_with(Command):
    """
    :open_files_with
    """

    def execute(self):
        global open_option_keymap

        def callback(answer):
            cmd = open_option_keymap[answer]
            if answer == "q":
                pass
            elif not cmd.startswith("open_files_"):
                self.fm.execute_console(cmd)
            else:
                self.fm.execute_console(
                    "{0} {1}".format(open_option_keymap[answer], self.rest(1))
                )
            self.fm.ui.browser.draw_info = False

        keys = [k for k in open_option_keymap.keys()]
        self.fm.ui.console.ask(
            "open_files_with: [{0}]".format("".join(keys)), callback, ["q", "q"] + keys
        )


class my_move_right(Command):
    """
    :my_move_right
    """

    def execute(self):
        f = self.fm.thisfile
        if f.is_directory:
            self.fm.move(right=1)
        else:
            self.fm.execute_console(
                "chain draw_command_open_option_keymap; open_files_with --open-from-move-right"
            )


class open_files_file_browser(Command):
    """
    :open_files_file_browser
    Reveal selected files in file browser
    """

    def execute(self):
        files = (
            self.fm.thistab.get_selection()
            if self.arg(2) != "-h"
            else [self.fm.thisfile]
        )
        if len(files) == 0:
            self.fm.notify("No files are selected")
            return
        if is_osx:
            # open in finder
            paths = ",".join(
                ['"{0}" as POSIX file'.format(file.path) for file in files]
            )
            reveal_script = 'tell application "Finder" to reveal {{{0}}}'.format(paths)
            activate_script = 'tell application "Finder" to set frontmost to true'
            script = "osascript -e '{0}' -e '{1}'".format(
                reveal_script, activate_script
            )
            self.fm.notify(script)
            subprocess.Popen(
                ["osascript", "-e", reveal_script, "-e", activate_script],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        else:
            # open in nautilus
            paths = [f.path for f in files]
            subprocess.Popen(
                ["nautilus", "--select"] + paths,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )


class shell_in_tmux(Command):
    """
    :shell_in_tmux

    Open shell in tmux
    """

    def execute(self):
        curdir = self.fm.thisdir.path
        command = "shell tmux splitw -v 'exec $SHELL && cd {0}'".format(curdir)
        self.fm.execute_console(command)
