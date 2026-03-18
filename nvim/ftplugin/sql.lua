-- SQL filetype configuration for vim-dadbod-completion
-- This ensures database autocomplete works properly with vim-dadbod

-- vim-dadbod-completion sets up omnifunc automatically
-- We ensure it's configured correctly
vim.opt_local.omnifunc = "vim_dadbod_completion#omni"

-- Configure completion options for SQL
vim.opt_local.completeopt = "menu,menuone,noselect"

-- Keymap for triggering database completion manually
-- Use <C-Space> to trigger omni-completion for tables, columns, etc.
vim.keymap.set("i", "<C-Space>", "<C-x><C-o>", {
  buffer = true,
  desc = "Trigger database completion",
})

-- Auto-trigger completion on dot (for table.column)
-- This creates a seamless autocomplete experience
vim.api.nvim_create_autocmd("InsertCharPre", {
  buffer = 0,
  callback = function()
    local char = vim.v.char
    if char == "." then
      -- Trigger omni-completion after typing a dot
      vim.defer_fn(function()
        local keys = vim.api.nvim_replace_termcodes("<C-x><C-o>", true, false, true)
        vim.api.nvim_feedkeys(keys, "n", false)
      end, 1)
    end
  end,
})

-- Additional SQL-specific settings
vim.opt_local.commentstring = "-- %s"
vim.opt_local.formatoptions:append("croql")
