local U = require("utils")

vim.pack.add({ U.gh("echasnovski/mini.nvim") })

require("mini.ai").setup({ n_lines = 500 })
require("mini.surround").setup()

require("mini.statusline").setup({
  use_icons = vim.g.have_nerd_font,
})

require("mini.sessions").setup({
  directory = vim.fn.stdpath("state") .. "/sessions",
  file = "Session.vim",
})
