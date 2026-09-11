"""Shared readout rendering for waybar custom modules (volume, brightness).

The bar is 52px wide and vertical, which fits about four 14px monospace glyphs
per row. Each readout is therefore a single row: one CP437 symbol identifying
the module, followed by its value.

The symbol is doing real work — it is what lets you tell the modules apart
peripherally, without reading. An earlier revision used three-letter captions
(BAT/BRI/VOL) stacked above the value, which made every module an identical
grey rectangle and cost twice the height.
"""

# CP437 symbols, chosen for distinct silhouettes at 14px rather than for
# literal accuracy — ♪ is not a speaker, but nothing else in the bar looks
# remotely like it, which is the whole point.
SYM_VOLUME = "♪"  # ♪ eighth note
SYM_BRIGHT = "☼"  # ☼ white sun with rays


def fmt(percent):
    """Clamp to 0-100 and pad to two digits.

    100 renders as three glyphs, everything below it as two, so the common case
    stays three glyphs wide including the symbol and never reflows the column.
    """
    return f"{max(0, min(100, int(percent))):02d}"


def readout(symbol, value):
    """A module's single row: symbol then value, no separator."""
    return f"{symbol}{value}"
