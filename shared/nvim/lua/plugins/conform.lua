local U = require("utils")

local conform_specs = { U.gh("stevearc/conform.nvim") }

local function conform_setup()
  require("conform").setup({
    formatters_by_ft = {
      go = { "gofumpt", "goimports-reviser" },
      javascript = { "prettier" },
      javascriptreact = { "prettier" },
      typescript = { "prettier" },
      typescriptreact = { "prettier" },
      json = { "prettier" },
      lua = { "stylua" },
      python = { "ruff_fix", "ruff_format" },
    },
  })
end

local function conform_format(bufnr, async)
  U.lazy_require("conform", conform_specs, conform_setup)
  require("conform").format({ bufnr = bufnr, async = async, timeout_ms = 500, lsp_format = "fallback" })
end

vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("format-on-save", { clear = true }),
  callback = function(args)
    if vim.g.disable_autoformat or vim.b[args.buf].disable_autoformat then return end
    if vim.b[args.buf].bigfile then return end
    conform_format(args.buf, false)
  end,
})

vim.api.nvim_create_user_command("FormatToggle", function(cmd)
  if cmd.bang then
    vim.b.disable_autoformat = not vim.b.disable_autoformat
    vim.notify("Format-on-save (buffer): " .. (vim.b.disable_autoformat and "off" or "on"))
  else
    vim.g.disable_autoformat = not vim.g.disable_autoformat
    vim.notify("Format-on-save (global): " .. (vim.g.disable_autoformat and "off" or "on"))
  end
end, { bang = true, desc = "Toggle format-on-save" })

vim.keymap.set("n", "<leader>lf", function()
  local ft = vim.bo.filetype
  if (ft == "json" or ft == "jsonc") and vim.b.bigfile and vim.fn.executable("jq") == 1 then
    local view = vim.fn.winsaveview()
    vim.cmd("silent keepjumps %!jq .")
    if vim.v.shell_error ~= 0 then
      vim.cmd("silent undo")
      vim.notify("jq failed (invalid JSON, or comments in jsonc)", vim.log.levels.ERROR)
    end
    vim.fn.winrestview(view)
  else
    conform_format(0, true)
  end
end, { desc = "Format buffer" })
