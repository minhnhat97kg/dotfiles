-- opencode.nvim — OpenCode integration inside Neovim
-- Defaults are sensible; only override what you care about.

---@type opencode.Opts
vim.g.opencode_opts = {
  -- Connect to an already-running `opencode --port` server when possible.
  -- If none is found, opencode.nvim can start one via the configured
  -- server.start function (defaults to `term://opencode --port`).
  server = {
    connect = true,
  },
}

-- Recommended/example keymaps from the plugin README.
-- Note: <C-a>/<C-x> are reused here; increment/decrement are still available
-- via <leader>a and <leader>x from config/keymaps.lua.

vim.keymap.set({ "n", "x" }, "<C-a>", function() require("opencode").ask("@this: ") end,
  { desc = "Ask OpenCode…" })

vim.keymap.set({ "n", "x" }, "<C-x>", function() require("opencode").select() end,
  { desc = "Select OpenCode…" })

vim.keymap.set({ "n", "x" }, "go", function() return require("opencode").operator("@this ") end,
  { desc = "Append range to OpenCode", expr = true })

vim.keymap.set({ "n" }, "goo", function() return require("opencode").operator("@this ") .. "_" end,
  { desc = "Append line to OpenCode", expr = true })

vim.keymap.set({ "n" }, "<S-C-u>", function() require("opencode").command("session.half.page.up") end,
  { desc = "Scroll OpenCode up" })

vim.keymap.set({ "n" }, "<S-C-d>", function() require("opencode").command("session.half.page.down") end,
  { desc = "Scroll OpenCode down" })
