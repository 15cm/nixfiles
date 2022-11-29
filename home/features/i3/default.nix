{ specialArgs, withArgs, pkgs, config. ... }:

let
  initScript = pkgs.writeShellScript "i3-init.sh" (builtins.readFile ./init.sh);
colorScheme = specialArgs.colorScheme;
in {
  programs.i3 = {
    enable = true;
    extraConfigTop = (builtins.readFile ./config) + "\n" + withArgs.extraConfigTop;
    barConfigInsideBracket = ''
        id bar-1
        font pango:DejaVu Sans Mono, FontAwesome 10
    	i3bar_command i3bar --transparency
    	position top

    ## please set your primary output first. Example: 'xrandr --output eDP1 --primary'
    	tray_output primary

    	bindsym button4 nop
    	bindsym button5 nop
    #   font xft:URWGothic-Book 11
    	strip_workspace_numbers yes

        colors {
''+ (if colorScheme == "light" then ''
            background #f5f5f5
    # Text color to be used for the statusline.
            statusline #454947
            separator #55ffff

    #                        border  backgr. text
            focused_workspace #454947 #212121 #00ff00
            active_workspace #454947 #212121 #e5f6ff
            inactive_workspace #454947 #212121 #ffffff99
            binding_mode #454947 #fff7e6 #00aaff
            urgent_workspace #454947 #fb4934 #ffffff99
  '' else ''
            background #222d31
    # Text color to be used for the statusline.
            statusline #f9faf9
            separator #454947

    #                      border  backgr. text
            focused_workspace #4c7899 #93c789 #ffffff
            active_workspace #333333 #285577 #ffffff
            inactive_workspace #595B5B #222d31 #eee8d5
            binding_mode #16a085 #2c2c2c #f9faf9
            urgent_workspace #16a085 #fdf6e3 #e5201d
  '') + "}" + withArgs.
  }
  xdg.configFile."i3/config".text = (builtins.readFile ./config) + "\n" + ''
    bar {
        id bar-1
        font pango:DejaVu Sans Mono, FontAwesome 10
    	i3bar_command i3bar --transparency
    	status_command i3status-rs ~/.config/i3/status.toml
    	position top

    ## please set your primary output first. Example: 'xrandr --output eDP1 --primary'
    	tray_output primary

    	bindsym button4 nop
    	bindsym button5 nop
    #   font xft:URWGothic-Book 11
    	strip_workspace_numbers yes

        colors {
  '' + (if colorScheme == "light" then ''
            background #f5f5f5
    # Text color to be used for the statusline.
            statusline #454947
            separator #55ffff

    #                        border  backgr. text
            focused_workspace #454947 #212121 #00ff00
            active_workspace #454947 #212121 #e5f6ff
            inactive_workspace #454947 #212121 #ffffff99
            binding_mode #454947 #fff7e6 #00aaff
            urgent_workspace #454947 #fb4934 #ffffff99
  '' else ''
            background #222d31
    # Text color to be used for the statusline.
            statusline #f9faf9
            separator #454947

    #                      border  backgr. text
            focused_workspace #4c7899 #93c789 #ffffff
            active_workspace #333333 #285577 #ffffff
            inactive_workspace #595B5B #222d31 #eee8d5
            binding_mode #16a085 #2c2c2c #f9faf9
            urgent_workspace #16a085 #fdf6e3 #e5201d
  '') + "}" + withArgs.extraConfig + ''
    exec --no-startup-id ${initScript} &
  '';
}
