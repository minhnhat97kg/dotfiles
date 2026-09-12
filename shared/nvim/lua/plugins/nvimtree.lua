local U = require("utils")

local nvim_tree_specs = {
  { src = U.gh("nvim-tree/nvim-tree.lua"), name = "nvim-tree.lua" },
  { src = U.gh("nvim-tree/nvim-web-devicons"), name = "nvim-web-devicons" },
}

local function nvim_tree_setup()
  require("nvim-tree").setup({
    sort = { sorter = "case_sensitive" },
    view = { width = 32 },
    renderer = {
      group_empty = true,
      icons = { show = { git = false } },
    },
    filters = { dotfiles = false },
    on_attach = function(bufnr)
      local api = require("nvim-tree.api")
      api.config.mappings.default_on_attach(bufnr)
      vim.keymap.set("n", "<LeftRelease>", function()
        if api.tree.get_node_under_cursor() then api.node.open.edit() end
      end, { buffer = bufnr, desc = "nvim-tree: open on single click" })
    end,
  })
end

U.lazy_keymap("n", "<leader>e", "nvim-tree", nvim_tree_specs, nvim_tree_setup,
  function() vim.cmd.NvimTreeToggle() end, { desc = "Toggle file tree" })
U.lazy_keymap("n", "<leader>E", "nvim-tree", nvim_tree_specs, nvim_tree_setup,
  function() vim.cmd.NvimTreeFindFile() end, { desc = "Reveal current file" })
