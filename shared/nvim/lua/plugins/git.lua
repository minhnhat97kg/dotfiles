local U = require("utils")

-- Eager: gitsigns
vim.pack.add({ U.gh("lewis6991/gitsigns.nvim") })

require("gitsigns").setup({
  current_line_blame = false,
  on_attach = function(bufnr)
    local gs = require("gitsigns")
    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = "Git: " .. desc })
    end
    map("n", "]h", function()
      if vim.wo.diff then vim.cmd.normal({ "]c", bang = true }) else gs.nav_hunk("next") end
    end, "next hunk")
    map("n", "[h", function()
      if vim.wo.diff then vim.cmd.normal({ "[c", bang = true }) else gs.nav_hunk("prev") end
    end, "previous hunk")
    map("n", "<leader>hs", gs.stage_hunk, "stage hunk")
    map("n", "<leader>hr", gs.reset_hunk, "reset hunk")
    map("v", "<leader>hs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "stage selection")
    map("v", "<leader>hr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "reset selection")
    map("n", "<leader>hS", gs.stage_buffer, "stage buffer")
    map("n", "<leader>hR", gs.reset_buffer, "reset buffer")
    map("n", "<leader>hp", gs.preview_hunk, "preview hunk")
    map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, "blame line")
    map("n", "<leader>htb", gs.toggle_current_line_blame, "toggle line blame")
    map("n", "<leader>hd", gs.diffthis, "diff against index")
  end,
})

-- Lazy: lazygit
local lazygit_specs = {
  { src = U.gh("kdheepak/lazygit.nvim"), name = "lazygit.nvim" },
  U.gh("nvim-lua/plenary.nvim"),
}
local function open_lazygit()
  U.lazy_require("lazygit", lazygit_specs, function() end)
  vim.cmd.LazyGit()
end
U.lazy_keymap("n", "<leader>gg", "lazygit", lazygit_specs, function() end,
  open_lazygit, { desc = "Lazygit" })

-- Lazy: gitgraph
local gitgraph_specs = { { src = U.gh("isakbm/gitgraph.nvim"), name = "gitgraph.nvim" } }
local function gitgraph_setup()
  require("gitgraph").setup({
    symbols = { merge_commit = "●", commit = "○", merge_commit_end = "●", commit_end = "○" },
    format = { timestamp = "%d-%m-%Y", fields = { "hash", "timestamp", "author", "branch_name", "tag" } },
    hooks = {
      on_select_commit = function(commit)
        vim.cmd("DiffviewOpen " .. commit.hash .. "^!")
      end,
      on_select_range_commit = function(from, to)
        vim.cmd(("DiffviewOpen %s~1..%s"):format(from.hash, to.hash))
      end,
    },
  })
end
local function gitgraph_draw(all)
  return function()
    local existing
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "gitgraph" then existing = win end
    end
    if existing then
      vim.api.nvim_set_current_win(existing)
    else
      vim.cmd("botright split")
    end
    require("gitgraph").draw({}, { all = all, max_count = 5000 })
  end
end
U.lazy_keymap("n", "<leader>gl", "gitgraph", gitgraph_specs, gitgraph_setup,
  gitgraph_draw(false), { desc = "Git commit graph" })
U.lazy_keymap("n", "<leader>gL", "gitgraph", gitgraph_specs, gitgraph_setup,
  gitgraph_draw(true), { desc = "Git commit graph (all branches)" })

-- Lazy: diffview
local diffview_specs = {
  U.gh("sindrets/diffview.nvim"),
  U.gh("nvim-lua/plenary.nvim"),
  { src = U.gh("nvim-tree/nvim-web-devicons"), name = "nvim-web-devicons" },
}
local function diffview_setup()
  vim.opt.fillchars:append({ diff = "\u{2571}" })
  local diffopt = vim.tbl_filter(function(opt)
    return not (vim.startswith(opt, "linematch:") or vim.startswith(opt, "algorithm:"))
  end, vim.opt.diffopt:get())
  vim.list_extend(diffopt, { "algorithm:histogram", "linematch:60" })
  vim.opt.diffopt = diffopt

  local function diff_highlights()
    local dark = vim.o.background == "dark"
    local c = dark
      and { add = "#26402f", del = "#45242a", chg = "#2c3f52", txt = "#2f628f", dim = "#3a3f45" }
      or { add = "#ddf4e4", del = "#fbdfe2", chg = "#e3edf7", txt = "#b9d8f5", dim = "#d8dde3" }
    vim.api.nvim_set_hl(0, "DiffAdd", { bg = c.add })
    vim.api.nvim_set_hl(0, "DiffChange", { bg = c.chg })
    vim.api.nvim_set_hl(0, "DiffText", { bg = c.txt, bold = true })
    vim.api.nvim_set_hl(0, "DiffDelete", { fg = c.dim, bg = "NONE" })
    vim.api.nvim_set_hl(0, "DiffviewDiffAddAsDelete", { bg = c.del })
    vim.api.nvim_set_hl(0, "DiffviewDiffDelete", { fg = c.dim, bg = "NONE" })
    vim.api.nvim_set_hl(0, "DiffviewDiffDeleteDim", { fg = c.dim, bg = "NONE" })
  end

  require("diffview").setup({
    enhanced_diff_hl = true,
    signs = { fold_closed = "\u{F0DA}", fold_open = "\u{F0D7}", done = "\u{2713}" },
    view = {
      default = { winbar_info = true, layout = "diff2_horizontal" },
      file_history = { winbar_info = true, layout = "diff2_horizontal" },
    },
    file_panel = {
      listing_style = "tree",
      tree_options = { flatten_dirs = true, folder_statuses = "only_folded" },
      win_config = { position = "left", width = 40 },
    },
    file_history_panel = { win_config = { position = "bottom", height = 14 } },
    hooks = {
      diff_buf_read = function(bufnr)
        vim.opt_local.list = false
        vim.opt_local.wrap = false
        vim.opt_local.foldenable = false
        vim.opt_local.relativenumber = false
        vim.opt_local.cursorline = true
        vim.b[bufnr].minidiff_disable = true
      end,
      view_opened = diff_highlights,
    },
    keymaps = {
      view = { { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close diffview" } } },
      file_panel = { { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close diffview" } } },
    },
  })

  diff_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("diffview_hl", { clear = true }),
    callback = diff_highlights,
  })
end

for _, diffview_cmd in ipairs({
  "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose",
  "DiffviewToggleFiles", "DiffviewFocusFiles", "DiffviewRefresh",
}) do
  vim.api.nvim_create_user_command(diffview_cmd, function(cmd)
    U.lazy_require("diffview", diffview_specs, diffview_setup)
    vim.cmd(diffview_cmd .. " " .. cmd.args)
  end, { nargs = "*", desc = "Diffview: " .. diffview_cmd })
end

U.lazy_keymap("n", "<leader>gd", "diffview", diffview_specs, diffview_setup,
  function() vim.cmd.DiffviewOpen() end, { desc = "Diffview: working tree" })
U.lazy_keymap("n", "<leader>gr", "diffview", diffview_specs, diffview_setup,
  function() vim.cmd("DiffviewOpen origin/HEAD...HEAD") end, { desc = "Diffview: review branch vs default" })
U.lazy_keymap("n", "<leader>gh", "diffview", diffview_specs, diffview_setup,
  function() vim.cmd("DiffviewFileHistory %") end, { desc = "Diffview: history of this file" })
