local U = require("utils")

vim.pack.add({
  U.gh("mrcjkb/rustaceanvim"),
  U.gh("williamboman/mason.nvim"),
  { src = U.gh("WhoIsSethDaniel/mason-tool-installer.nvim"), name = "mason-tool-installer.nvim" },
})

-- Rust
vim.g.rustaceanvim = {
  server = {
    default_settings = {
      ["rust-analyzer"] = {
        check = { command = "clippy" },
        cargo = { allFeatures = true },
        procMacro = { enable = true },
      },
    },
  },
  dap = {
    adapter = function()
      local mason = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension"
      local liblldb = mason .. "/lldb/lib/liblldb" .. (vim.uv.os_uname().sysname == "Darwin" and ".dylib" or ".so")
      return require("rustaceanvim.config").get_codelldb_adapter(mason .. "/adapter/codelldb", liblldb)
    end,
  },
}

-- Mason
require("mason").setup()
require("mason-tool-installer").setup({
  ensure_installed = {
    "gopls", "json-lsp", "lua-language-server", "rust-analyzer",
    "typescript-language-server", "basedpyright", "ruff",
    "java-debug-adapter", "js-debug-adapter", "codelldb",
    "prettier", "eslint-lsp",
  },
  auto_update = false,
  run_on_start = false,
})

-- LSP
local lsp_configs = {}
for _, f in ipairs(vim.api.nvim_get_runtime_file("lsp/*.lua", true)) do
  table.insert(lsp_configs, vim.fn.fnamemodify(f, ":t:r"))
end
vim.lsp.enable(lsp_configs)

vim.diagnostic.config({
  virtual_text = { spacing = 4, prefix = "●", source = "if_many" },
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = { source = true },
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
  callback = function(event)
    if vim.b[event.buf].bigfile then
      vim.schedule(function()
        vim.lsp.buf_detach_client(event.buf, event.data.client_id)
      end)
      return
    end

    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and (client.name == "gopls" or client.name == "ts_ls") then
      client.server_capabilities.semanticTokensProvider = nil
    end

    if client and client.name == "ruff" then
      client.server_capabilities.hoverProvider = false
    end

    if client and client.server_capabilities.hoverProvider then
      for _, other in ipairs(vim.lsp.get_clients({ bufnr = event.buf })) do
        if other.id ~= client.id and other.server_capabilities.hoverProvider then
          client.server_capabilities.hoverProvider = false
          break
        end
      end
    end

    local map = function(keys, func, desc)
      vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
    end
    map("K", vim.lsp.buf.hover, "Hover")
    map("gd", vim.lsp.buf.definition, "Definition")
    map("gD", vim.lsp.buf.declaration, "Declaration")
    map("gr", vim.lsp.buf.references, "References")
    map("gi", vim.lsp.buf.implementation, "Implementation")
    map("gl", vim.diagnostic.open_float, "Line diagnostics")
    map("<leader>la", vim.lsp.buf.code_action, "Code action")
    map("<leader>lr", vim.lsp.buf.rename, "Rename")
  end,
})
