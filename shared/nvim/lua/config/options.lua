vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true

for _, p in ipairs({ "perl", "ruby", "node", "python3" }) do
  vim.g["loaded_" .. p .. "_provider"] = 0
end

vim.opt.number = true
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true
vim.opt.scrolloff = 8
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.showmode = false
vim.opt.termguicolors = true
vim.opt.updatetime = 300
vim.opt.timeoutlen = 300
vim.opt.undofile = true
vim.opt.swapfile = false
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.smartindent = true
vim.opt.completeopt = "menu,menuone,noselect,popup"
vim.opt.winborder = "rounded"
vim.opt.modeline = false
vim.opt.list = true
vim.opt.listchars = { tab = "| ", trail = "·", nbsp = "␣" }

vim.schedule(function()
  vim.opt.clipboard = "unnamedplus"
end)
