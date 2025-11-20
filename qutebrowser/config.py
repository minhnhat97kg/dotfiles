# qutebrowser config.py
# Beautiful Catppuccin Mocha theme

config.load_autoconfig(False)
import os

# =============================================================================
# CATPPUCCIN MOCHA PALETTE
# =============================================================================
palette = {
    'rosewater': '#f5e0dc',
    'flamingo': '#f2cdcd',
    'pink': '#f5c2e7',
    'mauve': '#cba6f7',
    'red': '#f38ba8',
    'maroon': '#eba0ac',
    'peach': '#fab387',
    'yellow': '#f9e2af',
    'green': '#a6e3a1',
    'teal': '#94e2d5',
    'sky': '#89dceb',
    'sapphire': '#74c7ec',
    'blue': '#89b4fa',
    'lavender': '#b4befe',
    'text': '#cdd6f4',
    'subtext1': '#bac2de',
    'subtext0': '#a6adc8',
    'overlay2': '#9399b2',
    'overlay1': '#7f849c',
    'overlay0': '#6c7086',
    'surface2': '#585b70',
    'surface1': '#45475a',
    'surface0': '#313244',
    'base': '#1e1e2e',
    'mantle': '#181825',
    'crust': '#11111b',
}

# =============================================================================
# GENERAL SETTINGS
# =============================================================================
c.content.javascript.clipboard = 'access'
c.scrolling.smooth = True
c.tabs.show = 'multiple'
c.tabs.position = 'top'
c.tabs.padding = {'top': 6, 'bottom': 6, 'left': 8, 'right': 8}
c.tabs.indicator.width = 0
c.tabs.favicons.scale = 1.0
profile_name = os.environ.get('QB_PROFILE')
if profile_name:
    c.tabs.title.format = f'[{profile_name}] ' + '{audio}{current_title}'
else:
    c.tabs.title.format = '{audio}{current_title}'
c.tabs.last_close = 'close'

c.url.start_pages = ['https://start.duckduckgo.com']
c.url.default_page = 'https://start.duckduckgo.com'
c.url.searchengines = {
    'DEFAULT': 'https://duckduckgo.com/?q={}',
    'g': 'https://www.google.com/search?q={}',
    'gh': 'https://github.com/search?q={}',
    'yt': 'https://www.youtube.com/results?search_query={}',
}

c.downloads.location.directory = '~/Downloads'
c.downloads.position = 'bottom'

c.content.blocking.enabled = True
c.content.blocking.method = 'both'

# =============================================================================
# FONTS
# =============================================================================
c.fonts.default_family = ['JetBrainsMono Nerd Font', 'SF Mono', 'monospace']
c.fonts.default_size = '12pt'
c.fonts.web.family.standard = 'SF Pro Display'
c.fonts.web.family.sans_serif = 'SF Pro Display'
c.fonts.web.family.serif = 'New York'
c.fonts.web.family.fixed = 'JetBrainsMono Nerd Font'

c.fonts.completion.category = 'bold 12pt default_family'
c.fonts.completion.entry = '12pt default_family'
c.fonts.statusbar = '12pt default_family'
c.fonts.tabs.selected = 'bold 11pt default_family'
c.fonts.tabs.unselected = '11pt default_family'
c.fonts.hints = 'bold 11pt default_family'

# =============================================================================
# COMPLETION MENU
# =============================================================================
c.colors.completion.fg = palette['text']
c.colors.completion.odd.bg = palette['mantle']
c.colors.completion.even.bg = palette['base']
c.colors.completion.category.fg = palette['blue']
c.colors.completion.category.bg = palette['base']
c.colors.completion.category.border.top = palette['base']
c.colors.completion.category.border.bottom = palette['base']
c.colors.completion.item.selected.fg = palette['text']
c.colors.completion.item.selected.bg = palette['surface1']
c.colors.completion.item.selected.border.top = palette['surface1']
c.colors.completion.item.selected.border.bottom = palette['surface1']
c.colors.completion.item.selected.match.fg = palette['peach']
c.colors.completion.match.fg = palette['peach']
c.colors.completion.scrollbar.fg = palette['surface1']
c.colors.completion.scrollbar.bg = palette['base']

# =============================================================================
# CONTEXT MENU
# =============================================================================
c.colors.contextmenu.disabled.bg = palette['mantle']
c.colors.contextmenu.disabled.fg = palette['overlay0']
c.colors.contextmenu.menu.bg = palette['base']
c.colors.contextmenu.menu.fg = palette['text']
c.colors.contextmenu.selected.bg = palette['surface1']
c.colors.contextmenu.selected.fg = palette['text']

# =============================================================================
# DOWNLOADS
# =============================================================================
c.colors.downloads.bar.bg = palette['base']
c.colors.downloads.start.fg = palette['base']
c.colors.downloads.start.bg = palette['blue']
c.colors.downloads.stop.fg = palette['base']
c.colors.downloads.stop.bg = palette['green']
c.colors.downloads.error.fg = palette['red']

# =============================================================================
# HINTS
# =============================================================================
c.colors.hints.bg = palette['yellow']
c.colors.hints.fg = palette['base']
c.colors.hints.match.fg = palette['surface2']
c.hints.border = f'1px solid {palette["yellow"]}'

# =============================================================================
# KEYHINT
# =============================================================================
c.colors.keyhint.bg = palette['base']
c.colors.keyhint.fg = palette['text']
c.colors.keyhint.suffix.fg = palette['mauve']

# =============================================================================
# MESSAGES
# =============================================================================
c.colors.messages.error.bg = palette['base']
c.colors.messages.error.border = palette['red']
c.colors.messages.error.fg = palette['red']
c.colors.messages.info.bg = palette['base']
c.colors.messages.info.border = palette['blue']
c.colors.messages.info.fg = palette['blue']
c.colors.messages.warning.bg = palette['base']
c.colors.messages.warning.border = palette['peach']
c.colors.messages.warning.fg = palette['peach']

# =============================================================================
# PROMPTS
# =============================================================================
c.colors.prompts.bg = palette['base']
c.colors.prompts.border = palette['surface1']
c.colors.prompts.fg = palette['text']
c.colors.prompts.selected.bg = palette['surface1']
c.colors.prompts.selected.fg = palette['text']

# =============================================================================
# STATUSBAR
# =============================================================================
c.colors.statusbar.normal.bg = palette['base']
c.colors.statusbar.normal.fg = palette['text']
c.colors.statusbar.insert.bg = palette['green']
c.colors.statusbar.insert.fg = palette['base']
c.colors.statusbar.passthrough.bg = palette['mauve']
c.colors.statusbar.passthrough.fg = palette['base']
c.colors.statusbar.private.bg = palette['surface1']
c.colors.statusbar.private.fg = palette['text']
c.colors.statusbar.command.bg = palette['base']
c.colors.statusbar.command.fg = palette['text']
c.colors.statusbar.command.private.bg = palette['base']
c.colors.statusbar.command.private.fg = palette['text']
c.colors.statusbar.caret.bg = palette['peach']
c.colors.statusbar.caret.fg = palette['base']
c.colors.statusbar.caret.selection.bg = palette['peach']
c.colors.statusbar.caret.selection.fg = palette['base']
c.colors.statusbar.progress.bg = palette['blue']
c.colors.statusbar.url.fg = palette['text']
c.colors.statusbar.url.error.fg = palette['red']
c.colors.statusbar.url.hover.fg = palette['sky']
c.colors.statusbar.url.success.http.fg = palette['green']
c.colors.statusbar.url.success.https.fg = palette['green']
c.colors.statusbar.url.warn.fg = palette['yellow']

# =============================================================================
# TABS
# =============================================================================
c.colors.tabs.bar.bg = palette['crust']
c.colors.tabs.indicator.start = palette['blue']
c.colors.tabs.indicator.stop = palette['green']
c.colors.tabs.indicator.error = palette['red']
c.colors.tabs.odd.bg = palette['mantle']
c.colors.tabs.odd.fg = palette['subtext1']
c.colors.tabs.even.bg = palette['mantle']
c.colors.tabs.even.fg = palette['subtext1']
c.colors.tabs.pinned.odd.bg = palette['surface0']
c.colors.tabs.pinned.odd.fg = palette['mauve']
c.colors.tabs.pinned.even.bg = palette['surface0']
c.colors.tabs.pinned.even.fg = palette['mauve']
c.colors.tabs.pinned.selected.odd.bg = palette['surface1']
c.colors.tabs.pinned.selected.odd.fg = palette['text']
c.colors.tabs.pinned.selected.even.bg = palette['surface1']
c.colors.tabs.pinned.selected.even.fg = palette['text']
c.colors.tabs.selected.odd.bg = palette['surface1']
c.colors.tabs.selected.odd.fg = palette['text']
c.colors.tabs.selected.even.bg = palette['surface1']
c.colors.tabs.selected.even.fg = palette['text']

# =============================================================================
# WEBPAGE
# =============================================================================
c.colors.webpage.bg = palette['base']
c.colors.webpage.preferred_color_scheme = 'dark'

# =============================================================================
# KEYBINDINGS
# =============================================================================
config.bind('J', 'tab-prev')
config.bind('K', 'tab-next')
config.bind('x', 'tab-close')
config.bind('X', 'undo')
config.bind('<Ctrl-Shift-Tab>', 'tab-prev')
config.bind('<Ctrl-Tab>', 'tab-next')
config.bind(',m', 'spawn mpv {url}')
config.bind(',M', 'hint links spawn mpv {hint-url}')
config.bind(',r', 'config-source')
config.bind(',p', 'spawn --userscript qute-pass')

# Vim-like navigation in insert mode
config.bind('<Ctrl-h>', 'fake-key <Backspace>', 'insert')
config.bind('<Ctrl-a>', 'fake-key <Home>', 'insert')
config.bind('<Ctrl-e>', 'fake-key <End>', 'insert')
config.bind('<Ctrl-b>', 'fake-key <Left>', 'insert')
config.bind('<Ctrl-f>', 'fake-key <Right>', 'insert')
config.bind('<Ctrl-w>', 'fake-key <Ctrl-Backspace>', 'insert')
config.bind('<Ctrl-u>', 'fake-key <Shift-Home><Delete>', 'insert')
config.bind('<Ctrl-k>', 'fake-key <Shift-End><Delete>', 'insert')
