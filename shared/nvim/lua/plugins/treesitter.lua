local U = require("utils")

vim.pack.add({ U.gh("nvim-treesitter/nvim-treesitter") })

vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == "nvim-treesitter" and (kind == "install" or kind == "update") then
      vim.schedule(function() pcall(vim.cmd, "TSUpdate") end)
    end
  end,
})

require("nvim-treesitter").setup()
require("nvim-treesitter").install({
  "bash", "go", "gomod", "gosum", "gowork", "java", "javascript", "typescript", "tsx",
  "json", "lua", "luadoc", "markdown", "markdown_inline", "python", "rust", "toml", "vim", "vimdoc",
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("treesitter-start", { clear = true }),
  callback = function(ev)
    if vim.b[ev.buf].no_treesitter then return end
    local lang = vim.treesitter.language.get_lang(ev.match)
    if not lang then return end
    local ok, added = pcall(vim.treesitter.language.add, lang)
    if ok and added then
      vim.treesitter.start(ev.buf, lang)
      vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})
