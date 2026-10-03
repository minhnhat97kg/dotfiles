local U = require("utils")

-- nvim-treesitter-textobjects ships the @function.outer/@class.outer query
-- captures that mini.ai's treesitter text objects (af/if, ac/ic below) need.
vim.pack.add({ U.gh("echasnovski/mini.nvim"), U.gh("nvim-treesitter/nvim-treesitter-textobjects") })

require("mini.ai").setup({
  n_lines = 500,
  custom_textobjects = {
    f = require("mini.ai").gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
    c = require("mini.ai").gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
  },
})
require("mini.surround").setup()

require("mini.statusline").setup({
  use_icons = vim.g.have_nerd_font,
})

require("mini.sessions").setup({
  directory = vim.fn.stdpath("state") .. "/sessions",
  file = "Session.vim",
})

-- Show colour codes in their own colour: #rrggbb hex everywhere (css, lua,
-- kdl, nix…). LSP colours (css, tailwind) come from Neovim 0.12's built-in
-- vim.lsp.document_color.
local hipatterns = require("mini.hipatterns")
hipatterns.setup({
  highlighters = { hex_color = hipatterns.gen_highlighter.hex_color() },
})
