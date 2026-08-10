# niri Keybindings

`Mod` = Super/Windows key. Source of truth is `config.kdl`; regenerate this if you edit binds there.

## System / Apps
| Key | Action |
|---|---|
| `Mod+Shift+/` | Show hotkey overlay |
| `Mod+T` | Open terminal (alacritty) |
| `Mod+D` | App launcher (fuzzel) |
| `Mod+Shift+S` | Open Settings (gnome-control-center) |
| `Mod+Alt+L` | Lock the screen (swaylock) |
| `Mod+Tab` | Fuzzy window switcher (fuzzel) |
| `Mod+Shift+C` | Clipboard history (cliphist + fuzzel) |

## Mouseless pointer (warpd)
| Key | Action |
|---|---|
| `Mod+;` | Hint mode — label the screen, type a hint to jump, then `h/j/k/l` nudge, `m`/`space`/`enter` click |
| `Mod+'` | Grid mode — bisect the screen with `u/i/j/k`, `m`/`space` click |

Inside warpd normal mode: `x` = hint, `g` = grid, arrows via `h/j/k/l`, `esc` to exit.

## Media / Hardware keys
| Key | Action |
|---|---|
| `XF86AudioRaiseVolume` | Volume +10% |
| `XF86AudioLowerVolume` | Volume −10% |
| `XF86AudioMute` | Toggle mute (sink) |
| `XF86AudioMicMute` | Toggle mute (mic) |
| `XF86MonBrightnessUp` | Brightness +5% |
| `XF86MonBrightnessDown` | Brightness −5% |

## Overview / Window management
| Key | Action |
|---|---|
| `Mod+O` | Toggle overview |
| `Mod+Q` | Close window |
| `Mod+N` | Restore last notification (makoctl restore) |
| `Mod+Shift+N` | Dismiss all notifications |

## Focus (column/window) — arrows or H/J/K/L
| Key | Action |
|---|---|
| `Mod+Left` / `Mod+H` | Focus column left |
| `Mod+Down` / `Mod+J` | Focus window down |
| `Mod+Up` / `Mod+K` | Focus window up |
| `Mod+Right` / `Mod+L` | Focus column right |

## Move column/window — Mod+Ctrl+...
| Key | Action |
|---|---|
| `Mod+Ctrl+Left/H` | Move column left |
| `Mod+Ctrl+Down/J` | Move window down |
| `Mod+Ctrl+Up/K` | Move window up |
| `Mod+Ctrl+Right/L` | Move column right |

## Focus monitor — Mod+Shift+...
| Key | Action |
|---|---|
| `Mod+Shift+Left/H` | Focus monitor left |
| `Mod+Shift+Down/J` | Focus monitor down |
| `Mod+Shift+Up/K` | Focus monitor up |
| `Mod+Shift+Right/L` | Focus monitor right |

## Move column to monitor — Mod+Ctrl+Shift+...
| Key | Action |
|---|---|
| `Mod+Ctrl+Shift+Left/H` | Move column to monitor left |
| `Mod+Ctrl+Shift+Down/J` | Move column to monitor down |
| `Mod+Ctrl+Shift+Up/K` | Move column to monitor up |
| `Mod+Ctrl+Shift+Right/L` | Move column to monitor right |

## Column navigation
| Key | Action |
|---|---|
| `Mod+Home` | Focus first column |
| `Mod+End` | Focus last column |
| `Mod+Ctrl+Home` | Move column to first |
| `Mod+Ctrl+End` | Move column to last |

## Workspaces
| Key | Action |
|---|---|
| `Mod+Page_Down` / `Mod+U` | Focus workspace down |
| `Mod+Page_Up` / `Mod+I` | Focus workspace up |
| `Mod+Ctrl+Page_Down` / `Mod+Ctrl+U` | Move column to workspace down |
| `Mod+Ctrl+Page_Up` / `Mod+Ctrl+I` | Move column to workspace up |
| `Mod+WheelScrollDown/Up` | Focus workspace down/up (scroll) |
| `Mod+Ctrl+WheelScrollDown/Up` | Move column to workspace down/up (scroll) |
| `Mod+WheelScrollRight/Left` | Focus column right/left (scroll) |
| `Mod+Ctrl+WheelScrollRight/Left` | Move column right/left (scroll) |
| `Mod+1..5` | Focus workspace 1–5 |
| `Mod+Ctrl+1..5` | Move column to workspace 1–5 |

## Column consume/expel
| Key | Action |
|---|---|
| `Mod+BracketLeft` | Consume/expel window left |
| `Mod+BracketRight` | Consume/expel window right |
| `Mod+Comma` | Consume window into column |
| `Mod+Period` | Expel window from column |

## Sizing
| Key | Action |
|---|---|
| `Mod+R` | Switch preset column width |
| `Mod+Shift+R` | Switch preset column width (back) |
| `Mod+Ctrl+R` | Reset window height |
| `Mod+Ctrl+Shift+R` | Switch preset window height |
| `Mod+Minus` / `Mod+Equal` | Column width −10% / +10% |
| `Mod+Shift+Minus` / `Mod+Shift+Equal` | Window height −10% / +10% |

## Layout toggles
| Key | Action |
|---|---|
| `Mod+F` | Maximize column |
| `Mod+Shift+F` | Fullscreen window |
| `Mod+M` | Maximize window to edges |
| `Mod+Ctrl+F` | Expand column to available width |
| `Mod+C` | Center column |
| `Mod+V` | Toggle window floating |
| `Mod+Shift+V` | Switch focus floating/tiling |
| `Mod+W` | Toggle column tabbed display |

## Screenshots
| Key | Action |
|---|---|
| `Print` | Screenshot (interactive) |
| `Ctrl+Print` | Screenshot full screen |
| `Alt+Print` | Screenshot window |

## Session
| Key | Action |
|---|---|
| `Mod+Escape` | Toggle keyboard-shortcuts inhibit |
| `Mod+Shift+E` | Quit niri |
| `Ctrl+Alt+Delete` | Quit niri |
| `Mod+Shift+P` | Power off monitors |

## Keyboard layer (kanata — hardware remap, not niri)
| Key | Tap | Hold |
|---|---|---|
| `CapsLock` | Escape | Control |
| `a` `s` `d` `f` | letter | Super / Alt / Ctrl / Shift |
| `j` `k` `l` `;` | letter | Shift / Ctrl / Alt / Super |
| `Space` | Space | Nav layer: `h/j/k/l`→arrows, `u/i/o/p`→Home/End/PgUp/PgDn |
