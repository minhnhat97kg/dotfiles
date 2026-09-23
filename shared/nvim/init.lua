-- Minimal Neovim config: Go / Rust / React(JS/TS) / Lua

assert(vim.fn.has("nvim-0.12") == 1, "This config requires Neovim 0.12+")

local U = require("utils")

-- Plugins with no setup() call — just need to be on disk
vim.pack.add({
  U.gh("christoomey/vim-tmux-navigator"),
  { src = U.gh("nvzone/volt"), name = "volt" },
  { src = U.gh("nvzone/menu"), name = "menu" },
  { src = U.gh("nickjvandyke/opencode.nvim"), version = vim.version.range("*") },
  U.gh("pablopunk/pi.nvim"),
  U.gh("nvim-lua/plenary.nvim"),
  { src = U.gh("olimorris/codecompanion.nvim"), version = vim.version.range("^19.0.0") },
})

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.ui")

require("plugins.theme")
require("plugins.mini")
require("plugins.treesitter")
require("plugins.completion")
require("plugins.lsp")
require("plugins.quicker")
require("plugins.rendermarkdown")
require("plugins.git")
require("plugins.telescope")
require("plugins.nvimtree")
require("plugins.debug")
require("plugins.conform")
require("plugins.rest")
require("plugins.db")
require("plugins.whichkey")
require("plugins.opencode")
require("plugins.pi")
require("plugins.codecompanion")
