local U = require("utils")

vim.pack.add({
  { src = U.gh("navarasu/onedark.nvim"), name = "onedark.nvim" },
})

require("onedark").setup({ style = "darker" })
local colorscheme_state_file = vim.fn.stdpath("state") .. "/colorscheme"

local saved_colorscheme = vim.fn.filereadable(colorscheme_state_file) == 1
  and vim.fn.readfile(colorscheme_state_file)[1]
if not (saved_colorscheme and pcall(vim.cmd.colorscheme, saved_colorscheme)) then
  vim.cmd.colorscheme("onedark")
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("remember-colorscheme", { clear = true }),
  callback = function()
    if vim.g.colors_name then
      vim.fn.writefile({ vim.g.colors_name }, colorscheme_state_file)
    end
  end,
})
