# qutebrowser config
# Small tab bar (acts as the title bar under a tiling WM) + the desktop
# palette, matching kitty/nvim.

config.load_autoconfig()

# WORKAROUND for https://github.com/qutebrowser/qutebrowser/issues/8914 —
# segfault in extensions::ExtensionHost on Google domains (Gmail/Meet/Gemini).
# qutebrowser only auto-disables this for QtWebEngine == 6.11.0 exactly;
# force it on regardless of patch version since we're on 6.11.1.
c.qt.workarounds.disable_hangouts_extension = True

# Some sites gate on the UA string and reject QtWebEngine's own (which already
# says "Chrome" but not a version they recognize) — report as a normal current
# Chrome/Linux build instead.
c.content.headers.user_agent = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36"

# WebRTC's auto-gain keeps turning the OS mic level down mid-call (Teams/Meet
# sound quiet). Stop Chromium from touching the input volume.
c.qt.args = ["disable-features=WebRtcAllowInputVolumeAdjustment"]

# ── Keybindings ───────────────────────────────────────────────────────────────
# Default binds bare 'd' to tab-close, which is a one-key-fumble away from
# losing a tab. Require the vim-style double-tap 'dd' instead; a lone 'd' now
# just waits for a second key (config.unbind so 'd' isn't left dangling on
# tab-close underneath the chain).
config.unbind("d")
config.bind("dd", "tab-close")

# Insert-mode Ctrl-e (default bind) opens the focused text field in nvim, in
# its own kitty window; the text goes back into the field on :wq.
c.editor.command = ["kitty", "nvim", "{file}", "+call cursor({line}, {column})"]

# ── Palette ───────────────────────────────────────────────────────────────────
# Follows the Caelestia shell's active palette (shared/theme/theme.nix, light or
# dark), read from the scheme.json the shell rewrites on every theme change —
# same source as nvim (shared/nvim/colors/caelestia.lua). caelestia-theme-sync
# (modules/home/niri.nix) re-sources this file on change. Falls back to Catppuccin
# Latte where the file doesn't exist yet.
import json, os
try:
    with open(os.path.expanduser("~/.local/state/caelestia/scheme.json")) as f:
        _s = json.load(f)
    _c = {k: "#" + v for k, v in _s["colours"].items()}
    mode      = _s.get("mode", "dark")
    bg        = _c["background"]
    bg_dark   = _c["surfaceContainer"]
    bg_hl     = _c["surfaceContainerHighest"]
    sel       = _c["primaryContainer"]
    tab_sel   = _c["secondaryContainer"]  # distinct from primary (icon half)
    tab_sel_fg = _c["onSecondaryContainer"]
    fg        = _c["onSurface"]
    fg_dark   = _c["onSurfaceVariant"]
    comment   = _c["outline"]
    border    = _c["outlineVariant"]
    blue      = _c["primary"]
    cyan      = _c["term6"]
    green     = _c["term2"]
    orange    = _c["tertiary"]
    red       = _c["error"]
    magenta   = _c["term5"]
    yellow    = _c["term3"]
    hint_bg   = _c["tertiaryContainer"]
    hint_fg   = _c["onTertiaryContainer"]
except (OSError, KeyError, ValueError):
    # Catppuccin Latte, matching theme.nix's scheme.
    mode      = "light"
    bg        = "#eff1f5"  # base
    bg_dark   = "#e6e9ef"  # mantle
    bg_hl     = "#ccd0da"  # surface0
    sel       = "#bcc0cc"  # surface1
    fg        = "#4c4f69"  # text
    fg_dark   = "#5c5f77"  # subtext1
    comment   = "#8c8fa1"  # overlay1
    border    = "#acb0be"  # surface2
    blue      = "#1e66f5"  # blue
    cyan      = "#04a5e5"  # sky
    green     = "#40a02b"  # green
    orange    = "#fe640b"  # peach
    red       = "#d20f39"  # red
    magenta   = "#8839ef"  # mauve
    yellow    = "#df8e1d"  # yellow
    tab_sel   = "#7287fd"  # lavender
    tab_sel_fg = bg
    hint_bg   = yellow
    hint_fg   = bg

# ── Fonts ─────────────────────────────────────────────────────────────────────
# UI text in SF Pro (installed via `make sf-fonts`), anything typed or matched
# in the mono font kitty uses.
mono = "JetBrainsMono NFM"
c.fonts.default_family = mono
c.fonts.default_size = "10pt"
c.fonts.tabs.selected = "bold 9pt SF Pro Text"
c.fonts.tabs.unselected = "9pt SF Pro Text"
c.fonts.hints = f"bold 10pt {mono}"
c.fonts.prompts = "10pt SF Pro Text"

# ── Small tab bar (title bar replacement) ────────────────────────────────────
c.tabs.position = "top"
c.tabs.show = "multiple"
# Capsule tabs (drawn by the TabBarStyle patch below): 3px margin around each
# capsule + 8px inside it.
c.tabs.padding = {"top": 7, "bottom": 7, "left": 11, "right": 14}
c.tabs.indicator.width = 0  # load progress already shows in the statusbar
c.tabs.title.format = "{audio}{current_title}"
c.tabs.title.format_pinned = "{audio}"
c.tabs.pinned.shrink = True
c.tabs.favicons.scale = 0.9
c.tabs.max_width = 240

# Statusbar: only show it when it's actually saying something (command mode,
# insert mode, messages, download progress) instead of sitting there always.
c.statusbar.padding = {"top": 5, "bottom": 5, "left": 10, "right": 10}
c.statusbar.show = "in-mode"

# Rounded, roomier popups
c.completion.height = "40%"
c.completion.shrink = True
c.completion.scrollbar.width = 6
c.completion.scrollbar.padding = 0
c.hints.radius = 4
c.hints.padding = {"top": 1, "bottom": 1, "left": 4, "right": 4}
c.hints.border = f"1px solid {bg_dark}"
c.prompt.radius = 8
c.keyhint.radius = 8

# OS-level window title (used by taskbar/alt-tab, not drawn on screen here)
c.window.title_format = "{perc}{current_title}"

# ── Colors ───────────────────────────────────────────────────────────────────
c.colors.completion.fg = fg
c.colors.completion.odd.bg = bg
c.colors.completion.even.bg = bg_dark
c.colors.completion.category.fg = blue
c.colors.completion.category.bg = bg_dark
c.colors.completion.category.border.top = border
c.colors.completion.category.border.bottom = border
c.colors.completion.item.selected.fg = fg
c.colors.completion.item.selected.bg = sel
c.colors.completion.item.selected.border.top = sel
c.colors.completion.item.selected.border.bottom = sel
c.colors.completion.item.selected.match.fg = orange
c.colors.completion.match.fg = orange
c.colors.completion.scrollbar.bg = bg
c.colors.completion.scrollbar.fg = border

c.colors.contextmenu.disabled.bg = bg_dark
c.colors.contextmenu.disabled.fg = comment
c.colors.contextmenu.menu.bg = bg
c.colors.contextmenu.menu.fg = fg
c.colors.contextmenu.selected.bg = sel
c.colors.contextmenu.selected.fg = fg

c.colors.downloads.bar.bg = bg_dark
c.colors.downloads.start.fg = bg
c.colors.downloads.start.bg = blue
c.colors.downloads.stop.fg = bg
c.colors.downloads.stop.bg = green
c.colors.downloads.error.fg = fg
c.colors.downloads.error.bg = red

c.colors.hints.fg = hint_fg
c.colors.hints.bg = hint_bg
c.colors.hints.match.fg = comment

c.colors.keyhint.fg = fg_dark
c.colors.keyhint.suffix.fg = yellow
c.colors.keyhint.bg = bg_dark

c.colors.messages.error.fg = fg
c.colors.messages.error.bg = red
c.colors.messages.warning.fg = bg_dark
c.colors.messages.warning.bg = orange
c.colors.messages.info.fg = fg
c.colors.messages.info.bg = bg_dark

c.colors.prompts.fg = fg
c.colors.prompts.border = f"1px solid {border}"
c.colors.prompts.bg = bg_dark
c.colors.prompts.selected.bg = sel
c.colors.prompts.selected.fg = fg

c.colors.statusbar.normal.fg = fg_dark
c.colors.statusbar.normal.bg = bg_dark
c.colors.statusbar.insert.fg = bg_dark
c.colors.statusbar.insert.bg = green
c.colors.statusbar.passthrough.fg = bg_dark
c.colors.statusbar.passthrough.bg = cyan
c.colors.statusbar.private.fg = fg
c.colors.statusbar.private.bg = magenta
c.colors.statusbar.command.fg = fg
c.colors.statusbar.command.bg = bg
c.colors.statusbar.command.private.fg = fg
c.colors.statusbar.command.private.bg = bg_dark
c.colors.statusbar.caret.fg = bg_dark
c.colors.statusbar.caret.bg = magenta
c.colors.statusbar.caret.selection.fg = bg_dark
c.colors.statusbar.caret.selection.bg = blue
c.colors.statusbar.progress.bg = blue

c.colors.statusbar.url.fg = fg_dark
c.colors.statusbar.url.error.fg = red
c.colors.statusbar.url.hover.fg = cyan
c.colors.statusbar.url.success.http.fg = fg_dark
c.colors.statusbar.url.success.https.fg = green
c.colors.statusbar.url.warn.fg = yellow

c.colors.tabs.bar.bg = bg_dark
c.colors.tabs.indicator.start = blue
c.colors.tabs.indicator.stop = green
c.colors.tabs.indicator.error = red

# Title half of the capsule; the icon half's colour is in the patch below.
c.colors.tabs.odd.fg = fg_dark
c.colors.tabs.odd.bg = bg_hl
c.colors.tabs.even.fg = fg_dark
c.colors.tabs.even.bg = bg_hl
c.colors.tabs.pinned.even.bg = bg_hl
c.colors.tabs.pinned.odd.bg = bg_hl
c.colors.tabs.pinned.even.fg = fg
c.colors.tabs.pinned.odd.fg = fg

c.colors.tabs.selected.odd.fg = tab_sel_fg
c.colors.tabs.selected.odd.bg = tab_sel
c.colors.tabs.selected.even.fg = tab_sel_fg
c.colors.tabs.selected.even.bg = tab_sel
c.colors.tabs.pinned.selected.even.bg = tab_sel
c.colors.tabs.pinned.selected.odd.bg = tab_sel
c.colors.tabs.pinned.selected.even.fg = tab_sel_fg
c.colors.tabs.pinned.selected.odd.fg = tab_sel_fg

# Capsule tabs: qutebrowser has no setting for tab shape, so patch its tab
# painter (qutebrowser/mainwindow/tabwidget.py, checked against 3.7.0). Each tab
# becomes a pill on the bar background, split in two: the favicon on the left
# in a solid accent, the title on the right in the colours above. Internal API —
# if an upgrade breaks it, tabs fall back to qutebrowser's flat ones.
try:
    import functools
    from qutebrowser.mainwindow.tabwidget import TabBarStyle
    from qutebrowser.qt.core import QPoint, QRect, QRectF, QSize
    from qutebrowser.qt.gui import QColor, QPainter, QPainterPath, QPen
    from qutebrowser.qt.widgets import QStyle
    from qutebrowser.keyinput import modeman
    from qutebrowser.mainwindow.statusbar.bar import StatusBar
    from qutebrowser.utils import objreg, usertypes

    _MARGIN = 3  # bar background around each capsule
    _orig_draw = getattr(TabBarStyle, "_orig_drawControl", TabBarStyle.drawControl)
    TabBarStyle._orig_drawControl = _orig_draw
    # Gap between icon and title = the gap on the icon's left, doubled so the
    # split sits midway.
    TabBarStyle.ICON_PADDING = 2 * (c.tabs.padding["left"] - _MARGIN)

    def _capsule_draw(self, element, opt, p, widget=None,
                      _bar=QColor(bg_dark), _icon_sel=QColor(blue), _icon=QColor(border),
                      _insert=QColor(green)):
        if element != QStyle.ControlElement.CE_TabBarTabShape:
            return _orig_draw(self, element, opt, p, widget)
        layouts = self._tab_layout(opt)
        if layouts is None:
            return _orig_draw(self, element, opt, p, widget)
        p.save()
        p.fillRect(opt.rect, _bar)
        p.setRenderHint(QPainter.RenderHint.Antialiasing)
        r = QRectF(opt.rect).adjusted(_MARGIN, _MARGIN, -_MARGIN, -_MARGIN)
        path = QPainterPath()
        path.addRoundedRect(r, r.height() / 2, r.height() / 2)
        p.setClipPath(path)
        p.fillRect(r, opt.palette.window())
        if layouts.icon.isValid():
            gap = layouts.icon.left() - r.left()
            split = QRectF(r)
            split.setRight(layouts.icon.right() + 1 + gap)
            selected = opt.state & QStyle.StateFlag.State_Selected
            p.fillRect(split, _icon_sel if selected else _icon)
        if opt.state & QStyle.StateFlag.State_Selected and _in_insert(widget):
            p.setClipping(False)
            p.setPen(QPen(_insert, 2))
            r = r.adjusted(1, 1, -1, -1)
            p.drawRoundedRect(r, r.height() / 2, r.height() / 2)
        p.restore()

    TabBarStyle.drawControl = _capsule_draw

    # Tabs without a favicon still get the icon half: reserve an icon-sized
    # slot so the split sits where it would with one.
    _orig_layout = getattr(TabBarStyle, "_orig_tab_layout", TabBarStyle._tab_layout)
    TabBarStyle._orig_tab_layout = _orig_layout

    def _layout_with_slot(self, opt):
        layouts = _orig_layout(self, opt)
        if layouts is None or layouts.icon.isValid():
            return layouts
        size = opt.iconSize if opt.iconSize.isValid() else QSize(16, 16)
        text = layouts.text
        top = text.center().y() + 1 - size.height() // 2
        layouts.icon = QRect(QPoint(text.left(), top), size)
        text.adjust(size.width() + TabBarStyle.ICON_PADDING, 0, 0, 0)
        return layouts

    TabBarStyle._tab_layout = _layout_with_slot

    # Insert mode: no statusbar popping up with "-- INSERT MODE --" — the
    # current tab's capsule gets a green outline instead. The statusbar's slots
    # are connected when a window opens, so this applies from the next restart.
    def _in_insert(widget):
        try:
            return modeman.instance(widget._win_id).mode == usertypes.KeyMode.insert
        except Exception:  # noqa: BLE001 — no window/mode manager yet
            return False

    def _wrap_status(name):
        orig = getattr(StatusBar, "_orig_" + name, getattr(StatusBar, name))
        setattr(StatusBar, "_orig_" + name, orig)

        # wraps() keeps the @pyqtSlot signature, so Qt still passes just `mode`.
        @functools.wraps(orig)
        def wrapped(self, *args):
            orig(self, *args)
            if _in_insert(self):
                self.hide()
            try:
                objreg.get("tabbed-browser", scope="window",
                           window=self._win_id).widget.tabBar().update()
            except Exception:  # noqa: BLE001 — window still being built
                pass
        setattr(StatusBar, name, wrapped)

    for _name in ("on_mode_entered", "on_mode_left", "maybe_hide"):
        _wrap_status(_name)
except Exception as e:  # noqa: BLE001 — never let the cosmetics break config
    from qutebrowser.utils import message
    message.warning(f"capsule tabs disabled: {e}")

c.colors.webpage.bg = bg
c.colors.webpage.darkmode.enabled = False
# Sites with their own light/dark styles follow the desktop mode.
c.colors.webpage.preferred_color_scheme = mode
