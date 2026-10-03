local U = require("utils")

vim.pack.add({ U.gh("folke/snacks.nvim") })

-- Only modules that don't overlap with what's already here: telescope is the
-- picker, nvim-tree the explorer, lazygit.nvim the lazygit float.
require("snacks").setup({
  bigfile = { enabled = true },   -- drop treesitter/LSP on huge files
  quickfile = { enabled = true }, -- render the file before plugins finish loading
  indent = { enabled = true },    -- indent guides + current scope
  input = { enabled = true },     -- nicer vim.ui.input (LSP rename, etc.)
  notifier = { enabled = true },  -- vim.notify as floating notifications
  words = { enabled = true },     -- highlight LSP references under the cursor
})
