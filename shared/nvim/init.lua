-- Minimal Neovim config: Go / Rust / React(JS/TS) / Lua

vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true

for _, p in ipairs({ "perl", "ruby", "node", "python3" }) do
  vim.g["loaded_" .. p .. "_provider"] = 0
end

-- Options
vim.opt.number = true
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true
vim.opt.scrolloff = 8
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.showmode = false
vim.opt.termguicolors = true
vim.opt.updatetime = 300
vim.opt.timeoutlen = 300
vim.opt.undofile = true
vim.opt.swapfile = false
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.smartindent = true
vim.opt.completeopt = "menu,menuone,noselect,popup"
vim.opt.winborder = "rounded"
-- Never apply options found in file content: data files (CVE payloads and the
-- like) carry attacker-controlled strings that nvim would otherwise read as
-- modelines. 'modelineexpr' is off by default, but option-setting alone is enough
-- of a hole to close.
vim.opt.modeline = false
vim.opt.list = true
vim.opt.listchars = { tab = "| ", trail = "·", nbsp = "␣" }

vim.schedule(function()
  vim.opt.clipboard = "unnamedplus"
end)

-- Keymaps
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("n", ";", ":", { desc = "Command mode" })
vim.keymap.set("i", "kj", "<Esc>")
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostics list" })
-- A split, not the current window: `:terminal` on its own replaces whatever you
-- were editing, which is the one action bar entry that could lose your place.
vim.keymap.set("n", "<leader>tt", "<Cmd>botright 15split | terminal<CR>", { desc = "Terminal" })

-- Ctrl-free aliases. On an iPad software keyboard Ctrl lives on the accessory
-- row, so every Ctrl command costs a modifier tap before the key. These give
-- the built-in Ctrl commands a leader route as well; the originals are left
-- alone, so nothing changes on a desktop keyboard.
-- Insert mode is deliberately untouched: <leader> is Space, which is a literal
-- character there, and two-letter escapes like `kj` cost you that letter pair
-- for real typing.
for _, alias in ipairs({
  { "r", "<C-r>", "Redo" },
  { "o", "<C-o>", "Jump back" },
  { "i", "<C-i>", "Jump forward" },
  { "j", "<C-d>", "Half page down" },
  { "k", "<C-u>", "Half page up" },
  { "a", "<C-a>", "Increment number" },
  { "x", "<C-x>", "Decrement number" },
  { "b", "<C-^>", "Alternate buffer" },
  -- The only default with no non-Ctrl equivalent at all.
  { "v", "<C-v>", "Blockwise visual" },
}) do
  vim.keymap.set("n", "<leader>" .. alias[1], alias[2], { desc = alias[3] })
end

-- <leader>w stands in for the <C-w> window prefix. The directions go through
-- vim-tmux-navigator so they cross into tmux panes, exactly like <C-w>hjkl does.
for key, spec in pairs({
  h = { "<Cmd>TmuxNavigateLeft<CR>", "Window/pane left" },
  j = { "<Cmd>TmuxNavigateDown<CR>", "Window/pane down" },
  k = { "<Cmd>TmuxNavigateUp<CR>", "Window/pane up" },
  l = { "<Cmd>TmuxNavigateRight<CR>", "Window/pane right" },
  s = { "<Cmd>split<CR>", "Split horizontal" },
  v = { "<Cmd>vsplit<CR>", "Split vertical" },
  c = { "<Cmd>close<CR>", "Close window" },
  o = { "<Cmd>only<CR>", "Only this window" },
  ["="] = { "<C-w>=", "Equalise windows" },
  -- Uppercase moves the window, matching <C-w>HJKL. Shift is on the iPad
  -- keyboard's letter layer, unlike <>+- which need the symbol layer.
  H = { "<C-w>H", "Move window far left" },
  J = { "<C-w>J", "Move window far down" },
  K = { "<C-w>K", "Move window far up" },
  L = { "<C-w>L", "Move window far right" },
  x = { "<C-w>x", "Swap with next window" },
  r = { "<C-w>r", "Rotate windows" },
  t = { "<C-w>T", "Break window out to a new tab" },
}) do
  vim.keymap.set("n", "<leader>w" .. key, spec[1], { desc = spec[2] })
end

-- Resizing is inherently repetitive, and three taps per step is no good on a
-- touch keyboard. Enter once, then h/l/j/k adjust repeatedly; anything else
-- leaves. getcharstr keeps this self-contained -- no submode state to leak,
-- no temporary mappings to clean up.
vim.keymap.set("n", "<leader>wz", function()
  local step = {
    h = "vertical resize -3",
    l = "vertical resize +3",
    j = "resize -2",
    k = "resize +2",
  }
  while true do
    vim.api.nvim_echo({ { "-- RESIZE --  h/l width  j/k height  (any other key exits)", "ModeMsg" } },
      false, {})
    local ok, ch = pcall(vim.fn.getcharstr)
    local cmd = ok and step[ch]
    if not cmd then break end
    pcall(vim.cmd, cmd)
    vim.cmd("redraw")
  end
  vim.api.nvim_echo({ { "" } }, false, {})
end, { desc = "Resize window (submode)" })

-- Autocmds
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
  callback = function() vim.highlight.on_yank() end,
})

-- Large files: nvim has no built-in guard, so flag the buffer here (before it is
-- read) and let the FileType/LspAttach hooks below opt out. Two tiers, both
-- measured on ~/Documents/analog/server: dropping the language server is enough
-- for a few MB, but a whole-buffer treesitter parse costs 0.7s at 6MB, 7.8s at
-- 27MB and 29s/3.3GB at 190MB, so highlighting has to go at the second tier.
-- Regex syntax stays on there, capped by synmaxcol, since it only ever
-- highlights what is drawn. Only buffer-local options are touched; window
-- options would leak into the next buffer.
local BIGFILE_BYTES = 1024 * 1024
local NO_TREESITTER_BYTES = 10 * 1024 * 1024
vim.api.nvim_create_autocmd("BufReadPre", {
  group = vim.api.nvim_create_augroup("bigfile", { clear = true }),
  callback = function(ev)
    local st = vim.uv.fs_stat(vim.api.nvim_buf_get_name(ev.buf))
    if not st or st.size < BIGFILE_BYTES then return end
    vim.b[ev.buf].bigfile = true
    vim.b[ev.buf].no_treesitter = st.size >= NO_TREESITTER_BYTES
    vim.bo[ev.buf].undofile = false
    vim.bo[ev.buf].swapfile = false
    vim.bo[ev.buf].synmaxcol = 200
  end,
})

-- Plugins
assert(vim.fn.has("nvim-0.12") == 1, "This config requires Neovim 0.12+")

local gh = function(repo) return "https://github.com/" .. repo end

vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == "telescope-fzf-native.nvim" and (kind == "install" or kind == "update") then
      vim.system({ "make" }, { cwd = ev.data.path })
    elseif name == "nvim-treesitter" and (kind == "install" or kind == "update") then
      vim.schedule(function() pcall(vim.cmd, "TSUpdate") end)
    end
  end,
})

-- Plugins needed on every startup (theme, treesitter, editing helpers,
-- completion, LSP tooling). Kept in the eager `vim.pack.add` call below.
vim.pack.add({
  { src = gh("nickkadutskyi/jb.nvim"), name = "jb.nvim" },
  { src = gh("navarasu/onedark.nvim"), name = "onedark.nvim" },
  gh("echasnovski/mini.nvim"),
  { src = gh("christoomey/vim-tmux-navigator"), name = "vim-tmux-navigator" },
  gh("nvim-treesitter/nvim-treesitter"),
  gh("saghen/blink.lib"),
  gh("saghen/blink.cmp"),
  gh("mrcjkb/rustaceanvim"),
  gh("lewis6991/gitsigns.nvim"),
  gh("williamboman/mason.nvim"),
  { src = gh("WhoIsSethDaniel/mason-tool-installer.nvim"), name = "mason-tool-installer.nvim" },
  gh("MeanderingProgrammer/render-markdown.nvim"),
  { src = gh("stevearc/quicker.nvim"), name = "quicker.nvim" },
  -- volt/menu back both the menu bar dropdowns and the right-click menu. Neither
  -- ships plugin/ scripts, so adding them here costs nothing at startup; their
  -- Lua only loads on the first `require("menu")` when a menu is opened.
  { src = gh("nvzone/volt"), name = "volt" },
  { src = gh("nvzone/menu"), name = "menu" },
})

-- Theme. Remembers the last colorscheme picked via <leader>st (Telescope
-- writes it through the ColorScheme autocmd below) so it survives restarts;
-- falls back to jb (JetBrains New UI) if nothing was saved yet or the saved
-- name is no longer valid (e.g. after removing a colorscheme plugin).
-- jb follows `vim.o.background`, so there is one name for both light and dark.
require("jb").setup({})
require("onedark").setup({ style = "darker" })
local colorscheme_state_file = vim.fn.stdpath("state") .. "/colorscheme"

local saved_colorscheme = vim.fn.filereadable(colorscheme_state_file) == 1
  and vim.fn.readfile(colorscheme_state_file)[1]
if not (saved_colorscheme and pcall(vim.cmd.colorscheme, saved_colorscheme)) then
  vim.cmd.colorscheme("jb")
end
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("remember-colorscheme", { clear = true }),
  callback = function()
    if vim.g.colors_name then
      vim.fn.writefile({ vim.g.colors_name }, colorscheme_state_file)
    end
  end,
})

-- Tool windows. JetBrains paints the Project tree, terminal and DB console on
-- a background distinct from the editor's; Nvim has no such concept, so derive
-- one. jb.nvim exposes IntelliJ's real tool-window colour as
-- ToolWindowFloatNormal (and tracks light/dark for us); every other scheme
-- falls back to a shaded Normal so <leader>st still produces something usable.
local function hl_bg(name)
  local ok, spec = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  return ok and spec.bg or nil
end

local function hl_fg(name)
  local ok, spec = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  return ok and spec.fg or nil
end

-- Scale each channel toward white (>1) or black (<1). Plain arithmetic rather
-- than `bit` so this stays readable; the values are 24-bit ints from nvim_get_hl.
local function shade(rgb, factor)
  local function chan(div)
    local c = math.floor(rgb / div) % 0x100 * factor
    return math.min(math.max(math.floor(c + 0.5), 0), 0xFF)
  end
  return chan(0x10000) * 0x10000 + chan(0x100) * 0x100 + chan(1)
end

local tool_window_winhl = table.concat({
  "Normal:ToolWindow",
  "NormalNC:ToolWindow",
  "EndOfBuffer:ToolWindowEndOfBuffer",
  "CursorLine:ToolWindowCursorLine",
  "SignColumn:ToolWindow",
  "WinSeparator:ToolWindowWinSeparator",
}, ",")

local function apply_tool_window_theme()
  local editor_bg = hl_bg("Normal")
  local pane = hl_bg("ToolWindowFloatNormal")
  if not pane then
    -- A transparent scheme has no Normal bg to shade; leave it transparent.
    if not editor_bg then return end
    pane = shade(editor_bg, vim.o.background == "dark" and 1.28 or 0.97)
  end
  local sel = shade(pane, vim.o.background == "dark" and 1.32 or 0.94)

  -- fg matters: windows mapped to ToolWindow via winhighlight draw their text
  -- with it, and without one the text falls back to no colour at all.
  vim.api.nvim_set_hl(0, "ToolWindow", { bg = pane, fg = hl_fg("Normal") })
  vim.api.nvim_set_hl(0, "ToolWindowCursorLine", { bg = sel })
  -- Subdued-but-legible text on the pane, for shortcut columns and separators.
  -- Comment's own fg only reaches ~3.4:1 against the pane, so lift it to ~4.5:1
  -- while staying clearly dimmer than the item labels.
  local dim = hl_fg("Comment")
  vim.api.nvim_set_hl(0, "ToolWindowDim", {
    bg = pane,
    fg = dim and shade(dim, vim.o.background == "dark" and 1.22 or 0.76) or nil,
  })

  -- nvzone/menu paints with NvChad's Ex* group names. volt defines them itself,
  -- with a non-NvChad fallback branch that derives from Normal and Comment — so
  -- call volt rather than hand-rolling the palette. The module does its work at
  -- load time and caches, so drop it from package.loaded to pick up the new
  -- colorscheme.
  package.loaded["volt.highlights"] = nil
  pcall(require, "volt.highlights")
  -- ...but its non-NvChad branch reads colours with nvim_get_hl and no
  -- `link = false`, so every fg taken from a *linked* group (Comment, Function)
  -- comes back nil and lands as #000000 — black text on a dark menu. The
  -- bg-derived groups it produces are correct; redo only the fg ones.
  vim.api.nvim_set_hl(0, "ExLightGrey", { fg = hl_fg("Normal") })
  vim.api.nvim_set_hl(0, "CommentFg", { fg = hl_fg("Comment") })
  vim.api.nvim_set_hl(0, "ExRed", { fg = hl_fg("DiagnosticError") })
  vim.api.nvim_set_hl(0, "ExYellow", { fg = hl_fg("DiagnosticWarn") })
  vim.api.nvim_set_hl(0, "ExBlue", { fg = hl_fg("Function") })
  vim.api.nvim_set_hl(0, "ExGreen", { fg = hl_fg("String") })
  -- The `~` filler must vanish into the pane rather than sit on editor colour.
  vim.api.nvim_set_hl(0, "ToolWindowEndOfBuffer", { fg = pane, bg = pane })
  vim.api.nvim_set_hl(0, "ToolWindowWinSeparator", {
    fg = (vim.api.nvim_get_hl(0, { name = "WinSeparator", link = false }) or {}).fg,
    bg = pane,
  })

  -- nvim-tree drives its own winhighlight off these, so defining them is enough.
  -- SignColumn/LineNr/StatusLine included or they keep the editor bg as a stripe
  -- down the side of the pane.
  for _, group in ipairs({
    "NvimTreeNormal", "NvimTreeNormalNC", "NvimTreeSignColumn",
    "NvimTreeLineNr", "NvimTreeStatusLine", "NvimTreeStatuslineNC",
  }) do
    vim.api.nvim_set_hl(0, group, { link = "ToolWindow" })
  end
  -- The menu bar is a tool window too — JetBrains paints it the same grey.
  vim.api.nvim_set_hl(0, "TabLineFill", { bg = pane })
  vim.api.nvim_set_hl(0, "TabLine", { bg = pane, fg = hl_fg("Normal") })
  vim.api.nvim_set_hl(0, "TabLineSel", { bg = sel, fg = hl_fg("Normal"), bold = true })

  vim.api.nvim_set_hl(0, "NvimTreeEndOfBuffer", { link = "ToolWindowEndOfBuffer" })
  vim.api.nvim_set_hl(0, "NvimTreeCursorLine", { link = "ToolWindowCursorLine" })
  vim.api.nvim_set_hl(0, "NvimTreeWinSeparator", { link = "ToolWindowWinSeparator" })
end

-- Scheduled: nvim-tree reasserts its own highlights from a ColorScheme handler
-- registered when it lazy-loads, i.e. after this one. Deferring puts us last.
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("tool-window-theme", { clear = true }),
  callback = function() vim.schedule(apply_tool_window_theme) end,
})
apply_tool_window_theme()

-- Windows that play the role of a JetBrains tool window but, unlike nvim-tree,
-- have no dedicated highlight namespace — reach them through winhighlight.
-- Two autocmds because TermOpen matches on buffer name, not filetype.
local tool_window_panes = vim.api.nvim_create_augroup("tool-window-panes", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = tool_window_panes,
  pattern = { "qf", "help", "dbui", "dbout", "dbui-drawer" },
  callback = function() vim.wo.winhighlight = tool_window_winhl end,
})

-- nvzone/menu's float. It sets its own winhl before setting the filetype, so
-- this runs after and wins. menu/ui.lua hardcodes LineNr for the shortcut
-- column and separators, which is far too dark on the pane background — remap
-- it window-locally so the editor's own line numbers keep their colour.
vim.api.nvim_create_autocmd("FileType", {
  group = tool_window_panes,
  pattern = "NvMenu",
  callback = function()
    vim.wo.winhighlight = table.concat({
      "Normal:ToolWindow",
      "NormalNC:ToolWindow",
      "EndOfBuffer:ToolWindowEndOfBuffer",
      "LineNr:ToolWindowDim",
      "FloatBorder:ToolWindowWinSeparator",
    }, ",")
  end,
})
vim.api.nvim_create_autocmd("TermOpen", {
  group = tool_window_panes,
  callback = function() vim.wo.winhighlight = tool_window_winhl end,
})

-- Quickfix as a table, via quicker.nvim: aligned filename/lnum/text columns,
-- per-file headers, treesitter-highlighted results, and an editable list (`:w`
-- writes edits back to every file). Replaces a hand-rolled quickfixtextfunc
-- plus a replacement qf syntax.
require("quicker").setup({
  opts = { number = false, wrap = false, winfixheight = true },
  edit = { enabled = true, autosave = "unmodified" },
  highlight = { treesitter = true, lsp = true },
  trim_leading_whitespace = "common",
  -- Keep the text column readable on a narrow split.
  max_filename_width = function() return math.floor(math.min(60, vim.o.columns / 3)) end,
  keys = {
    { ">", function() require("quicker").expand({ before = 2, after = 2 }) end,
      desc = "Expand quickfix context" },
    { "<", function() require("quicker").collapse() end,
      desc = "Collapse quickfix context" },
  },
})

-- Action bar across the top: one icon, one command, no dropdown. Icons are
-- literal Nerd Font glyphs -- nvim-web-devicons and mini.icons only map *file
-- types*, so neither can supply a "search" or "terminal" icon. Codepoints come
-- from ryanoasis/nerd-fonts glyphnames.json.
local action_bar = {
  { icon = "\u{F0645}", label = "File tree",   keys = "<leader>e" },   -- md-file_tree
  { icon = "\u{F021E}", label = "Find file",   keys = "<leader>sf" },  -- md-file_find
  { icon = "\u{F13B8}", label = "Grep",        keys = "<leader>sg" },  -- md-text_search
  { icon = "\u{F0279}", label = "Symbols",     keys = "<leader>ss" },  -- md-format_list_bulleted
  { icon = "\u{F05D6}", label = "Diagnostics", keys = "<leader>q" },   -- md-alert_circle_outline
  { icon = "\u{E702}",  label = "Git",         keys = "<leader>gg" },  -- dev-git
  { icon = "\u{F062C}", label = "Commit graph", keys = "<leader>gl" }, -- md-source_branch
  { icon = "\u{F018D}", label = "Terminal",    keys = "<leader>tt" },  -- md-console
  { icon = "\u{F00E4}", label = "Debug",       keys = "<F5>" },        -- md-bug
}

-- What to print in the shortcut column. <leader> is a space here, which shows
-- as nothing useful, so spell it.
local function menu_shortcut(keys)
  local cmd = keys:match("^<Cmd>(.-)<CR>$")
  if cmd then return ":" .. cmd end
  return (keys:gsub("<leader>", "<Space>"))
end

-- Feed the *existing* keymap rather than calling the underlying function, so
-- lazy_keymap wrappers still lazy-load their plugin and no menu entry can drift
-- from the keymap it advertises. "m" so leader mappings resolve.
local function menu_feed(keys)
  return function()
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "m", false)
  end
end

-- Our {label, keys} pairs -> nvzone/menu's {name, cmd, rtxt}. An empty entry is
-- a separator.
local function menu_items(entries)
  local items = {}
  for _, entry in ipairs(entries) do
    if entry[1] == nil then
      items[#items + 1] = { name = "separator" }
    else
      items[#items + 1] = { name = entry[1], cmd = menu_feed(entry[2]), rtxt = menu_shortcut(entry[2]) }
    end
  end
  return items
end

local function menu_open(entries, opts)
  require("menu").open(menu_items(entries), vim.tbl_extend("force", { border = true }, opts or {}))
end

function _G.menubar_click(idx)
  if idx == #action_bar + 1 then return _G.close_tool_window() end
  local action = action_bar[idx]
  if action then menu_feed(action.keys)() end
end

-- Which icon the pointer is resting on, so it can be highlighted and named.
-- Set by the <MouseMove> handler further down; nil when the pointer is elsewhere.
local hovered_action = nil

-- Everything the action bar can open, so one close button can shut any of them.
-- Terminals are matched on buftype: they carry no filetype of their own.
local TOOL_WINDOW_FT = {
  NvimTree = true, qf = true, help = true, gitgraph = true,
  dbui = true, dbout = true, ["dbui-drawer"] = true, NvMenu = true,
  ["dap-view"] = true, ["dap-view-term"] = true, ["dap-view-hover"] = true,
  ["dap-view-help"] = true, ["dap-repl"] = true,
}

local function is_tool_window(win)
  local buf = vim.api.nvim_win_get_buf(win)
  return TOOL_WINDOW_FT[vim.bo[buf].filetype] or vim.bo[buf].buftype == "terminal"
end

-- The × on the bar. Closes the focused tool window, else the first one it finds.
-- Diffview owns a whole tabpage, so it gets its own command rather than having a
-- single window pulled out from under it.
function _G.close_tool_window()
  local wins = vim.api.nvim_list_wins()
  for _, win in ipairs(wins) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype:find("^Diffview") then
      pcall(vim.cmd, "DiffviewClose")
      return
    end
  end
  local cur = vim.api.nvim_get_current_win()
  local target = is_tool_window(cur) and cur or nil
  if not target then
    for _, win in ipairs(wins) do
      if is_tool_window(win) then target = win break end
    end
  end
  if not target then return end

  -- Every tool view opens in its own window, so closing the window is the rule.
  -- The exception is a view that ended up as the last one standing: closing it
  -- would take the editor with it, so unload the buffer instead and Nvim falls
  -- back to whatever was there before.
  if #wins < 2 then
    pcall(vim.api.nvim_buf_delete, vim.api.nvim_win_get_buf(target), { force = true })
    return
  end
  pcall(vim.api.nvim_win_close, target, true)
end

function _G.menubar_tabline()
  local parts = {}
  for i, action in ipairs(action_bar) do
    parts[#parts + 1] = ("%%#%s#%%%d@v:lua.menubar_click@  %s  %%X"):format(
      hovered_action == i and "TabLineSel" or "TabLine", i, action.icon)
  end
  -- Icons alone are cryptic, so name whichever one is under the pointer.
  if hovered_action and action_bar[hovered_action] then
    local a = action_bar[hovered_action]
    parts[#parts + 1] = ("%%#ToolWindowDim#  %s  %s"):format(a.label, menu_shortcut(a.keys))
  end
  parts[#parts + 1] = "%#TabLineFill#%="
  -- Close button, right-aligned like a JetBrains tool-window header.
  parts[#parts + 1] = ("%%#TabLine#%%%d@v:lua.menubar_click@  \u{F0156}  %%X"):format(#action_bar + 1)
  -- Don't silently eat the tabline's real job: list tabpages when there are any.
  local tabs = vim.api.nvim_list_tabpages()
  if #tabs > 1 then
    local cur = vim.api.nvim_get_current_tabpage()
    for i, tab in ipairs(tabs) do
      parts[#parts + 1] = ("%%#%s# %d %%#TabLineFill#"):format(
        tab == cur and "TabLineSel" or "TabLine", i)
    end
  end
  return table.concat(parts)
end

vim.o.tabline = "%!v:lua.menubar_tabline()"
vim.o.showtabline = 2

-- Keyboard route to the same actions (<F10> is already Debug: step over).
-- Reuses nvzone/menu so the list carries the shortcut column.
vim.keymap.set("n", "<leader>m", function()
  local entries = {}
  for _, action in ipairs(action_bar) do
    entries[#entries + 1] = { action.icon .. "  " .. action.label, action.keys }
  end
  menu_open(entries)
end, { desc = "Action bar" })

-- Expose for the hover handler below, which lives past several other blocks.
function _G.menubar_set_hover(idx)
  if hovered_action == idx then return false end
  hovered_action = idx
  vim.cmd("redrawtabline")
  return true
end

function _G.menubar_hovered() return hovered_action end
function _G.menubar_actions_count() return #action_bar end

-- Screen column -> icon index. Measured with strdisplaywidth rather than assumed:
-- Nerd Font glyphs are not all one cell wide.
function _G.menubar_action_at(col)
  local x = 0
  for i, action in ipairs(action_bar) do
    local w = vim.fn.strdisplaywidth("  " .. action.icon .. "  ")
    if col > x and col <= x + w then return i end
    x = x + w
  end
  return nil
end

-- Mouse / touchpad. tmux already runs with `mouse on`, so Nvim only has to make
-- use of what it is handed.
vim.o.mouse = "a"                 -- was "nvi"; adds command-line and terminal modes
vim.o.mousescroll = "ver:1,hor:4" -- ver:3 lurches on a smooth-scrolling touchpad

-- Right-click context menu, same table shape and same feed-the-keymap machinery
-- as the menu bar. An empty entry is a separator.
local context_menu = {
  { "Go to Definition", "gd" },
  { "References", "gr" },
  { "Implementation", "gi" },
  {},
  { "Rename Symbol", "<leader>lr" },
  { "Code Action", "<leader>la" },
  { "Format Buffer", "<leader>lf" },
  {},
  { "Line Diagnostics", "gl" },
  {},
  { "Stage Hunk", "<leader>hs" },
  { "Reset Hunk", "<leader>hr" },
  { "Preview Hunk", "<leader>hp" },
  { "Blame Line", "<leader>hb" },
  {},
  -- Worth keeping from the stock menu.
  { "Open in Browser", "gx" },
  { "Inspect Highlight", "<Cmd>Inspect<CR>" },
}

-- Drop Nvim's stock PopUp so nothing else answers a right-click, then drive our
-- own. mousemodel stays popup_setpos, but the cursor is placed explicitly here
-- rather than relying on that side effect — the LSP entries act on the cursor.
pcall(vim.cmd, "aunmenu PopUp")
vim.keymap.set("n", "<RightMouse>", function()
  local pos = vim.fn.getmousepos()
  if pos.winid ~= 0 and pos.line > 0 then
    pcall(vim.api.nvim_set_current_win, pos.winid)
    pcall(vim.api.nvim_win_set_cursor, pos.winid, { pos.line, math.max(pos.column - 1, 0) })
  end
  menu_open(context_menu, { mouse = true })
end, { desc = "Context menu" })

-- Hover diagnostics. Turning on mousemoveevent means every pointer movement
-- reaches Nvim, so the handler stays cheap and the real work is debounced.
-- Set to 0 to switch hover off entirely.
local MOUSE_HOVER_MS = 400

if MOUSE_HOVER_MS > 0 then
  vim.o.mousemoveevent = true
  local hover_timer = vim.uv.new_timer()
  local hover_win, hover_key

  local function close_hover()
    if hover_win and vim.api.nvim_win_is_valid(hover_win) then
      vim.api.nvim_win_close(hover_win, true)
    end
    hover_win, hover_key = nil, nil
  end

  function _G.mouse_hover_diagnostics()
    hover_timer:stop()
    local pos = vim.fn.getmousepos()
    -- Row 1 is the action bar: name whichever icon is under the pointer.
    if pos.screenrow == 1 and vim.o.showtabline == 2 then
      close_hover()
      _G.menubar_set_hover(_G.menubar_action_at(pos.screencol))
      return
    end
    _G.menubar_set_hover(nil)
    -- winid 0 means the pointer is off any window (statusline, gutter).
    if pos.winid == 0 or pos.line == 0 then
      close_hover()
      return
    end
    local key = pos.winid .. ":" .. pos.line
    if key == hover_key then return end -- same line, float already correct
    close_hover()
    hover_key = key

    hover_timer:start(MOUSE_HOVER_MS, 0, vim.schedule_wrap(function()
      if not vim.api.nvim_win_is_valid(pos.winid) then return end
      local buf = vim.api.nvim_win_get_buf(pos.winid)
      local diags = vim.diagnostic.get(buf, { lnum = pos.line - 1 })
      if #diags == 0 then return end

      local lines, width = {}, 0
      for _, d in ipairs(diags) do
        for _, l in ipairs(vim.split(d.message, "\n", { plain = true })) do
          lines[#lines + 1] = l
          width = math.max(width, vim.fn.strdisplaywidth(l))
        end
      end
      width = math.min(width, 80)
      local height = math.min(#lines, 10)

      local fbuf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(fbuf, 0, -1, false, lines)
      -- Sit just below the pointer, clamped so the float stays on screen.
      local row = pos.screenrow
      if row + height + 2 > vim.o.lines then row = math.max(pos.screenrow - height - 2, 0) end
      hover_win = vim.api.nvim_open_win(fbuf, false, {
        relative = "editor",
        row = row,
        col = math.min(math.max(pos.screencol - 1, 0), math.max(vim.o.columns - width - 2, 0)),
        width = width,
        height = height,
        style = "minimal",
        border = "rounded",
        focusable = false,
        noautocmd = true,
      })
    end))
  end

  vim.keymap.set({ "n", "i" }, "<MouseMove>", function() _G.mouse_hover_diagnostics() end,
    { desc = "Hover diagnostics under mouse" })
  vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter", "BufLeave", "WinScrolled" }, {
    group = vim.api.nvim_create_augroup("mouse-hover-diagnostics", { clear = true }),
    callback = close_hover,
  })
end

-- UI/editing helpers
require("mini.ai").setup({ n_lines = 500 })
require("mini.surround").setup()

require("gitsigns").setup({
  current_line_blame = false, -- keep the at-rest UI clean; toggle with <leader>htb
  on_attach = function(bufnr)
    local gs = require("gitsigns")
    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = "Git: " .. desc })
    end
    map("n", "]h", function()
      if vim.wo.diff then vim.cmd.normal({ "]c", bang = true }) else gs.nav_hunk("next") end
    end, "next hunk")
    map("n", "[h", function()
      if vim.wo.diff then vim.cmd.normal({ "[c", bang = true }) else gs.nav_hunk("prev") end
    end, "previous hunk")
    map("n", "<leader>hs", gs.stage_hunk, "stage hunk")
    map("n", "<leader>hr", gs.reset_hunk, "reset hunk")
    map("v", "<leader>hs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "stage selection")
    map("v", "<leader>hr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "reset selection")
    map("n", "<leader>hS", gs.stage_buffer, "stage buffer")
    map("n", "<leader>hR", gs.reset_buffer, "reset buffer")
    map("n", "<leader>hp", gs.preview_hunk, "preview hunk")
    map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, "blame line")
    map("n", "<leader>htb", gs.toggle_current_line_blame, "toggle line blame")
    map("n", "<leader>hd", gs.diffthis, "diff against index")
  end,
})

-- Markdown rendering (in-buffer, uses treesitter + devicons)
require("render-markdown").setup({
  completions = { lsp = { enabled = true } },
})
vim.keymap.set("n", "<leader>tm", "<cmd>RenderMarkdown toggle<CR>", { desc = "Toggle markdown render" })

-- nvim-treesitter `main` branch API on nvim 0.12
require("nvim-treesitter").setup()
require("nvim-treesitter").install({
  "bash", "go", "gomod", "gosum", "gowork", "java", "javascript", "typescript", "tsx", "json", "lua", "luadoc", "markdown", "markdown_inline", "python", "rust", "toml", "vim", "vimdoc",
})

-- File tree, fuzzy search, and Mason are only touched on demand (a keymap
-- press or an explicit command), not on every buffer/session. Registering
-- them with vim.pack.add eagerly still costs real startup time — Nvim
-- sources every added plugin's `plugin/` scripts right after init.lua runs,
-- regardless of any `load` option — so keep them out of the call above and
-- only `vim.pack.add` + `require(...).setup()` them the first time they're
-- actually invoked.
local lazy_loaded = {}
local function lazy_require(key, specs, setup)
  if lazy_loaded[key] then return end
  lazy_loaded[key] = true
  vim.pack.add(specs, { load = true })
  setup()
end

local function lazy_keymap(mode, lhs, key, specs, setup, action, opts)
  vim.keymap.set(mode, lhs, function()
    lazy_require(key, specs, setup)
    action()
  end, opts)
end

-- Formatting (conform.nvim). Loaded on first save/format, never at startup.
local conform_specs = { gh("stevearc/conform.nvim") }
local function conform_setup()
  require("conform").setup({
    formatters_by_ft = {
      go = { "gofumpt", "goimports-reviser" },
      javascript = { "prettier" },
      javascriptreact = { "prettier" },
      typescript = { "prettier" },
      typescriptreact = { "prettier" },
      json = { "prettier" },
      lua = { "stylua" },
      -- ruff_fix applies safe lint fixes (incl. import sorting) before
      -- ruff_format lays the code out — order matters.
      python = { "ruff_fix", "ruff_format" },
      -- rust/java fall through to LSP (rust-analyzer / jdtls) via lsp_format below
    },
  })
end

local function conform_format(bufnr, async)
  lazy_require("conform", conform_specs, conform_setup)
  require("conform").format({ bufnr = bufnr, async = async, timeout_ms = 500, lsp_format = "fallback" })
end

vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("format-on-save", { clear = true }),
  callback = function(args)
    if vim.g.disable_autoformat or vim.b[args.buf].disable_autoformat then return end
    if vim.b[args.buf].bigfile then return end
    conform_format(args.buf, false)
  end,
})

-- :FormatToggle (global) / :FormatToggle! (this buffer) — escape hatch for
-- vendored or generated files.
vim.api.nvim_create_user_command("FormatToggle", function(cmd)
  if cmd.bang then
    vim.b.disable_autoformat = not vim.b.disable_autoformat
    vim.notify("Format-on-save (buffer): " .. (vim.b.disable_autoformat and "off" or "on"))
  else
    vim.g.disable_autoformat = not vim.g.disable_autoformat
    vim.notify("Format-on-save (global): " .. (vim.g.disable_autoformat and "off" or "on"))
  end
end, { bang = true, desc = "Toggle format-on-save" })

-- LSP clients are detached from large files (see the bigfile guard below),
-- which leaves this dead there, so JSON goes through jq instead.
vim.keymap.set("n", "<leader>lf", function()
  local ft = vim.bo.filetype
  if (ft == "json" or ft == "jsonc") and vim.b.bigfile and vim.fn.executable("jq") == 1 then
    local view = vim.fn.winsaveview()
    vim.cmd("silent keepjumps %!jq .")
    if vim.v.shell_error ~= 0 then
      vim.cmd("silent undo")
      vim.notify("jq failed (invalid JSON, or comments in jsonc)", vim.log.levels.ERROR)
    end
    vim.fn.winrestview(view)
  else
    conform_format(0, true)
  end
end, { desc = "Format buffer" })

local nvim_tree_specs = {
  { src = gh("nvim-tree/nvim-tree.lua"), name = "nvim-tree.lua" },
  { src = gh("nvim-tree/nvim-web-devicons"), name = "nvim-web-devicons" },
}
local function nvim_tree_setup()
  require("nvim-tree").setup({
    sort = { sorter = "case_sensitive" },
    view = { width = 32 },
    renderer = {
      group_empty = true,
      icons = { show = { git = false } },
    },
    filters = { dotfiles = false },
    on_attach = function(bufnr)
      local api = require("nvim-tree.api")
      api.config.mappings.default_on_attach(bufnr)
      -- Single click to open: double-tapping a touchpad is fiddly. <LeftMouse>
      -- is unmapped, so it has already moved the cursor onto the node by the
      -- time <LeftRelease> fires — just act on whatever sits under it.
      vim.keymap.set("n", "<LeftRelease>", function()
        if api.tree.get_node_under_cursor() then api.node.open.edit() end
      end, { buffer = bufnr, desc = "nvim-tree: open on single click" })
    end,
  })
end
lazy_keymap("n", "<leader>e", "nvim-tree", nvim_tree_specs, nvim_tree_setup,
  function() vim.cmd.NvimTreeToggle() end, { desc = "Toggle file tree" })
lazy_keymap("n", "<leader>E", "nvim-tree", nvim_tree_specs, nvim_tree_setup,
  function() vim.cmd.NvimTreeFindFile() end, { desc = "Reveal current file" })

local telescope_specs = {
  gh("nvim-lua/plenary.nvim"),
  gh("nvim-telescope/telescope.nvim"),
  { src = gh("nvim-telescope/telescope-fzf-native.nvim"), name = "telescope-fzf-native.nvim" },
}
-- Prompt sits on top with ascending sort so the best match lands directly under
-- the cursor. The prompt/results borderchars are deliberately joined (┤├ / ╰╯)
-- so the two windows read as one panel instead of two stacked boxes. Pickers
-- that don't benefit from a preview get the compact ivy/dropdown treatment.
local function telescope_setup()
  local telescope = require("telescope")
  local themes = require("telescope.themes")
  telescope.setup({
    defaults = {
      layout_strategy = "flex",
      layout_config = {
        height = 0.95,
        prompt_position = "top",
        horizontal = { preview_width = 0.55 },
        flex = { flip_columns = 140 },
      },
      sorting_strategy = "ascending",
      path_display = { "filename_first" },
      dynamic_preview_title = true,
      prompt_prefix = "   ",
      selection_caret = "  ",
      entry_prefix = "   ",
      multi_icon = " ",
      borderchars = {
        prompt = { "─", "│", "─", "│", "╭", "╮", "┤", "├" },
        results = { "─", "│", "─", "│", "├", "┤", "╯", "╰" },
        preview = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
      },
      winblend = 0,
    },
    pickers = {
      buffers = themes.get_ivy({ previewer = false, sort_mru = true }),
      keymaps = themes.get_ivy({ previewer = false }),
      diagnostics = themes.get_ivy(),
      colorscheme = themes.get_dropdown({ previewer = false }),
    },
  })
  pcall(telescope.load_extension, "fzf")
end
local function tb(name, opts)
  return function()
    lazy_require("telescope", telescope_specs, telescope_setup)
    require("telescope.builtin")[name](opts)
  end
end
vim.keymap.set("n", "<leader>sf", tb("find_files"), { desc = "Search files" })
vim.keymap.set("n", "<leader>sg", tb("live_grep"), { desc = "Search grep" })
vim.keymap.set("n", "<leader>sw", tb("grep_string"), { desc = "Search word" })
vim.keymap.set("n", "<leader>sb", tb("buffers"), { desc = "Search buffers" })
vim.keymap.set("n", "<leader>sh", tb("help_tags"), { desc = "Search help" })
vim.keymap.set("n", "<leader><leader>", tb("buffers"), { desc = "Buffers" })
vim.keymap.set("n", "<leader>sd", tb("diagnostics"), { desc = "Search diagnostics (project)" })
vim.keymap.set("n", "<leader>ss", tb("lsp_document_symbols"), { desc = "Search symbols (file outline)" })
vim.keymap.set("n", "<leader>sS", tb("lsp_workspace_symbols"), { desc = "Search symbols (workspace)" })
vim.keymap.set("n", "<leader>sk", tb("keymaps"), { desc = "Search keymaps" })
vim.keymap.set("n", "<leader>sc", tb("git_bcommits"), { desc = "Search commits touching this file" })
vim.keymap.set("n", "<leader>st", tb("colorscheme", { enable_preview = true }), { desc = "Pick colorscheme (live preview)" })

local lazygit_specs = {
  { src = gh("kdheepak/lazygit.nvim"), name = "lazygit.nvim" },
  gh("nvim-lua/plenary.nvim"),
}
local function lazygit_setup() end
local function open_lazygit()
  lazy_require("lazygit", lazygit_specs, lazygit_setup)
  vim.cmd.LazyGit()
end
lazy_keymap("n", "<leader>gg", "lazygit", lazygit_specs, lazygit_setup,
  open_lazygit, { desc = "Lazygit" })

-- Commit graph (gitgraph.nvim). Renders into an ordinary Nvim buffer, so `/`,
-- yank and the leader maps all work on it. Selecting a commit opens it in
-- Diffview, which this config already carries; the :DiffviewOpen stubs further
-- down load the plugin on demand, so the hooks need no lazy handling of their own.
local gitgraph_specs = { { src = gh("isakbm/gitgraph.nvim"), name = "gitgraph.nvim" } }
local function gitgraph_setup()
  require("gitgraph").setup({
    -- Box-drawing symbols match the JetBrains chrome better than ASCII.
    symbols = { merge_commit = "●", commit = "○", merge_commit_end = "●", commit_end = "○" },
    format = { timestamp = "%d-%m-%Y", fields = { "hash", "timestamp", "author", "branch_name", "tag" } },
    hooks = {
      on_select_commit = function(commit)
        vim.cmd("DiffviewOpen " .. commit.hash .. "^!")
      end,
      on_select_range_commit = function(from, to)
        vim.cmd(("DiffviewOpen %s~1..%s"):format(from.hash, to.hash))
      end,
    },
  })
end
local function gitgraph_draw(all)
  return function()
    -- Draw into a split of its own. gitgraph renders into the current window,
    -- which would take over the buffer you were editing -- the one thing every
    -- other action-bar entry avoids, and it left the × with no window to close.
    -- Reuse the graph window if one is already up rather than stacking splits.
    local existing
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "gitgraph" then existing = win end
    end
    if existing then
      vim.api.nvim_set_current_win(existing)
    else
      vim.cmd("botright split")
    end
    require("gitgraph").draw({}, { all = all, max_count = 5000 })
  end
end
lazy_keymap("n", "<leader>gl", "gitgraph", gitgraph_specs, gitgraph_setup,
  gitgraph_draw(false), { desc = "Git commit graph" })
lazy_keymap("n", "<leader>gL", "gitgraph", gitgraph_specs, gitgraph_setup,
  gitgraph_draw(true), { desc = "Git commit graph (all branches)" })

-- One way out of every tool window. Diffview already binds `q` in its own
-- panels; these are the ones that shipped without it, so `q` (or the × on the
-- action bar) closes anything the bar can open.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("tool-window-close", { clear = true }),
  pattern = { "gitgraph", "qf", "dap-view", "dap-view-term", "dap-repl", "help" },
  callback = function(ev)
    vim.keymap.set("n", "q", "<Cmd>close<CR>", { buffer = ev.buf, desc = "Close tool window" })
  end,
})

-- Terminals have no filetype, and `q` in terminal mode would be typed into the
-- shell -- bind it only for normal mode, which <Esc><Esc> drops you into.
vim.api.nvim_create_autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("terminal-close", { clear = true }),
  callback = function(ev)
    vim.keymap.set("n", "q", "<Cmd>close<CR>", { buffer = ev.buf, desc = "Close terminal" })
  end,
})

-- Diffview: a whole branch or PR in one tab -- file panel on the left, diff on
-- the right -- which `git difftool` can only do one file at a time. Lazy like
-- the rest: the stub commands below load it on first use.
local diffview_specs = {
  gh("sindrets/diffview.nvim"),
  gh("nvim-lua/plenary.nvim"),
  -- Devicons is in the pack but lazy, so name it here too: diffview's file
  -- panel warns and falls back to no icons when it loads without it.
  { src = gh("nvim-tree/nvim-web-devicons"), name = "nvim-web-devicons" },
}
local function diffview_setup()
  -- Filler lines default to a wall of "-". A dim diagonal reads as "nothing
  -- here" instead of as content, which is most of what makes a diff legible.
  vim.opt.fillchars:append({ diff = "\u{2571}" })
  -- histogram aligns moved blocks far better than the default myers, and a
  -- higher linematch budget keeps rewritten hunks lined up side by side.
  -- Filtered rather than appended: nvim ships its own linematch, and appending
  -- leaves both values in the option.
  local diffopt = vim.tbl_filter(function(opt)
    return not (vim.startswith(opt, "linematch:") or vim.startswith(opt, "algorithm:"))
  end, vim.opt.diffopt:get())
  vim.list_extend(diffopt, { "algorithm:histogram", "linematch:60" })
  vim.opt.diffopt = diffopt

  -- jb.nvim (and several other themes) define DiffText identical to DiffChange
  -- and DiffDelete as the dim filler colour, per the plain-vimdiff convention.
  -- Diffview reuses those for real deleted lines and for intra-line changes, so
  -- taken as-is a diff comes out nearly monochrome. Re-apply on ColorScheme,
  -- since <leader>st can switch themes at runtime.
  local function diff_highlights()
    local dark = vim.o.background == "dark"
    local c = dark
      and { add = "#26402f", del = "#45242a", chg = "#2c3f52", txt = "#2f628f", dim = "#3a3f45" }
      or { add = "#ddf4e4", del = "#fbdfe2", chg = "#e3edf7", txt = "#b9d8f5", dim = "#d8dde3" }
    vim.api.nvim_set_hl(0, "DiffAdd", { bg = c.add })
    vim.api.nvim_set_hl(0, "DiffChange", { bg = c.chg })
    -- The one that matters most: the exact characters that changed, which
    -- diffopt's inline:char marks. It has to out-contrast DiffChange.
    vim.api.nvim_set_hl(0, "DiffText", { bg = c.txt, bold = true })
    -- DiffDelete stays the filler colour (fg only) so the diff:╱ fill does not
    -- become a solid block; diffview's own group carries the deleted lines.
    vim.api.nvim_set_hl(0, "DiffDelete", { fg = c.dim, bg = "NONE" })
    vim.api.nvim_set_hl(0, "DiffviewDiffAddAsDelete", { bg = c.del })
    vim.api.nvim_set_hl(0, "DiffviewDiffDelete", { fg = c.dim, bg = "NONE" })
    vim.api.nvim_set_hl(0, "DiffviewDiffDeleteDim", { fg = c.dim, bg = "NONE" })
  end
  require("diffview").setup({
    enhanced_diff_hl = true,
    signs = { fold_closed = "\u{F0DA}", fold_open = "\u{F0D7}", done = "\u{2713}" },
    view = {
      -- Reviewing a branch is a read, so stay in a plain 2-way diff rather than
      -- dropping into the 3-way merge layout on conflicted files.
      default = { winbar_info = true, layout = "diff2_horizontal" },
      file_history = { winbar_info = true, layout = "diff2_horizontal" },
    },
    file_panel = {
      -- A tree with single-child dirs collapsed: this monorepo buries files
      -- under service/internal/core/..., which a flat list renders unreadable.
      listing_style = "tree",
      tree_options = { flatten_dirs = true, folder_statuses = "only_folded" },
      win_config = { position = "left", width = 40 },
    },
    file_history_panel = { win_config = { position = "bottom", height = 14 } },
    hooks = {
      -- Diff buffers are for reading: drop the writing-mode furniture that
      -- fights with the highlights (listchars, folds, relative numbers).
      diff_buf_read = function(bufnr)
        vim.opt_local.list = false
        vim.opt_local.wrap = false
        vim.opt_local.foldenable = false
        vim.opt_local.relativenumber = false
        vim.opt_local.cursorline = true
        vim.b[bufnr].minidiff_disable = true
      end,
      -- Diffview re-derives its own groups when a view opens, so win them back.
      view_opened = diff_highlights,
    },
    keymaps = {
      view = { { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close diffview" } } },
      file_panel = { { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close diffview" } } },
    },
  })

  -- After setup, not before: setup() derives DiffviewDiffAddAsDelete from
  -- DiffDelete and would overwrite these. The autocmd is registered after
  -- diffview's own ColorScheme handler for the same reason -- last one wins.
  diff_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("diffview_hl", { clear = true }),
    callback = diff_highlights,
  })
end

-- Stubs so `:DiffviewOpen <rev>` works from a cold start: each loads the plugin,
-- which defines the real command over the top of the stub, then replays the
-- same arguments into it.
for _, diffview_cmd in ipairs({
  "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose",
  "DiffviewToggleFiles", "DiffviewFocusFiles", "DiffviewRefresh",
}) do
  vim.api.nvim_create_user_command(diffview_cmd, function(cmd)
    lazy_require("diffview", diffview_specs, diffview_setup)
    vim.cmd(diffview_cmd .. " " .. cmd.args)
  end, { nargs = "*", desc = "Diffview: " .. diffview_cmd })
end

lazy_keymap("n", "<leader>gd", "diffview", diffview_specs, diffview_setup,
  function() vim.cmd.DiffviewOpen() end, { desc = "Diffview: working tree" })
-- origin/HEAD is whatever the remote calls its default branch (qa here, main
-- elsewhere), so this reviews the current branch exactly as the PR shows it.
lazy_keymap("n", "<leader>gr", "diffview", diffview_specs, diffview_setup,
  function() vim.cmd("DiffviewOpen origin/HEAD...HEAD") end, { desc = "Diffview: review branch vs default" })
lazy_keymap("n", "<leader>gh", "diffview", diffview_specs, diffview_setup,
  function() vim.cmd("DiffviewFileHistory %") end, { desc = "Diffview: history of this file" })

-- Start screen (mini.starter) — shown on `nvim` with no file arguments.
-- Reuses telescope (`tb`) and lazygit (`open_lazygit`) lazy-loaders so the
-- welcome screen itself stays cheap.
local starter = require("mini.starter")
starter.setup({
  header = [[
    ███╗   ██╗██╗   ██╗██╗███╗   ███╗
    ████╗  ██║██║   ██║██║████╗ ████║
    ██╔██╗ ██║██║   ██║██║██╔████╔██║
    ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║
    ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║
    ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝
  ]],
  items = {
    { name = "Find files", action = tb("find_files"), section = "Search" },
    { name = "Search text", action = tb("live_grep"), section = "Search" },
    starter.sections.recent_files(8, true),
    { name = "Lazygit", action = open_lazygit, section = "Tools" },
    starter.sections.builtin_actions(),
  },
  footer = [[Type to filter · <CR> open · <Esc> reset · <C-c> close]],
  content_hooks = {
    starter.gen_hook.adding_bullet("▍ ", false),
    starter.gen_hook.aligning("center", "center"),
  },
})

-- Debugging (nvim-dap + nvim-dap-view). Loaded on the first debug keypress,
-- never at startup. dap-view is a single bottom panel (scopes/breakpoints/
-- watches/repl as tabs) that opens with the session and closes with it
-- (auto_toggle); ad-hoc inspection goes through dap.ui.widgets hover instead
-- of any always-on panel.
local dap_specs = {
  gh("mfussenegger/nvim-dap"),
  gh("igorlfs/nvim-dap-view"),
}

local function dap_setup()
  local dap = require("dap")
  require("dap-view").setup({ auto_toggle = true })

  -- Go: delve comes from the Nix flake (devPackages), not mason.
  dap.adapters.go = {
    type = "server",
    port = "${port}",
    executable = { command = "dlv", args = { "dap", "-l", "127.0.0.1:${port}" } },
  }
  dap.configurations.go = {
    { type = "go", name = "Debug package", request = "launch", program = "${fileDirname}" },
    { type = "go", name = "Debug test (package)", request = "launch", mode = "test", program = "${fileDirname}" },
    {
      type = "go",
      name = "Attach to process",
      request = "attach",
      mode = "local",
      processId = function() return require("dap.utils").pick_process() end,
    },
  }

  -- JS/TS: js-debug-adapter from mason.
  local js_debug = vim.fn.stdpath("data") .. "/mason/bin/js-debug-adapter"
  if vim.fn.executable(js_debug) == 0 then
    vim.notify("js-debug-adapter missing — run :MasonToolsInstall", vim.log.levels.WARN)
  end
  dap.adapters["pwa-node"] = {
    type = "server",
    host = "localhost",
    port = "${port}",
    executable = { command = js_debug, args = { "${port}" } },
  }
  for _, ft in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
    dap.configurations[ft] = {
      {
        type = "pwa-node",
        name = "Launch current file (node)",
        request = "launch",
        program = "${file}",
        cwd = "${workspaceFolder}",
      },
      {
        type = "pwa-node",
        name = "Attach (--inspect, :9229)",
        request = "attach",
        processId = function() return require("dap.utils").pick_process() end,
        cwd = "${workspaceFolder}",
      },
    }
  end

  -- Java: the adapter is served BY jdtls (java-debug bundle, wired in
  -- lsp/jdtls.lua). Ask the running jdtls for a debug port, then connect.
  dap.adapters.java = function(callback)
    local client = vim.lsp.get_clients({ name = "jdtls" })[1]
    if not client then
      vim.notify("jdtls is not attached — open a Java file in the project first", vim.log.levels.WARN)
      return
    end
    client:request("workspace/executeCommand", { command = "vscode.java.startDebugSession" }, function(err, port)
      if err or not port then
        vim.notify("jdtls could not start a debug session: " .. vim.inspect(err), vim.log.levels.ERROR)
        return
      end
      callback({ type = "server", host = "127.0.0.1", port = port })
    end)
  end
  dap.configurations.java = {
    {
      type = "java",
      request = "attach",
      name = "Attach to JVM (:5005)",
      hostName = "127.0.0.1",
      port = 5005,
    },
  }
end

local function dap_do(fn)
  return function()
    lazy_require("dap", dap_specs, dap_setup)
    require("dap")[fn]()
  end
end
vim.keymap.set("n", "<F5>", dap_do("continue"), { desc = "Debug: continue/start" })
vim.keymap.set("n", "<F10>", dap_do("step_over"), { desc = "Debug: step over" })
vim.keymap.set("n", "<F11>", dap_do("step_into"), { desc = "Debug: step into" })
vim.keymap.set("n", "<S-F11>", dap_do("step_out"), { desc = "Debug: step out" })
vim.keymap.set("n", "<leader>db", dap_do("toggle_breakpoint"), { desc = "Debug: toggle breakpoint" })
vim.keymap.set("n", "<leader>dB", function()
  lazy_require("dap", dap_specs, dap_setup)
  require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "Debug: conditional breakpoint" })
vim.keymap.set("n", "<leader>dq", dap_do("terminate"), { desc = "Debug: terminate session" })
vim.keymap.set("n", "<leader>dd", function()
  lazy_require("dap", dap_specs, dap_setup)
  require("dap-view").toggle()
end, { desc = "Debug: toggle panel" })
vim.keymap.set("n", "<leader>dk", function()
  lazy_require("dap", dap_specs, dap_setup)
  require("dap.ui.widgets").hover()
end, { desc = "Debug: inspect symbol" })

-- REST client (kulala.nvim). Requests live in plain .http files; the plugin
-- loads on the first http buffer and never otherwise. global_keymaps is
-- disabled so only the explicit buffer-local maps below apply.
vim.filetype.add({ extension = { http = "http" } })
local kulala_specs = { gh("mistweaverco/kulala.nvim") }
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("kulala-load", { clear = true }),
  pattern = "http",
  callback = function(ev)
    lazy_require("kulala", kulala_specs, function()
      require("kulala").setup({ global_keymaps = false })
    end)
    local function bmap(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = "REST: " .. desc })
    end
    bmap("<CR>", function() require("kulala").run() end, "run request under cursor")
    bmap("]r", function() require("kulala").jump_next() end, "next request")
    bmap("[r", function() require("kulala").jump_prev() end, "previous request")
    bmap("<leader>re", function() require("kulala").set_selected_env() end, "select environment")
  end,
})

-- DB client (vim-dadbod + vim-dadbod-ui). Connections are per-machine
-- secrets: they load from an untracked file, never from this repo.
--   ~/.config/dotfiles/scripts/db-connections.lua  should  `return` a table:
--   return { { name = "local-pg", url = "postgresql://user:pass@localhost:5432/db" } }
local dadbod_specs = {
  gh("tpope/vim-dadbod"),
  { src = gh("kristijanhusak/vim-dadbod-ui"), name = "vim-dadbod-ui" },
}
local function dadbod_setup()
  local conn_file = vim.fn.expand("~/.config/dotfiles/scripts/db-connections.lua")
  if vim.uv.fs_stat(conn_file) then
    local ok, dbs = pcall(dofile, conn_file)
    if ok and type(dbs) == "table" then
      vim.g.dbs = dbs
    else
      vim.notify("db-connections.lua exists but did not return a table", vim.log.levels.ERROR)
    end
  else
    vim.notify("No DB connections configured — create " .. conn_file, vim.log.levels.WARN)
  end
  vim.g.db_ui_use_nerd_fonts = 1
end
lazy_keymap("n", "<leader>du", "dadbod", dadbod_specs, dadbod_setup,
  function() vim.cmd.DBUI() end, { desc = "DB: open UI" })

-- The `main` branch no longer auto-enables highlighting via `highlight = { enable = true }`;
-- start it per buffer for any filetype that has an installed parser.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("treesitter-start", { clear = true }),
  callback = function(ev)
    if vim.b[ev.buf].no_treesitter then return end
    local lang = vim.treesitter.language.get_lang(ev.match)
    if not lang then return end
    -- pcall's first return is only "did it error"; the parser may be absent
    -- without erroring (e.g. Telescope's `TelescopeResults` buffers), so we
    -- must also check `language.add`'s own return before starting.
    local ok, added = pcall(vim.treesitter.language.add, lang)
    if ok and added then
      vim.treesitter.start(ev.buf, lang)
      vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

-- Completion
require("blink.cmp").setup({
  completion = {
    menu = { auto_show = true },
    documentation = { auto_show = true, auto_show_delay_ms = 300 },
  },
  sources = { default = { "lsp", "path", "snippets", "buffer" } },
  cmdline = { enabled = true },
  signature = { enabled = true },
  fuzzy = { implementation = "lua" },
  keymap = {
    preset = "default",
    ["<CR>"] = { "accept", "fallback" },
    ["<Tab>"] = { "select_and_accept", "snippet_forward", "fallback" },
    ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
  },
})

-- Tools
require("mason").setup()
require("mason-tool-installer").setup({
  ensure_installed = {
    "gopls",
    "json-lsp",
    "lua-language-server",
    "rust-analyzer",
    "typescript-language-server",
    "basedpyright",
    "ruff",
    -- DAP adapters (see the Debugging section)
    "java-debug-adapter",
    "js-debug-adapter",
    "codelldb",
    -- Formatting / lint (see conform + lsp/eslint.lua)
    "prettier",
    "eslint-lsp",
  },
  auto_update = false,
  run_on_start = false,
})

-- Rust
vim.g.rustaceanvim = {
  server = {
    default_settings = {
      ["rust-analyzer"] = {
        check = { command = "clippy" },
        cargo = { allFeatures = true },
        procMacro = { enable = true },
      },
    },
  },
  dap = {
    -- codelldb from mason (installed via ensure_installed above), rendered
    -- through the shared dap-view panel like every other adapter.
    adapter = function()
      local mason = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension"
      local liblldb = mason .. "/lldb/lib/liblldb" .. (vim.uv.os_uname().sysname == "Darwin" and ".dylib" or ".so")
      return require("rustaceanvim.config").get_codelldb_adapter(mason .. "/adapter/codelldb", liblldb)
    end,
  },
}

-- LSP
local lsp_configs = {}
for _, f in ipairs(vim.api.nvim_get_runtime_file("lsp/*.lua", true)) do
  table.insert(lsp_configs, vim.fn.fnamemodify(f, ":t:r"))
end
vim.lsp.enable(lsp_configs)

vim.diagnostic.config({
  virtual_text = { spacing = 4, prefix = "●", source = "if_many" },
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = { source = true },
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
  callback = function(event)
    -- Detach from large files rather than stopping the server, which may still
    -- be serving normal buffers.
    if vim.b[event.buf].bigfile then
      vim.schedule(function()
        vim.lsp.buf_detach_client(event.buf, event.data.client_id)
      end)
      return
    end

    -- Drop the semantic-token cache for the heavier servers; treesitter already
    -- handles highlighting, so this is redundant memory per buffer.
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and (client.name == "gopls" or client.name == "ts_ls") then
      client.server_capabilities.semanticTokensProvider = nil
    end

    -- ruff and basedpyright both attach to Python buffers; ruff's hover only
    -- renders rule documentation, so let basedpyright answer K instead.
    if client and client.name == "ruff" then
      client.server_capabilities.hoverProvider = false
    end

    local map = function(keys, func, desc)
      vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
    end
    map("K", vim.lsp.buf.hover, "Hover")
    map("gd", vim.lsp.buf.definition, "Definition")
    map("gD", vim.lsp.buf.declaration, "Declaration")
    map("gr", vim.lsp.buf.references, "References")
    map("gi", vim.lsp.buf.implementation, "Implementation")
    map("gl", vim.diagnostic.open_float, "Line diagnostics")
    map("<leader>la", vim.lsp.buf.code_action, "Code action")
    map("<leader>lr", vim.lsp.buf.rename, "Rename")
  end,
})
