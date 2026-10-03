"""Shared readout rendering for waybar custom modules (volume, brightness).

The bar is horizontal now, with width to spare, so each readout is an actual
icon (a Nerd Font Font Awesome glyph — see the codepoints below, requires the
JetBrainsMono Nerd Font this desktop already installs for the SF Pro
fallback chain) followed by its value, the way a macOS status item pairs an
SF Symbol with a number rather than gluing a text symbol and digits together.
"""

# Font Awesome glyphs via the Nerd Font patch. Chosen over CP437 approximations
# (the old "☼"/"♪") because they render as actual icons, not squinted-at text.
SYM_BRIGHT = ""  # nf-fa-sun_o
SYM_VOLUME_HIGH = ""  # nf-fa-volume_up
SYM_VOLUME_LOW = ""  # nf-fa-volume_down
SYM_VOLUME_MUTE = ""  # nf-fa-volume_off


def fmt(percent):
    """Clamp to 0-100, pad to two digits, and suffix with %.

    100 renders as three digits, everything below it as two, so the common
    case stays a fixed width and never reflows the column.
    """
    return f"{max(0, min(100, int(percent))):02d}%"


def readout(symbol, value):
    """A module's single row: icon, a space, then the value."""
    return f"{symbol} {value}"
