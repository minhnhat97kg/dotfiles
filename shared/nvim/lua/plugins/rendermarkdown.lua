local U = require("utils")

vim.pack.add({ U.gh("MeanderingProgrammer/render-markdown.nvim") })

require("render-markdown").setup({
  completions = { lsp = { enabled = true } },
})

vim.keymap.set("n", "<leader>tm", "<cmd>RenderMarkdown toggle<CR>", { desc = "Toggle markdown render" })
