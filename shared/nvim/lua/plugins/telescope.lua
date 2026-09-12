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
  local themes = require("telescope.themes")
  telescope.setup({
    defaults = {
      layout_strategy = "flex",
      layout_config = {
        height = 0.95,
        prompt_position = "top",
        horizontal = { preview_width = 0.55 },
        flex = { flip_columns = 140 },
      },
      sorting_strategy = "ascending",
      path_display = { "filename_first" },
      dynamic_preview_title = true,
      prompt_prefix = "   ",
      selection_caret = "  ",
      entry_prefix = "   ",
      multi_icon = " ",
      borderchars = {
        prompt = { "─", "│", "─", "│", "╭", "╮", "┤", "├" },
        results = { "─", "│", "─", "│", "├", "┤", "╯", "╰" },
        preview = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
      },
      winblend = 0,
    },
    pickers = {
      buffers = themes.get_ivy({ previewer = false, sort_mru = true }),
      keymaps = themes.get_ivy({ previewer = false }),
      diagnostics = themes.get_ivy(),
      colorscheme = themes.get_dropdown({ previewer = false }),
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
