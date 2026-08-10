-- Minimal Neovim config: Go / Rust / React(JS/TS) / Lua

vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true

for _, p in ipairs({ "perl", "ruby", "node", "python3" }) do
  vim.g["loaded_" .. p .. "_provider"] = 0
end

-- Options
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
vim.opt.list = true
vim.opt.listchars = { tab = "| ", trail = "·", nbsp = "␣" }

vim.schedule(function()
  vim.opt.clipboard = "unnamedplus"
end)

-- Keymaps
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("n", ";", ":", { desc = "Command mode" })
vim.keymap.set("i", "kj", "<Esc>")
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostics list" })
vim.keymap.set("n", "<leader>tt", "<cmd>terminal<CR>", { desc = "Terminal" })

-- Autocmds
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
  callback = function() vim.highlight.on_yank() end,
})

-- Plugins
assert(vim.fn.has("nvim-0.12") == 1, "This config requires Neovim 0.12+")

local gh = function(repo) return "https://github.com/" .. repo end

vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == "telescope-fzf-native.nvim" and (kind == "install" or kind == "update") then
      vim.system({ "make" }, { cwd = ev.data.path })
    elseif name == "nvim-treesitter" and (kind == "install" or kind == "update") then
      vim.schedule(function() pcall(vim.cmd, "TSUpdate") end)
    end
  end,
})

-- Plugins needed on every startup (theme, treesitter, editing helpers,
-- completion, LSP tooling). Kept in the eager `vim.pack.add` call below.
vim.pack.add({
  { src = gh("navarasu/onedark.nvim"), name = "onedark.nvim" },
  gh("echasnovski/mini.nvim"),
  { src = gh("christoomey/vim-tmux-navigator"), name = "vim-tmux-navigator" },
  gh("nvim-treesitter/nvim-treesitter"),
  gh("saghen/blink.lib"),
  gh("saghen/blink.cmp"),
  gh("mrcjkb/rustaceanvim"),
  gh("lewis6991/gitsigns.nvim"),
  gh("williamboman/mason.nvim"),
  { src = gh("WhoIsSethDaniel/mason-tool-installer.nvim"), name = "mason-tool-installer.nvim" },
})

-- Theme
require("onedark").setup({ style = "darker" })
require("onedark").load()

-- UI/editing helpers
require("mini.ai").setup({ n_lines = 500 })
require("mini.surround").setup()

require("gitsigns").setup()

-- nvim-treesitter `main` branch API on nvim 0.12
require("nvim-treesitter").setup()
require("nvim-treesitter").install({
  "bash", "go", "gomod", "gosum", "gowork", "javascript", "typescript", "tsx", "json", "lua", "luadoc", "rust", "vim", "vimdoc",
})

-- File tree, fuzzy search, and Mason are only touched on demand (a keymap
-- press or an explicit command), not on every buffer/session. Registering
-- them with vim.pack.add eagerly still costs real startup time — Nvim
-- sources every added plugin's `plugin/` scripts right after init.lua runs,
-- regardless of any `load` option — so keep them out of the call above and
-- only `vim.pack.add` + `require(...).setup()` them the first time they're
-- actually invoked.
local lazy_loaded = {}
local function lazy_require(key, specs, setup)
  if lazy_loaded[key] then return end
  lazy_loaded[key] = true
  vim.pack.add(specs, { load = true })
  setup()
end

local function lazy_keymap(mode, lhs, key, specs, setup, action, opts)
  vim.keymap.set(mode, lhs, function()
    lazy_require(key, specs, setup)
    action()
  end, opts)
end

local nvim_tree_specs = {
  { src = gh("nvim-tree/nvim-tree.lua"), name = "nvim-tree.lua" },
  { src = gh("nvim-tree/nvim-web-devicons"), name = "nvim-web-devicons" },
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
  })
end
lazy_keymap("n", "<leader>e", "nvim-tree", nvim_tree_specs, nvim_tree_setup,
  function() vim.cmd.NvimTreeToggle() end, { desc = "Toggle file tree" })
lazy_keymap("n", "<leader>E", "nvim-tree", nvim_tree_specs, nvim_tree_setup,
  function() vim.cmd.NvimTreeFindFile() end, { desc = "Reveal current file" })

local telescope_specs = {
  gh("nvim-lua/plenary.nvim"),
  gh("nvim-telescope/telescope.nvim"),
  { src = gh("nvim-telescope/telescope-fzf-native.nvim"), name = "telescope-fzf-native.nvim" },
}
local function telescope_setup()
  require("telescope").setup({
    defaults = {
      layout_strategy = "flex",
      layout_config = { height = 0.95 },
    },
  })
  pcall(require("telescope").load_extension, "fzf")
end
local function tb(name, opts)
  return function()
    lazy_require("telescope", telescope_specs, telescope_setup)
    require("telescope.builtin")[name](opts)
  end
end
vim.keymap.set("n", "<leader>sf", tb("find_files"), { desc = "Search files" })
vim.keymap.set("n", "<leader>sg", tb("live_grep"), { desc = "Search grep" })
vim.keymap.set("n", "<leader>sw", tb("grep_string"), { desc = "Search word" })
vim.keymap.set("n", "<leader>sb", tb("buffers"), { desc = "Search buffers" })
vim.keymap.set("n", "<leader>sh", tb("help_tags"), { desc = "Search help" })
vim.keymap.set("n", "<leader><leader>", tb("buffers"), { desc = "Buffers" })

local lazygit_specs = {
  { src = gh("kdheepak/lazygit.nvim"), name = "lazygit.nvim" },
  gh("nvim-lua/plenary.nvim"),
}
local function lazygit_setup() end
local function open_lazygit()
  lazy_require("lazygit", lazygit_specs, lazygit_setup)
  vim.cmd.LazyGit()
end
lazy_keymap("n", "<leader>gg", "lazygit", lazygit_specs, lazygit_setup,
  open_lazygit, { desc = "Lazygit" })

-- Start screen (mini.starter) — shown on `nvim` with no file arguments.
-- Reuses telescope (`tb`) and lazygit (`open_lazygit`) lazy-loaders so the
-- welcome screen itself stays cheap.
local starter = require("mini.starter")
starter.setup({
  header = [[
    ███╗   ██╗██╗   ██╗██╗███╗   ███╗
    ████╗  ██║██║   ██║██║████╗ ████║
    ██╔██╗ ██║██║   ██║██║██╔████╔██║
    ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║
    ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║
    ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝
  ]],
  items = {
    { name = "Find files", action = tb("find_files"), section = "Search" },
    { name = "Search text", action = tb("live_grep"), section = "Search" },
    starter.sections.recent_files(8, true),
    { name = "Lazygit", action = open_lazygit, section = "Tools" },
    starter.sections.builtin_actions(),
  },
  footer = [[Type to filter · <CR> open · <Esc> reset · <C-c> close]],
  content_hooks = {
    starter.gen_hook.adding_bullet("▍ ", false),
    starter.gen_hook.aligning("center", "center"),
  },
})

-- The `main` branch no longer auto-enables highlighting via `highlight = { enable = true }`;
-- start it per buffer for any filetype that has an installed parser.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("treesitter-start", { clear = true }),
  callback = function(ev)
    local lang = vim.treesitter.language.get_lang(ev.match)
    if not lang then return end
    -- pcall's first return is only "did it error"; the parser may be absent
    -- without erroring (e.g. Telescope's `TelescopeResults` buffers), so we
    -- must also check `language.add`'s own return before starting.
    local ok, added = pcall(vim.treesitter.language.add, lang)
    if ok and added then
      vim.treesitter.start(ev.buf, lang)
      vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

-- Completion
require("blink.cmp").setup({
  completion = {
    menu = { auto_show = true },
    documentation = { auto_show = true, auto_show_delay_ms = 300 },
  },
  sources = { default = { "lsp", "path", "snippets", "buffer" } },
  cmdline = { enabled = true },
  signature = { enabled = true },
  fuzzy = { implementation = "lua" },
  keymap = {
    preset = "default",
    ["<CR>"] = { "accept", "fallback" },
    ["<Tab>"] = { "select_and_accept", "snippet_forward", "fallback" },
    ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
  },
})

-- Tools
require("mason").setup()
require("mason-tool-installer").setup({
  ensure_installed = {
    "gopls",
    "lua-language-server",
    "rust-analyzer",
    "typescript-language-server",
  },
  auto_update = false,
  run_on_start = false,
})

-- Rust
vim.g.rustaceanvim = {
  server = {
    default_settings = {
      ["rust-analyzer"] = {
        check = { command = "clippy" },
        cargo = { allFeatures = true },
        procMacro = { enable = true },
      },
    },
  },
}

-- LSP
local lsp_configs = {}
for _, f in ipairs(vim.api.nvim_get_runtime_file("lsp/*.lua", true)) do
  table.insert(lsp_configs, vim.fn.fnamemodify(f, ":t:r"))
end
vim.lsp.enable(lsp_configs)

vim.diagnostic.config({
  virtual_text = { spacing = 4, prefix = "●", source = "if_many" },
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = { source = true },
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc)
      vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
    end
    map("K", vim.lsp.buf.hover, "Hover")
    map("gd", vim.lsp.buf.definition, "Definition")
    map("gD", vim.lsp.buf.declaration, "Declaration")
    map("gr", vim.lsp.buf.references, "References")
    map("gi", vim.lsp.buf.implementation, "Implementation")
    map("gl", vim.diagnostic.open_float, "Line diagnostics")
    map("<leader>la", vim.lsp.buf.code_action, "Code action")
    map("<leader>lr", vim.lsp.buf.rename, "Rename")
    map("<leader>lf", vim.lsp.buf.format, "Format")
  end,
})
