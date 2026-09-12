vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("n", ";", ":", { desc = "Command mode" })
vim.keymap.set("i", "kj", "<Esc>")
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostics list" })
vim.keymap.set("n", "<leader>tt", "<Cmd>botright 15split | terminal<CR>", { desc = "Terminal" })

-- Ctrl-free aliases for iPad software keyboard
for _, alias in ipairs({
  { "r", "<C-r>", "Redo" },
  { "o", "<C-o>", "Jump back" },
  { "i", "<C-i>", "Jump forward" },
  { "j", "<C-d>", "Half page down" },
  { "k", "<C-u>", "Half page up" },
  { "a", "<C-a>", "Increment number" },
  { "x", "<C-x>", "Decrement number" },
  { "b", "<C-^>", "Alternate buffer" },
  { "v", "<C-v>", "Blockwise visual" },
}) do
  vim.keymap.set("n", "<leader>" .. alias[1], alias[2], { desc = alias[3] })
end

-- <leader>w stands in for the <C-w> window prefix
for key, spec in pairs({
  h = { "<Cmd>TmuxNavigateLeft<CR>", "Window/pane left" },
  j = { "<Cmd>TmuxNavigateDown<CR>", "Window/pane down" },
  k = { "<Cmd>TmuxNavigateUp<CR>", "Window/pane up" },
  l = { "<Cmd>TmuxNavigateRight<CR>", "Window/pane right" },
  s = { "<Cmd>split<CR>", "Split horizontal" },
  v = { "<Cmd>vsplit<CR>", "Split vertical" },
  c = { "<Cmd>close<CR>", "Close window" },
  o = { "<Cmd>only<CR>", "Only this window" },
  ["="] = { "<C-w>=", "Equalise windows" },
  H = { "<C-w>H", "Move window far left" },
  J = { "<C-w>J", "Move window far down" },
  K = { "<C-w>K", "Move window far up" },
  L = { "<C-w>L", "Move window far right" },
  x = { "<C-w>x", "Swap with next window" },
  r = { "<C-w>r", "Rotate windows" },
  t = { "<C-w>T", "Break window out to a new tab" },
}) do
  vim.keymap.set("n", "<leader>w" .. key, spec[1], { desc = spec[2] })
end

-- Window resize submode
vim.keymap.set("n", "<leader>wz", function()
  local step = {
    h = "vertical resize -3",
    l = "vertical resize +3",
    j = "resize -2",
    k = "resize +2",
  }
  while true do
    vim.api.nvim_echo({ { "-- RESIZE --  h/l width  j/k height  (any other key exits)", "ModeMsg" } },
      false, {})
    local ok, ch = pcall(vim.fn.getcharstr)
    local cmd = ok and step[ch]
    if not cmd then break end
    pcall(vim.cmd, cmd)
    vim.cmd("redraw")
  end
  vim.api.nvim_echo({ { "" } }, false, {})
end, { desc = "Resize window (submode)" })
