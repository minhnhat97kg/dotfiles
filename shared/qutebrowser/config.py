# qutebrowser config
# Small tab bar (acts as the title bar under a tiling WM) + Tokyo Night colors.

config.load_autoconfig()

# WORKAROUND for https://github.com/qutebrowser/qutebrowser/issues/8914 —
# segfault in extensions::ExtensionHost on Google domains (Gmail/Meet/Gemini).
# qutebrowser only auto-disables this for QtWebEngine == 6.11.0 exactly;
# force it on regardless of patch version since we're on 6.11.1.
c.qt.workarounds.disable_hangouts_extension = True

# ── Tokyo Night palette ───────────────────────────────────────────────────────
bg        = "#1a1b26"
bg_dark   = "#16161e"
bg_hl     = "#292e42"
fg        = "#c0caf5"
fg_dark   = "#a9b1d6"
comment   = "#565f89"
border    = "#3b4261"
blue      = "#7aa2f7"
cyan      = "#7dcfff"
green     = "#9ece6a"
orange    = "#ff9e64"
red       = "#f7768e"
magenta   = "#bb9af7"
yellow    = "#e0af68"

# ── Small tab bar (title bar replacement) ────────────────────────────────────
c.tabs.position = "top"
c.tabs.show = "multiple"
c.tabs.padding = {"top": 1, "bottom": 1, "left": 5, "right": 5}
c.tabs.indicator.width = 2
c.tabs.pinned.shrink = True
c.fonts.tabs.selected = "9pt sans-serif"
c.fonts.tabs.unselected = "9pt sans-serif"
c.tabs.favicons.scale = 0.8

# Statusbar: keep it thin too
c.fonts.statusbar = "9pt monospace"
c.statusbar.padding = {"top": 1, "bottom": 1, "left": 5, "right": 5}

# OS-level window title (used by taskbar/alt-tab, not drawn on screen here)
c.window.title_format = "{perc}{current_title}"

# ── Colors: Tokyo Night ───────────────────────────────────────────────────────
c.colors.completion.fg = fg
c.colors.completion.odd.bg = bg
c.colors.completion.even.bg = bg_dark
c.colors.completion.category.fg = blue
c.colors.completion.category.bg = bg_dark
c.colors.completion.category.border.top = border
c.colors.completion.category.border.bottom = border
c.colors.completion.item.selected.fg = bg
c.colors.completion.item.selected.bg = blue
c.colors.completion.item.selected.border.top = blue
c.colors.completion.item.selected.border.bottom = blue
c.colors.completion.item.selected.match.fg = bg_dark
c.colors.completion.match.fg = orange
c.colors.completion.scrollbar.bg = bg
c.colors.completion.scrollbar.fg = fg_dark

c.colors.contextmenu.disabled.bg = bg_dark
c.colors.contextmenu.disabled.fg = comment
c.colors.contextmenu.menu.bg = bg
c.colors.contextmenu.menu.fg = fg
c.colors.contextmenu.selected.bg = blue
c.colors.contextmenu.selected.fg = bg

c.colors.downloads.bar.bg = bg_dark
c.colors.downloads.start.fg = bg
c.colors.downloads.start.bg = blue
c.colors.downloads.stop.fg = bg
c.colors.downloads.stop.bg = green
c.colors.downloads.error.fg = fg
c.colors.downloads.error.bg = red

c.colors.hints.fg = bg_dark
c.colors.hints.bg = yellow
c.colors.hints.match.fg = comment

c.colors.keyhint.fg = fg_dark
c.colors.keyhint.suffix.fg = fg
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
c.colors.prompts.selected.bg = blue
c.colors.prompts.selected.fg = bg

c.colors.statusbar.normal.fg = fg_dark
c.colors.statusbar.normal.bg = bg_dark
c.colors.statusbar.insert.fg = bg_dark
c.colors.statusbar.insert.bg = green
c.colors.statusbar.passthrough.fg = bg_dark
c.colors.statusbar.passthrough.bg = cyan
c.colors.statusbar.private.fg = fg
c.colors.statusbar.private.bg = magenta
c.colors.statusbar.command.fg = fg
c.colors.statusbar.command.bg = bg_dark
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

c.colors.tabs.odd.fg = fg_dark
c.colors.tabs.odd.bg = bg_dark
c.colors.tabs.even.fg = fg_dark
c.colors.tabs.even.bg = bg_dark
c.colors.tabs.pinned.even.bg = bg_hl
c.colors.tabs.pinned.odd.bg = bg_hl
c.colors.tabs.pinned.even.fg = fg
c.colors.tabs.pinned.odd.fg = fg

c.colors.tabs.selected.odd.fg = bg_dark
c.colors.tabs.selected.odd.bg = orange
c.colors.tabs.selected.even.fg = bg_dark
c.colors.tabs.selected.even.bg = orange
c.colors.tabs.pinned.selected.even.bg = orange
c.colors.tabs.pinned.selected.odd.bg = orange
c.colors.tabs.pinned.selected.even.fg = bg_dark
c.colors.tabs.pinned.selected.odd.fg = bg_dark

c.colors.webpage.bg = bg
c.colors.webpage.darkmode.enabled = False
