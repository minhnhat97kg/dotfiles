local U = require("utils")

vim.pack.add({
  U.gh("saghen/blink.lib"),
  U.gh("saghen/blink.cmp"),
})

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
