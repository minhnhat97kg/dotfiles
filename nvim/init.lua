-- ============================================================================
-- SSH DETECTION (must be first!)
-- ============================================================================
local function is_ssh()
	return os.getenv("SSH_CONNECTION") ~= nil
		or os.getenv("SSH_CLIENT") ~= nil
		or os.getenv("SSH_TTY") ~= nil
end

vim.g.is_ssh = is_ssh()

if vim.g.is_ssh then
	vim.notify("SSH session detected - applying performance optimizations", vim.log.levels.INFO)
end

-- Debug helper: Use :DebugEnv to check environment variables
vim.api.nvim_create_user_command("DebugEnv", function()
	print("=== SSH/Mosh Detection Debug ===")
	print("")
	print("SSH Detection:")
	print("  SSH_CONNECTION: " .. (os.getenv("SSH_CONNECTION") or "not set"))
	print("  SSH_CLIENT: " .. (os.getenv("SSH_CLIENT") or "not set"))
	print("  SSH_TTY: " .. (os.getenv("SSH_TTY") or "not set"))
	print("")
	print("Terminal Info:")
	print("  TERM: " .. (os.getenv("TERM") or "not set"))
	print("  COLORTERM: " .. (os.getenv("COLORTERM") or "not set"))
	print("")
	print("Locale Info:")
	print("  LC_ALL: " .. (os.getenv("LC_ALL") or "not set"))
	print("  LANG: " .. (os.getenv("LANG") or "not set"))
	print("")
	print("Detection Results:")
	print("  is_ssh: " .. tostring(vim.g.is_ssh))
	print("")
	print("Neovim Color Settings:")
	print("  termguicolors: " .. tostring(vim.opt.termguicolors:get()))
	print("  encoding: " .. vim.opt.encoding:get())
	print("  has('termguicolors'): " .. tostring(vim.fn.has("termguicolors")))
	print("")
end, {})

-- ============================================================================
-- BASIC SETTINGS
-- ============================================================================
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true

vim.opt.number = true
vim.opt.mouse = "a"
vim.opt.showmode = false
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.smartindent = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.listchars = { tab = "| ", trail = "·", nbsp = "␣" }
vim.opt.inccommand = "split"
vim.opt.cursorline = true
vim.opt.scrolloff = 10

-- Clipboard
vim.schedule(function()
	vim.opt.clipboard = "unnamedplus"
end)

-- ============================================================================
-- PERFORMANCE OPTIMIZATIONS (Always applied)
-- ============================================================================

-- Faster update time (default is 4000ms, we use 300ms for better responsiveness)
vim.opt.updatetime = 300

-- Faster timeout for mapped sequences (default is 1000ms)
vim.opt.timeoutlen = 300

-- Disable swap files (faster, but no crash recovery)
vim.opt.swapfile = false

-- Keep undo history in a file instead of memory
vim.opt.undofile = true
vim.opt.undolevels = 10000

-- Faster terminal connection
vim.opt.ttyfast = true

-- Better completion experience
vim.opt.completeopt = "menu,menuone,noselect"

-- Smaller command line height (less redraw)
vim.opt.cmdheight = 1

-- Don't show mode in command line (we have statusline)
vim.opt.showmode = false

-- Limit syntax highlighting in long lines
vim.opt.synmaxcol = 300 -- Only highlight first 300 columns

-- Limit number of items in completion menu
vim.opt.pumheight = 15 -- Max 15 items in popup menu

-- Don't scan included files for completion (faster)
vim.opt.complete:remove("i")

-- Disable providers we don't use (faster startup)
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_python3_provider = 0

vim.notify("Performance optimizations applied", vim.log.levels.INFO)

-- ============================================================================
-- SSH OPTIMIZATIONS (Only for SSH sessions)
-- ============================================================================

if vim.g.is_ssh then
	-- Disable cursorline over SSH (causes constant redraws)
	vim.opt.cursorline = false

	-- Disable mouse support over SSH (reduces overhead)
	vim.opt.mouse = ""

	-- Increase update time for SSH (reduce network traffic)
	vim.opt.updatetime = 1000

	-- Disable list characters over SSH
	vim.opt.list = false

	-- Disable cursor shape changes (causes lag over network)
	vim.opt.guicursor = ""

	-- Disable clipboard sync over SSH (very slow)
	vim.schedule(function()
		vim.opt.clipboard = ""
	end)

	-- Reduce diagnostic verbosity over SSH
	vim.diagnostic.config({
		virtual_text = false,
		update_in_insert = false,
		severity_sort = true,
	})

	vim.notify("SSH optimizations applied", vim.log.levels.INFO)
end

-- ============================================================================
-- KEYMAPS
-- ============================================================================
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
vim.keymap.set("n", ";", ":", { desc = "Enter the command" })
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

-- ============================================================================
-- AUTOCMDS
-- ============================================================================
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = "json",
	callback = function(ev)
		vim.bo[ev.buf].formatprg = "jq"
	end,
})

-- ============================================================================
-- LAZY.NVIM SETUP
-- ============================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		error("Error cloning lazy.nvim:\n" .. out)
	end
end
vim.opt.rtp:prepend(lazypath)

-- ============================================================================
-- PLUGINS
-- ============================================================================
require("lazy").setup({
	-- Dependencies
	{
		"vhyrro/luarocks.nvim",
		priority = 1000,
		config = true,
	},

	-- Git integration (disabled in SSH for performance)
	{
		"lewis6991/gitsigns.nvim",
		enabled = not vim.g.is_ssh,
		opts = {
			signs = {
				add = { text = "+" },
				change = { text = "~" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
			},
		},
	},

	-- Which-key
	{
		"folke/which-key.nvim",
		event = "VimEnter",
		opts = {
			delay = 0,
			icons = {
				mappings = vim.g.have_nerd_font,
				keys = vim.g.have_nerd_font and {} or {},
			},
			spec = {
				{ "<leader>c", group = "[C]ode", mode = { "n", "x" } },
				{ "<leader>d", group = "[D]ocument" },
				{ "<leader>r", group = "[R]ename" },
				{ "<leader>s", group = "[S]earch" },
				{ "<leader>w", group = "[W]orkspace" },
				{ "<leader>t", group = "[T]oggle" },
				{ "<leader>h", group = "Git [H]unk", mode = { "n", "v" } },
				{ "<leader>l", group = "[L]SP" },
				{ "<leader>b", group = "[B]uffer" },
				{ "<leader>D", group = "[D]atabase" },
			},
		},
	},

	-- Telescope
	{
		"nvim-telescope/telescope.nvim",
		event = "VimEnter",
		branch = "0.1.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
				cond = function()
					return vim.fn.executable("make") == 1
				end,
			},
			{ "nvim-telescope/telescope-ui-select.nvim" },
			{ "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
		},
		config = function()
			require("telescope").setup({
				defaults = {
					layout_strategy = "flex",
					layout_config = { height = 0.95 },
				},
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown(),
					},
				},
			})

			pcall(require("telescope").load_extension, "fzf")
			pcall(require("telescope").load_extension, "ui-select")

			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
			vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
			vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "[S]earch [F]iles" })
			vim.keymap.set("n", "<leader>ss", builtin.builtin, { desc = "[S]earch [S]elect Telescope" })
			vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
			vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "[S]earch by [G]rep" })
			vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
			vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "[S]earch [R]esume" })
			vim.keymap.set("n", "<leader>s.", builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
			vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "[ ] Find existing buffers" })

			vim.keymap.set("n", "<leader>/", function()
				builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
					winblend = 10,
					previewer = false,
				}))
			end, { desc = "[/] Fuzzily search in current buffer" })

			vim.keymap.set("n", "<leader>s/", function()
				builtin.live_grep({
					grep_open_files = true,
					prompt_title = "Live Grep in Open Files",
				})
			end, { desc = "[S]earch [/] in Open Files" })

			vim.keymap.set("n", "<leader>sn", function()
				builtin.find_files({ cwd = vim.fn.stdpath("config") })
			end, { desc = "[S]earch [N]eovim files" })
		end,
	},

	-- Completion
	{
		"saghen/blink.cmp",
		lazy = false,
		build = "cargo +nightly build --release",
		opts = {
			enabled = function()
				local disabled_filetypes = { "NvimTree", "snacks_input", "snacks_picker_input" }
				return not vim.tbl_contains(disabled_filetypes, vim.bo.filetype)
			end,
			appearance = {
				use_nvim_cmp_as_default = true,
				nerd_font_variant = "normal",
			},
			completion = {
				menu = {
					min_width = 25,
					max_height = 15, -- Limit completion menu height for performance
					border = "rounded",
					draw = {
						columns = { { "label", "label_description", gap = 4 }, { "kind_icon", gap = 1, "kind" } },
					},
				},
				documentation = {
					auto_show = true,
					auto_show_delay_ms = 300, -- Slightly delay to reduce overhead
					window = {
						border = "rounded",
						winhighlight = "FloatBorder:boolean",
					},
				},
			},
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},
			signature = {
				enabled = true,
				window = {
					border = "rounded",
				},
			},
			fuzzy = { implementation = "lua" },
			keymap = {
				["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
				["<C-e>"] = { "hide", "fallback" },
				["<CR>"] = { "accept", "fallback" },
				["<Tab>"] = { "snippet_forward", "fallback" },
				["<S-Tab>"] = { "snippet_backward", "fallback" },
				["<Up>"] = { "select_prev", "fallback" },
				["<Down>"] = { "select_next", "fallback" },
				["<C-k>"] = { "select_prev", "fallback" },
				["<C-j>"] = { "select_next", "fallback" },
				["<C-b>"] = { "scroll_documentation_up", "fallback" },
				["<C-f>"] = { "scroll_documentation_down", "fallback" },
			},
		},
	},

	-- Mason for LSP/tools installation
	{ "williamboman/mason.nvim", opts = {} },

	-- Highlight comments
	{
		"folke/todo-comments.nvim",
		event = "VimEnter",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = { signs = false },
	},

	-- Mini plugins
	{
		"echasnovski/mini.nvim",
		config = function()
			require("mini.ai").setup({ n_lines = 500 })
			require("mini.surround").setup()
			local statusline = require("mini.statusline")
			statusline.setup({ use_icons = vim.g.have_nerd_font })
			statusline.section_location = function()
				return "%2l:%-2v"
			end
		end,
	},

	-- Treesitter
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		main = "nvim-treesitter.configs",
		opts = {
			ensure_installed = {
				"bash",
				"c",
				"diff",
				"html",
				"lua",
				"luadoc",
				"markdown",
				"markdown_inline",
				"query",
				"vim",
				"vimdoc",
				"sql",
			},
			auto_install = true,
			highlight = {
				enable = true,
				additional_vim_regex_highlighting = { "ruby" },
				disable = function(lang, buf)
					-- Disable for very large files
					local max_filesize = 100 * 1024 -- 100 KB
					local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
					if ok and stats and stats.size > max_filesize then
						return true
					end
				end,
			},
			indent = { enable = true, disable = { "ruby" } },
		},
	},

	-- File explorer
	{
		"nvim-neo-tree/neo-tree.nvim",
		version = "*",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
		},
		cmd = "Neotree",
		keys = {
			{ "\\", ":Neotree reveal<CR>", desc = "NeoTree reveal", silent = true },
		},
		opts = {
			filesystem = {
				window = {
					mappings = {
						["\\"] = "close_window",
					},
				},
			},
		},
	},

	-- Indent guides (disabled in SSH for performance)
	{
		"lukas-reineke/indent-blankline.nvim",
		enabled = not vim.g.is_ssh,
		main = "ibl",
		opts = {},
	},

	-- Snacks.nvim utilities
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		opts = {
			bigfile = { enabled = true },
			indent = { enabled = not vim.g.is_ssh }, -- Disable in SSH
			quickfile = { enabled = true },
			scroll = { enabled = not vim.g.is_ssh }, -- Disable smooth scrolling in SSH
			lazygit = { enabled = not vim.g.is_ssh }, -- Disable git UI in SSH
			bufdelete = { enabled = true },
			terminal = { enabled = true },
		},
		config = function()
			local snacks = require("snacks")
			vim.keymap.set("n", "<leader>tg", snacks.lazygit.open, { desc = "[T]oggle [G]it" })
			vim.keymap.set("n", "<leader>tt", snacks.terminal.toggle, { desc = "[T]oggle [T]erminal" })
			vim.keymap.set("n", "<leader>bdc", snacks.bufdelete.delete, { desc = "[B]uffer [D]elete [C]urrent" })
			vim.keymap.set("n", "<leader>bda", snacks.bufdelete.all, { desc = "[B]uffer [D]elete [A]ll" })
			vim.keymap.set("n", "<leader>bdo", snacks.bufdelete.other, { desc = "[B]uffer [D]elete [O]ther" })
		end,
	},

	-- Movement
	{
		"phaazon/hop.nvim",
		config = function()
			require("hop").setup({ keys = "etovxqpdygfblzhckisuran" })
			local hop = require("hop")
			local directions = require("hop.hint").HintDirection
			vim.keymap.set("", "f", function()
				hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = false })
			end, { remap = true })
			vim.keymap.set("", "F", function()
				hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = false })
			end, { remap = true })
		end,
	},

	-- Tmux integration
	{
		"christoomey/vim-tmux-navigator",
		cmd = {
			"TmuxNavigateLeft",
			"TmuxNavigateDown",
			"TmuxNavigateUp",
			"TmuxNavigateRight",
			"TmuxNavigatePrevious",
		},
		keys = {
			{ "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
			{ "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
			{ "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
			{ "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
			{ "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
		},
	},

	-- Copilot (disabled in SSH - network dependent)
	{
		"github/copilot.vim",
		enabled = not vim.g.is_ssh,
	},
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		enabled = not vim.g.is_ssh,
		dependencies = {
			{ "github/copilot.vim" },
			{ "nvim-lua/plenary.nvim", branch = "master" },
		},
		build = "make tiktoken",
		opts = {},
	},

	-- REST client
	{
		"mistweaverco/kulala.nvim",
		keys = {
			{ "<leader>Rs", desc = "Send request" },
			{ "<leader>Ra", desc = "Send all requests" },
			{ "<leader>Rb", desc = "Open scratchpad" },
		},
		ft = { "http", "rest" },
		opts = {
			global_keymaps = false,
			global_keymaps_prefix = "<leader>R",
		},
	},

	-- Markdown rendering (disabled in SSH - heavy rendering)
	{
		"MeanderingProgrammer/render-markdown.nvim",
		enabled = not vim.g.is_ssh,
		dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.nvim" },
		opts = {},
	},

	-- Java LSP (lazy loaded)
	{
		"mfussenegger/nvim-jdtls",
		ft = { "java" },
	},

	-- Database client (vim-dadbod)
	{
		"kristijanhusak/vim-dadbod-ui",
		dependencies = {
			{ "tpope/vim-dadbod", lazy = true },
			{ "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
		},
		cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
		init = function()
			-- UI configuration
			vim.g.db_ui_use_nerd_fonts = 1
			vim.g.db_ui_show_database_icon = 1
			vim.g.db_ui_force_echo_notifications = 1
			vim.g.db_ui_win_position = "left"
			vim.g.db_ui_winwidth = 40

			-- Table helpers - useful queries for each database type
			vim.g.db_ui_table_helpers = {
				postgresql = {
					Count = "SELECT COUNT(*) FROM {table}",
					Columns = "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = '{table}'",
				},
				mysql = {
					Count = "SELECT COUNT(*) FROM {table}",
					Columns = "DESCRIBE {table}",
				},
				sqlite = {
					Count = "SELECT COUNT(*) FROM {table}",
					Schema = "SELECT sql FROM sqlite_master WHERE name = '{table}'",
				},
			}

			-- Auto-execute query on save
			vim.g.db_ui_execute_on_save = 0
		end,
		config = function()
			-- Keymaps for database operations
			vim.keymap.set("n", "<leader>Du", "<cmd>DBUIToggle<cr>", { desc = "[D]atabase [U]I toggle" })
			vim.keymap.set("n", "<leader>Da", "<cmd>DBUIAddConnection<cr>", { desc = "[D]atabase [A]dd connection" })
			vim.keymap.set("n", "<leader>Df", "<cmd>DBUIFindBuffer<cr>", { desc = "[D]atabase [F]ind buffer" })
			vim.keymap.set("n", "<leader>Dr", "<cmd>DBUIRenameBuffer<cr>", { desc = "[D]atabase [R]ename buffer" })
			vim.keymap.set("n", "<leader>Dl", "<cmd>DBUILastQueryInfo<cr>", { desc = "[D]atabase [L]ast query info" })

			-- SQL file specific keymaps
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "sql", "mysql", "plsql" },
				callback = function()
					-- Execute query and send to pspg
					local function execute_to_pspg(is_visual)
						local query
						if is_visual then
							-- Get visual selection
							local start_pos = vim.fn.getpos("'<")
							local end_pos = vim.fn.getpos("'>")
							local lines = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)
							if #lines == 1 then
								lines[1] = string.sub(lines[1], start_pos[3], end_pos[3])
							else
								lines[1] = string.sub(lines[1], start_pos[3])
								lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
							end
							query = table.concat(lines, "\n")
						else
							-- Get current paragraph (query block)
							local cursor = vim.api.nvim_win_get_cursor(0)
							local start_line = cursor[1]
							local end_line = cursor[1]
							local total_lines = vim.api.nvim_buf_line_count(0)

							-- Find start of paragraph
							while start_line > 1 do
								local line = vim.api.nvim_buf_get_lines(0, start_line - 2, start_line - 1, false)[1]
								if line == "" then break end
								start_line = start_line - 1
							end

							-- Find end of paragraph
							while end_line < total_lines do
								local line = vim.api.nvim_buf_get_lines(0, end_line, end_line + 1, false)[1]
								if line == "" then break end
								end_line = end_line + 1
							end

							local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
							query = table.concat(lines, "\n")
						end

						-- Get database URL from DBUI
						local db_url = vim.b.db or vim.g.db
						if not db_url then
							vim.notify("No database connection found", vim.log.levels.ERROR)
							return
						end

						-- Execute query using vim-dadbod and capture output
						local tmpfile = vim.fn.tempname() .. ".txt"

						-- Write query to temp file and execute
						local queryfile = vim.fn.tempname() .. ".sql"
						vim.fn.writefile(vim.split(query, "\n"), queryfile)

						-- Execute via DB command with file input
						vim.cmd("DB < " .. queryfile)

						-- Wait for execution then get result
						vim.defer_fn(function()
							vim.fn.delete(queryfile)

							-- Find the most recent dbout buffer and get its content
							local dbout_buf = nil
							for _, buf in ipairs(vim.api.nvim_list_bufs()) do
								if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "dbout" then
									dbout_buf = buf
								end
							end

							if dbout_buf then
								local lines = vim.api.nvim_buf_get_lines(dbout_buf, 0, -1, false)
								if #lines > 0 and lines[1] ~= "" then
									vim.fn.writefile(lines, tmpfile)

									-- Close the result buffer/window
									for _, win in ipairs(vim.api.nvim_list_wins()) do
										if vim.api.nvim_win_get_buf(win) == dbout_buf then
											vim.api.nvim_win_close(win, true)
											break
										end
									end

									-- Open in pspg floating terminal
									require("snacks").terminal("pspg " .. tmpfile .. " && rm " .. tmpfile, {
										win = {
											style = "float",
											width = 0.9,
											height = 0.9,
											border = "rounded",
										},
									})
								else
									vim.notify("No results from query", vim.log.levels.WARN)
									vim.fn.delete(tmpfile)
								end
							else
								vim.notify("No result buffer found", vim.log.levels.ERROR)
								vim.fn.delete(tmpfile)
							end
						end, 500)
					end

					-- Execute query to pspg
					vim.keymap.set("n", "<leader>De", function() execute_to_pspg(false) end, { buffer = true, desc = "[D]atabase [E]xecute to pspg" })
					vim.keymap.set("v", "<leader>De", function() execute_to_pspg(true) end, { buffer = true, desc = "[D]atabase [E]xecute selection to pspg" })

					-- Execute query to buffer (original behavior)
					vim.keymap.set("n", "<leader>Db", "<Plug>(DBUI_ExecuteQuery)", { buffer = true, desc = "[D]atabase execute to [B]uffer" })
					vim.keymap.set("v", "<leader>Db", "<Plug>(DBUI_ExecuteQuery)", { buffer = true, desc = "[D]atabase execute to [B]uffer" })

					-- Save query to file
					vim.keymap.set("n", "<leader>Ds", "<Plug>(DBUI_SaveQuery)", { buffer = true, desc = "[D]atabase [S]ave query" })
					-- Toggle result layout (expanded view)
					vim.keymap.set("n", "<leader>Dt", "<Plug>(DBUI_ToggleResultLayout)", { buffer = true, desc = "[D]atabase [T]oggle result layout" })
				end,
			})
		end,
	},

	-- Theme
	{
		"navarasu/onedark.nvim",
		priority = 1000,
		init = function()
			vim.cmd.colorscheme("onedark")
		end,
		config = function()
			require("onedark").setup({
				style = "dark",
				transparent = true,
				term_colors = true,
			})
		end,
	},
})

-- ============================================================================
-- LSP CONFIGURATION (Neovim 0.11+)
-- ============================================================================

-- Auto-discover and enable LSP configs from runtime
local lsp_configs = {}
for _, f in pairs(vim.api.nvim_get_runtime_file("lsp/*.lua", true)) do
	local server_name = vim.fn.fnamemodify(f, ":t:r")

	-- Skip SSH-specific configs when not in SSH
	if server_name:match("-ssh$") then
		if vim.g.is_ssh then
			-- In SSH mode, use SSH config and skip regular version
			local base_name = server_name:gsub("-ssh$", "")
			-- Remove regular version if already added
			for i, config in ipairs(lsp_configs) do
				if config == base_name then
					table.remove(lsp_configs, i)
					break
				end
			end
			table.insert(lsp_configs, server_name)
		end
		-- Skip adding SSH config when not in SSH mode
	else
		-- Only add regular config if not in SSH mode or no SSH version exists
		if not vim.g.is_ssh then
			table.insert(lsp_configs, server_name)
		else
			-- Check if SSH version exists
			local ssh_version = server_name .. "-ssh"
			local has_ssh_version = false
			for _, file in ipairs(vim.api.nvim_get_runtime_file("lsp/" .. ssh_version .. ".lua", true)) do
				has_ssh_version = true
				break
			end
			-- If no SSH version, use regular version
			if not has_ssh_version then
				table.insert(lsp_configs, server_name)
			end
		end
	end
end
vim.lsp.enable(lsp_configs)

-- Diagnostic configuration (optimized for performance)
vim.diagnostic.config({
	virtual_text = {
		spacing = 4,
		prefix = "●",
		-- Only show diagnostics for current line
		source = "if_many",
	},
	underline = true,
	update_in_insert = false, -- Don't update while typing
	severity_sort = true,
	float = {
		border = "rounded",
		source = true,
	},
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "󰅚 ",
			[vim.diagnostic.severity.WARN] = "󰀪 ",
			[vim.diagnostic.severity.INFO] = "󰋽 ",
			[vim.diagnostic.severity.HINT] = "󰌶 ",
		},
		numhl = {
			[vim.diagnostic.severity.ERROR] = "ErrorMsg",
			[vim.diagnostic.severity.WARN] = "WarningMsg",
		},
	},
})

-- LSP Attach keymaps
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
	callback = function(event)
		local map = function(keys, func, desc)
			vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
		end

		map("gl", vim.diagnostic.open_float, "Open Diagnostic Float")
		map("K", vim.lsp.buf.hover, "Hover Documentation")
		map("gs", vim.lsp.buf.signature_help, "Signature Documentation")
		map("gD", vim.lsp.buf.declaration, "Goto Declaration")
		map("gd", vim.lsp.buf.definition, "Goto Definition")
		map("<leader>la", vim.lsp.buf.code_action, "Code Action")
		map("<leader>lr", vim.lsp.buf.rename, "Rename all references")
		map("<leader>lf", vim.lsp.buf.format, "Format")
		map("<leader>f", vim.lsp.buf.format, "[F]ormat buffer") -- Replaced conform.nvim
		map("<leader>v", "<cmd>vsplit | lua vim.lsp.buf.definition()<cr>", "Goto Definition in Vertical Split")

		local function client_supports_method(client, method, bufnr)
			if vim.fn.has("nvim-0.11") == 1 then
				return client:supports_method(method, bufnr)
			else
				return client.supports_method(method, { bufnr = bufnr })
			end
		end

		-- Disable document highlight for better performance
		-- (Can be re-enabled if needed, but causes lag on cursor movement)
		-- local client = vim.lsp.get_client_by_id(event.data.client_id)
		-- if
		-- 	client
		-- 	and client_supports_method(
		-- 		client,
		-- 		vim.lsp.protocol.Methods.textDocument_documentHighlight,
		-- 		event.buf
		-- 	)
		-- then
		-- 	local highlight_augroup = vim.api.nvim_create_augroup("lsp-highlight", { clear = false })
		--
		-- 	vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
		-- 		buffer = event.buf,
		-- 		group = highlight_augroup,
		-- 		callback = vim.lsp.buf.document_highlight,
		-- 	})
		-- 	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
		-- 		buffer = event.buf,
		-- 		group = highlight_augroup,
		-- 		callback = vim.lsp.buf.clear_references,
		-- 	})
		--
		-- 	vim.api.nvim_create_autocmd("LspDetach", {
		-- 		group = vim.api.nvim_create_augroup("lsp-detach", { clear = true }),
		-- 		callback = function(event2)
		-- 			vim.lsp.buf.clear_references()
		-- 			vim.api.nvim_clear_autocmds({ group = "lsp-highlight", buffer = event2.buf })
		-- 		end,
		-- 	})
		-- end
	end,
})
