return {
  cmd = { "vscode-json-language-server", "--stdio" },
  filetypes = { "json", "jsonc" },
  root_markers = { ".git" },
  -- The server ships a formatter but keeps it off unless asked, so
  -- `vim.lsp.buf.format` (<leader>lf) would silently do nothing without this.
  init_options = { provideFormatter = true },
  settings = {
    json = {
      validate = { enable = true },
    },
  },
}
