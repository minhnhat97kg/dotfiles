local U = require("utils")

local telescope_specs = {
  U.gh("nvim-lua/plenary.nvim"),
  U.gh("nvim-telescope/telescope.nvim"),
  { src = U.gh("nvim-telescope/telescope-fzf-native.nvim"), name = "telescope-fzf-native.nvim" },
}

vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    if ev.data.spec.name == "telescope-fzf-native.nvim" and (ev.data.kind == "install" or ev.data.kind == "update") then
      vim.system({ "make" }, { cwd = ev.data.path })
    end
  end,
})

local function telescope_setup()
  local telescope = require("telescope")
  telescope.setup({
    pickers = {
      buffers = { sort_mru = true },
    },
  })
  pcall(telescope.load_extension, "fzf")
end

local function tb(name, opts)
  return function()
    U.lazy_require("telescope", telescope_specs, telescope_setup)
    require("telescope.builtin")[name](opts)
  end
end

vim.keymap.set("n", "<leader>sf", tb("find_files"), { desc = "Search files" })
vim.keymap.set("n", "<leader>sg", tb("live_grep"), { desc = "Search grep" })
vim.keymap.set("n", "<leader>sw", tb("grep_string"), { desc = "Search word" })
vim.keymap.set("n", "<leader>sb", tb("buffers"), { desc = "Search buffers" })
vim.keymap.set("n", "<leader>sh", tb("help_tags"), { desc = "Search help" })
vim.keymap.set("n", "<leader><leader>", tb("buffers"), { desc = "Buffers" })
vim.keymap.set("n", "<leader>sd", tb("diagnostics"), { desc = "Search diagnostics (project)" })
vim.keymap.set("n", "<leader>ss", tb("lsp_document_symbols"), { desc = "Search symbols (file outline)" })
vim.keymap.set("n", "<leader>sS", tb("lsp_workspace_symbols"), { desc = "Search symbols (workspace)" })
vim.keymap.set("n", "<leader>sk", tb("keymaps"), { desc = "Search keymaps" })
vim.keymap.set("n", "<leader>sc", tb("git_bcommits"), { desc = "Search commits touching this file" })
vim.keymap.set("n", "<leader>st", tb("colorscheme", { enable_preview = true }), { desc = "Pick colorscheme (live preview)" })
