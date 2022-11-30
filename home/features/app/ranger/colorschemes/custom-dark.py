from ranger.colorschemes.default import Default

from ranger.gui.color import (
    black, blue, cyan, green, magenta, red, white, yellow, default,
    normal, bold, reverse,
    default_colors,
)

class Scheme(Default):

    def use(self, context):
        fg, bg, attr = Default.use(self, context)

        if context.in_titlebar:
            if context.tab:
                if not context.good:
                    fg = cyan

        return fg, bg, attr
