local U = require("utils")

-- ============================================================================
-- Tool window theme
-- ============================================================================
local function hl_bg(name)
  local ok, spec = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  return ok and spec.bg or nil
end

local function hl_fg(name)
  local ok, spec = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  return ok and spec.fg or nil
end

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
    if not editor_bg then return end
    pane = shade(editor_bg, vim.o.background == "dark" and 1.28 or 0.97)
  end
  local sel = shade(pane, vim.o.background == "dark" and 1.32 or 0.94)

  vim.api.nvim_set_hl(0, "ToolWindow", { bg = pane, fg = hl_fg("Normal") })
  vim.api.nvim_set_hl(0, "ToolWindowCursorLine", { bg = sel })
  local dim = hl_fg("Comment")
  vim.api.nvim_set_hl(0, "ToolWindowDim", {
    bg = pane,
    fg = dim and shade(dim, vim.o.background == "dark" and 1.22 or 0.76) or nil,
  })

  package.loaded["volt.highlights"] = nil
  pcall(require, "volt.highlights")
  vim.api.nvim_set_hl(0, "ExLightGrey", { fg = hl_fg("Normal") })
  vim.api.nvim_set_hl(0, "CommentFg", { fg = hl_fg("Comment") })
  vim.api.nvim_set_hl(0, "ExRed", { fg = hl_fg("DiagnosticError") })
  vim.api.nvim_set_hl(0, "ExYellow", { fg = hl_fg("DiagnosticWarn") })
  vim.api.nvim_set_hl(0, "ExBlue", { fg = hl_fg("Function") })
  vim.api.nvim_set_hl(0, "ExGreen", { fg = hl_fg("String") })
  vim.api.nvim_set_hl(0, "ToolWindowEndOfBuffer", { fg = pane, bg = pane })
  vim.api.nvim_set_hl(0, "ToolWindowWinSeparator", {
    fg = (vim.api.nvim_get_hl(0, { name = "WinSeparator", link = false }) or {}).fg,
    bg = pane,
  })

  for _, group in ipairs({
    "NvimTreeNormal", "NvimTreeNormalNC", "NvimTreeSignColumn",
    "NvimTreeLineNr", "NvimTreeStatusLine", "NvimTreeStatuslineNC",
  }) do
    vim.api.nvim_set_hl(0, group, { link = "ToolWindow" })
  end
  vim.api.nvim_set_hl(0, "TabLineFill", { bg = pane })
  vim.api.nvim_set_hl(0, "TabLine", { bg = pane, fg = hl_fg("Normal") })
  vim.api.nvim_set_hl(0, "TabLineSel", { bg = sel, fg = hl_fg("Normal"), bold = true })

  vim.api.nvim_set_hl(0, "NvimTreeEndOfBuffer", { link = "ToolWindowEndOfBuffer" })
  vim.api.nvim_set_hl(0, "NvimTreeCursorLine", { link = "ToolWindowCursorLine" })
  vim.api.nvim_set_hl(0, "NvimTreeWinSeparator", { link = "ToolWindowWinSeparator" })
  vim.api.nvim_set_hl(0, "NvimTreeVisual", { bg = sel })
  vim.api.nvim_set_hl(0, "NvimTreeVisualLine", { bg = sel })
  vim.api.nvim_set_hl(0, "NvimTreeVisualLineNC", { bg = sel })

  for _, group in ipairs({
    "NvimTreeGitDirty", "NvimTreeGitNew", "NvimTreeGitDeleted",
    "NvimTreeGitStaged", "NvimTreeGitRenamed", "NvimTreeGitIgnored",
    "NvimTreeGitMerge", "NvimTreeGitUntracked",
  }) do
    local existing = vim.api.nvim_get_hl(0, { name = group, link = false })
    if existing and (existing.underline or existing.undercurl or existing.underdotted) then
      existing.underline = false
      existing.undercurl = false
      existing.underdotted = false
      existing.sp = nil
      vim.api.nvim_set_hl(0, group, existing)
    end
  end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("tool-window-theme", { clear = true }),
  callback = function() vim.schedule(apply_tool_window_theme) end,
})
apply_tool_window_theme()

local tool_window_panes = vim.api.nvim_create_augroup("tool-window-panes", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = tool_window_panes,
  pattern = { "qf", "help", "dbui", "dbout", "dbui-drawer" },
  callback = function() vim.wo.winhighlight = tool_window_winhl end,
})

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

-- ============================================================================
-- Action bar
-- ============================================================================
local action_bar = {
  { icon = "\u{F0645}", label = "File tree",   keys = "<leader>e" },
  { icon = "\u{F021E}", label = "Find file",   keys = "<leader>sf" },
  { icon = "\u{F13B8}", label = "Grep",        keys = "<leader>sg" },
  { icon = "\u{F0279}", label = "Symbols",     keys = "<leader>ss" },
  { icon = "\u{F05D6}", label = "Diagnostics", keys = "<leader>q" },
  { icon = "\u{E702}",  label = "Git",         keys = "<leader>gg" },
  { icon = "\u{F062C}", label = "Commit graph", keys = "<leader>gl" },
  { icon = "\u{F018D}", label = "Terminal",    keys = "<leader>tt" },
  { icon = "\u{F00E4}", label = "Debug",       keys = "<F5>" },
}

vim.keymap.set("n", "<leader>m", function()
  local entries = {}
  for _, action in ipairs(action_bar) do
    entries[#entries + 1] = { action.icon .. "  " .. action.label, action.keys }
  end
  U.menu_open(entries)
end, { desc = "Action bar" })

-- ============================================================================
-- Context menu (right-click)
-- ============================================================================
vim.o.mouse = "a"
vim.o.mousescroll = "ver:1,hor:4"

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
  { "Open in Browser", "gx" },
  { "Inspect Highlight", "<Cmd>Inspect<CR>" },
}

pcall(vim.cmd, "aunmenu PopUp")
vim.keymap.set("n", "<RightMouse>", function()
  local pos = vim.fn.getmousepos()
  if pos.winid ~= 0 and pos.line > 0 then
    pcall(vim.api.nvim_set_current_win, pos.winid)
    pcall(vim.api.nvim_win_set_cursor, pos.winid, { pos.line, math.max(pos.column - 1, 0) })
  end
  U.menu_open(context_menu, { mouse = true })
end, { desc = "Context menu" })

-- ============================================================================
-- Mouse hover diagnostics
-- ============================================================================
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
    if pos.winid == 0 or pos.line == 0 then
      close_hover()
      return
    end
    local key = pos.winid .. ":" .. pos.line
    if key == hover_key then return end
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
