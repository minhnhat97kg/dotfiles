local U = require("utils")

vim.pack.add({ { src = U.gh("stevearc/quicker.nvim"), name = "quicker.nvim" } })

require("quicker").setup({
  opts = { number = false, wrap = false, winfixheight = true },
  edit = { enabled = true, autosave = "unmodified" },
  highlight = { treesitter = true, lsp = true },
  trim_leading_whitespace = "common",
  max_filename_width = function() return math.floor(math.min(60, vim.o.columns / 3)) end,
  keys = {
    { ">", function() require("quicker").expand({ before = 2, after = 2 }) end,
      desc = "Expand quickfix context" },
    { "<", function() require("quicker").collapse() end,
      desc = "Collapse quickfix context" },
  },
})
