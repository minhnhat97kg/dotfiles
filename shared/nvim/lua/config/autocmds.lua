-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
  callback = function() vim.highlight.on_yank() end,
})

-- Large files: two tiers
local BIGFILE_BYTES = 1024 * 1024
local NO_TREESITTER_BYTES = 10 * 1024 * 1024
vim.api.nvim_create_autocmd("BufReadPre", {
  group = vim.api.nvim_create_augroup("bigfile", { clear = true }),
  callback = function(ev)
    local st = vim.uv.fs_stat(vim.api.nvim_buf_get_name(ev.buf))
    if not st or st.size < BIGFILE_BYTES then return end
    vim.b[ev.buf].bigfile = true
    vim.b[ev.buf].no_treesitter = st.size >= NO_TREESITTER_BYTES
    vim.bo[ev.buf].undofile = false
    vim.bo[ev.buf].swapfile = false
    vim.bo[ev.buf].synmaxcol = 200
  end,
})

-- Tool windows: q to close
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("tool-window-close", { clear = true }),
  pattern = { "gitgraph", "qf", "dap-view", "dap-view-term", "dap-repl", "help" },
  callback = function(ev)
    vim.keymap.set("n", "q", "<Cmd>close<CR>", { buffer = ev.buf, desc = "Close tool window" })
  end,
})

vim.api.nvim_create_autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("terminal-close", { clear = true }),
  callback = function(ev)
    vim.keymap.set("n", "q", "<Cmd>close<CR>", { buffer = ev.buf, desc = "Close terminal" })
  end,
})
