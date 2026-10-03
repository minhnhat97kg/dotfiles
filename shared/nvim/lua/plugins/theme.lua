local U = require("utils")

vim.pack.add({
  { src = U.gh("rebelot/kanagawa.nvim"), name = "kanagawa.nvim" },
  U.gh("echasnovski/mini.nvim"), -- mini.base16, for colors/caelestia.lua
})

require("kanagawa").setup({ theme = "wave" })

-- Transparent bg for the editor and every pane (tool windows, tree, tabline,
-- floats), any colorscheme. Selections/cursorline and popup menus keep their bg.
-- Scheduled so it runs after config/ui.lua's (also scheduled) tool-window pass.
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("transparent-bg", { clear = true }),
  callback = function()
    vim.schedule(function()
      for _, g in ipairs({
        "Normal", "NormalNC", "SignColumn", "LineNr", "FoldColumn", "EndOfBuffer",
        "StatusLine", "StatusLineNC", "WinSeparator", "TabLineFill", "TabLine",
        "NormalFloat", "FloatBorder", "FloatTitle",
        "ToolWindow", "ToolWindowDim", "ToolWindowWinSeparator",
      }) do
        vim.cmd.highlight(g, "guibg=NONE ctermbg=NONE")
      end
      -- was fg=bg=pane to hide the ~ filler; without a bg that fg would show
      vim.api.nvim_set_hl(0, "ToolWindowEndOfBuffer", { link = "EndOfBuffer" })
    end)
  end,
})

local colorscheme_state_file = vim.fn.stdpath("state") .. "/colorscheme"

local saved_colorscheme = vim.fn.filereadable(colorscheme_state_file) == 1
  and vim.fn.readfile(colorscheme_state_file)[1]
-- The desktop theme (shared/theme/theme.nix, via the Caelestia palette) wins
-- wherever it exists; the remembered choice applies elsewhere (e.g. macOS).
if not pcall(vim.cmd.colorscheme, "caelestia")
  and not (saved_colorscheme and pcall(vim.cmd.colorscheme, saved_colorscheme))
then
  vim.cmd.colorscheme("kanagawa")
end

-- Follow the Caelestia shell live: it rewrites its palette on every wallpaper
-- or light/dark change. Watch the directory (not the file) so a replaced file
-- is still seen; the delay lets the write finish before it is read.
local palette_dir = vim.fn.expand("~/.local/state/caelestia")
local watcher = vim.uv.new_fs_event()
if watcher and vim.uv.fs_stat(palette_dir) then
  watcher:start(palette_dir, {}, function(_, fname)
    if fname ~= "scheme.json" then return end
    vim.defer_fn(function()
      if vim.g.colors_name == "caelestia" then pcall(vim.cmd.colorscheme, "caelestia") end
    end, 300)
  end)
end

-- Neovim reads the terminal background (OSC 11) only at startup; ask again on
-- focus so an OS light/dark switch (kitty follows it) flips 'background', which
-- reloads the colorscheme in the matching mode.
vim.api.nvim_create_autocmd("FocusGained", {
  group = vim.api.nvim_create_augroup("refresh-background", { clear = true }),
  callback = function() vim.api.nvim_ui_send("\027]11;?\007") end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("remember-colorscheme", { clear = true }),
  callback = function()
    if vim.g.colors_name then
      vim.fn.writefile({ vim.g.colors_name }, colorscheme_state_file)
    end
  end,
})
