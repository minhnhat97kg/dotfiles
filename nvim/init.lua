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
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
vim.keymap.set("n", ";", ":", { desc = "Enter the command" })
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

vim.schedule(function()
	vim.opt.clipboard = "unnamedplus"
end)

vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		error("Error cloning lazy.nvim:\n" .. out)
	end
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	{
		"vhyrro/luarocks.nvim",
		priority = 1000, -- Very high priority is required, luarocks.nvim should run as the first plugin in your config.
		config = true,
	},
	"tpope/vim-sleuth", -- Detect tabstop and shiftwidth automatically

	{                  -- Adds git related signs to the gutter, as well as utilities for managing changes
		"lewis6991/gitsigns.nvim",
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
	--=====================================================================================
	-- INFO: KEY
	--=====================================================================================
	{                   -- Useful plugin to show you pending keybinds.
		"folke/which-key.nvim",
		event = "VimEnter", -- Sets the loading event to 'VimEnter'
		opts = {
			-- delay between pressing a key and opening which-key (milliseconds)
			-- this setting is independent of vim.opt.timeoutlen
			delay = 0,
			icons = {
				-- set icon mappings to true if you have a Nerd Font
				mappings = vim.g.have_nerd_font,
				-- If you are using a Nerd Font: set icons.keys to an empty table which will use the
				-- default which-key.nvim defined Nerd Font icons, otherwise define a string table
				keys = vim.g.have_nerd_font and {} or {
					Up = "<Up> ",
					Down = "<Down> ",
					Left = "<Left> ",
					Right = "<Right> ",
					C = "<C-…> ",
					M = "<M-…> ",
					D = "<D-…> ",
					S = "<S-…> ",
					CR = "<CR> ",
					Esc = "<Esc> ",
					ScrollWheelDown = "<ScrollWheelDown> ",
					ScrollWheelUp = "<ScrollWheelUp> ",
					NL = "<NL> ",
					BS = "<BS> ",
					Space = "<Space> ",
					Tab = "<Tab> ",
					F1 = "<F1>",
					F2 = "<F2>",
					F3 = "<F3>",
					F4 = "<F4>",
					F5 = "<F5>",
					F6 = "<F6>",
					F7 = "<F7>",
					F8 = "<F8>",
					F9 = "<F9>",
					F10 = "<F10>",
					F11 = "<F11>",
					F12 = "<F12>",
				},
			},

			-- Document existing key chains
			spec = {
				{ "<leader>c", group = "[C]ode",     mode = { "n", "x" } },
				{ "<leader>d", group = "[D]ocument" },
				{ "<leader>r", group = "[R]ename" },
				{ "<leader>s", group = "[S]earch" },
				{ "<leader>w", group = "[W]orkspace" },
				{ "<leader>t", group = "[T]oggle" },
				{ "<leader>h", group = "Git [H]unk", mode = { "n", "v" } },
			},
		},
	},

	--=====================================================================================
	-- INFO: TREESITTER
	--=====================================================================================

	{ -- Fuzzy Finder (files, lsp, etc)
		"nvim-telescope/telescope.nvim",
		event = "VimEnter",
		branch = "0.1.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ -- If encountering errors, see telescope-fzf-native README for installation instructions
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
				cond = function()
					return vim.fn.executable("make") == 1
				end,
			},
			{ "nvim-telescope/telescope-ui-select.nvim" },

			-- Useful for getting pretty icons, but requires a Nerd Font.
			{ "nvim-tree/nvim-web-devicons",            enabled = vim.g.have_nerd_font },
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

			-- Enable Telescope extensions if they are installed
			pcall(require("telescope").load_extension, "fzf")
			pcall(require("telescope").load_extension, "ui-select")

			-- See `:help telescope.builtin`
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

			-- Slightly advanced example of overriding default behavior and theme
			vim.keymap.set("n", "<leader>/", function()
				-- You can pass additional configuration to Telescope to change the theme, layout, etc.
				builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
					winblend = 10,
					previewer = false,
				}))
			end, { desc = "[/] Fuzzily search in current buffer" })

			-- It's also possible to pass additional configuration options.
			--  See `:help telescope.builtin.live_grep()` for information about particular keys
			vim.keymap.set("n", "<leader>s/", function()
				builtin.live_grep({
					grep_open_files = true,
					prompt_title = "Live Grep in Open Files",
				})
			end, { desc = "[S]earch [/] in Open Files" })

			-- Shortcut for searching your Neovim configuration files
			vim.keymap.set("n", "<leader>sn", function()
				builtin.find_files({ cwd = vim.fn.stdpath("config") })
			end, { desc = "[S]earch [N]eovim files" })
		end,
	},

	-- LSP Plugins
	{
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				{ path = "luvit-meta/library", words = { "vim%.uv" } },
			},
		},
	},

	-- --=====================================================================================
	-- -- INFO: JAVA
	-- --=====================================================================================
	--
	-- {
	-- 	"nvim-java/nvim-java",
	-- 	priority = 1000,
	-- 	dependencies = {
	-- 		"nvim-java/lua-async-await",
	-- 		"nvim-java/nvim-java-refactor",
	-- 		"nvim-java/nvim-java-core",
	-- 		"nvim-java/nvim-java-test",
	-- 		"nvim-java/nvim-java-dap",
	-- 		"MunifTanjim/nui.nvim",
	-- 		"neovim/nvim-lspconfig",
	-- 		"mfussenegger/nvim-dap",
	-- 		{
	-- 			"JavaHello/spring-boot.nvim",
	-- 			-- commit = "218c0c26c14d99feca778e4d13f5ec3e8b1b60f0",
	-- 		},
	-- 		{
	-- 			"williamboman/mason.nvim",
	-- 			opts = {
	-- 				registries = {
	-- 					"github:nvim-java/mason-registry",
	-- 					"github:mason-org/mason-registry",
	-- 				},
	-- 			},
	-- 		},
	-- 	},
	--
	-- 	config = function() end,
	-- },

	--=====================================================================================
	-- INFO: AUTOCOMPLETE
	--=====================================================================================

	{
		"saghen/blink.cmp",
		lazy = false, -- lazy loading handled internally
		-- optional: provides snippets for the snippet source
		dependencies = {
			-- add blink.compat to dependencies
			{ "saghen/blink.compat" },
			-- add source to dependencies
		},
		-- Use nightly build
		build = "cargo +nightly build --release",
		opts = {
			enabled = function()
				local disabled_filetypes = { "NvimTree", "snacks_input", "snacks_picker_input" } -- Add extra fileypes you do not want blink enabled.
				return not vim.tbl_contains(disabled_filetypes, vim.bo.filetype)
			end,
			appearance = {
				use_nvim_cmp_as_default = true,
				nerd_font_variant = "normal",
			},
			completion = {
				menu = {
					min_width = 25,
					border = "rounded",
					draw = {
						columns = { { "label", "label_description", gap = 4 }, { "kind_icon", gap = 1, "kind" } },
					},
				},
				documentation = {
					auto_show = true,
					auto_show_delay_ms = 200,
					window = {
						border = "rounded",
						winhighlight = "FloatBorder:boolean",
					},
				},
			},
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},
			cmdline = {
				enabled = false,
				keymap = {
					preset = "none",
					["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
					["<C-e>"] = { "hide" },
					["<CR>"] = { "select_accept_and_enter" },

					["<Up>"] = { "select_prev", "fallback" },
					["<Down>"] = { "select_next", "fallback" },
					["<C-k>"] = { "select_prev", "fallback_to_mappings" },
					["<C-j>"] = { "select_next", "fallback_to_mappings" },

					["<C-b>"] = { "scroll_documentation_up", "fallback" },
					["<C-f>"] = { "scroll_documentation_down", "fallback" },

					["<Tab>"] = { "snippet_forward", "fallback" },
					["<S-Tab>"] = { "snippet_backward", "fallback" },

					["<C-s>"] = { "show_signature", "hide_signature", "fallback" },
				},
				sources = function()
					local type = vim.fn.getcmdtype()
					-- Search forward and backward
					if type == "/" or type == "?" then
						return { "buffer" }
					end
					-- Commands
					if type == ":" or type == "@" then
						return { "cmdline" }
					end
					return {}
				end,
				completion = {
					trigger = {
						show_on_blocked_trigger_characters = {},
						show_on_x_blocked_trigger_characters = {},
					},
					list = {
						selection = {
							-- When `true`, will automatically select the first item in the completion list
							preselect = true,
							-- When `true`, inserts the completion item automatically when selecting it
							auto_insert = true,
						},
					},
					-- Whether to automatically show the window when new completion items are available
					menu = { auto_show = true },
					-- Displays a preview of the selected item on the current line
					ghost_text = { enabled = true },
				},
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
	--
	-- --=====================================================================================
	-- -- INFO: LSP
	-- --=====================================================================================
	{ "williamboman/mason.nvim", opts = {} },
	-- "nvimdev/lspsaga.nvim",
	-- "williamboman/mason-lspconfig.nvim",
	-- "WhoIsSethDaniel/mason-tool-installer.nvim",
	-- {
	-- 	-- Main LSP Configuration
	-- 	"neovim/nvim-lspconfig",
	-- 	dependencies = {
	-- 		-- Automatically install LSPs and related tools to stdpath for Neovim
	-- 		-- Mason must be loaded before its dependents so we need to set it up here.
	-- 		{ "williamboman/mason.nvim", opts = {} },
	-- 		"williamboman/mason-lspconfig.nvim",
	-- 		"WhoIsSethDaniel/mason-tool-installer.nvim",
	-- 		"nvimdev/lspsaga.nvim",
	-- 		"saghen/blink.cmp",
	-- 		-- Useful status updates for LSP.
	-- 		{ "j-hui/fidget.nvim", opts = {} },
	-- 	},
	-- 	config = function()
	-- 		require("java").setup({
	-- 			root_markers = {
	-- 				".git",
	-- 				"mvnw",
	-- 				"gradlew",
	-- 				"pom.xml",
	-- 			},
	-- 			java_test = {
	-- 				enable = false,
	-- 			},
	-- 			java_debug_adapter = {
	-- 				enable = false,
	-- 			},
	-- 			spring_boot_tools = {
	-- 				enable = true,
	-- 			},
	-- 			jdk = {
	-- 				auto_install = false,
	-- 			},
	-- 			notifications = {
	-- 				dap = false,
	-- 			},
	-- 		})
	--
	-- 		require("lspsaga").setup({
	-- 			symbol_in_winbar = {
	-- 				enable = true,
	-- 			},
	-- 			code_action_prompt = {
	-- 				enable = true,
	-- 				sign = true,
	-- 			},
	-- 			implement = {
	-- 				enable = true,
	-- 				sign = true,
	-- 			},
	-- 		})
	--
	-- 		vim.api.nvim_create_autocmd("LspAttach", {
	-- 			group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
	-- 			callback = function(event)
	-- 				local map = function(keys, func, desc, mode)
	-- 					mode = mode or "n"
	-- 					vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
	-- 				end
	--
	-- 				map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
	-- 				map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
	-- 				map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
	-- 				map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")
	-- 				map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
	-- 				map(
	-- 					"<leader>ws",
	-- 					require("telescope.builtin").lsp_dynamic_workspace_symbols,
	-- 					"[W]orkspace [S]ymbols"
	-- 				)
	-- 				map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
	-- 				map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction", { "n", "x" })
	-- 				-- WARN: This is not Goto Definition, this is Goto Declaration.
	-- 				--  For example, in C this would take you to the header.
	-- 				map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
	--
	-- 				local client = vim.lsp.get_client_by_id(event.data.client_id)
	-- 				if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
	-- 					local highlight_augroup =
	-- 						vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
	-- 					vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
	-- 						buffer = event.buf,
	-- 						group = highlight_augroup,
	-- 						callback = vim.lsp.buf.document_highlight,
	-- 					})
	--
	-- 					vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
	-- 						buffer = event.buf,
	-- 						group = highlight_augroup,
	-- 						callback = vim.lsp.buf.clear_references,
	-- 					})
	--
	-- 					vim.api.nvim_create_autocmd("LspDetach", {
	-- 						group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
	-- 						callback = function(event2)
	-- 							vim.lsp.buf.clear_references()
	-- 							vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
	-- 						end,
	-- 					})
	-- 				end
	--
	-- 				if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
	-- 					map("<leader>th", function()
	-- 						vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
	-- 					end, "[T]oggle Inlay [H]ints")
	-- 				end
	-- 			end,
	-- 		})
	--
	-- 		local servers = {
	-- 			jsonls = {},
	-- 			ts_ls = {},
	-- 			html = {},
	-- 			tailwindcss = {},
	-- 			lua_ls = {},
	-- 			jdtls = {
	-- 				java = {
	-- 					format = {
	-- 						settings = {
	-- 							url = "https://raw.githubusercontent.com/google/styleguide/gh-pages/eclipse-java-google-style.xml",
	-- 							profile = "GoogleStyle",
	-- 						},
	-- 					},
	-- 					configuration = {
	-- 						runtimes = {
	-- 							{
	-- 								default = true,
	-- 								name = "JavaSE-21",
	-- 								path = "/Library/Java/JavaVirtualMachines/temurin-21.jdk/Contents/Home",
	-- 							},
	-- 						},
	-- 					},
	-- 					implementationsCodeLens = {
	-- 						enabled = false,
	-- 					},
	-- 					referenceCodeLens = {
	-- 						enabled = false,
	-- 					},
	-- 				},
	-- 			},
	-- 		}
	--
	-- 		local ensure_installed = vim.tbl_keys(servers or {})
	-- 		local lspconfig = require("lspconfig")
	-- 		for server_name, server in pairs(servers) do
	-- 			server.capabilities = require("blink.cmp").get_lsp_capabilities(server.capabilities or {})
	-- 			lspconfig[server_name].setup(server)
	-- 		end
	--
	-- 		vim.list_extend(ensure_installed, {
	-- 			"stylua", -- Used to format Lua code
	-- 		})
	--
	-- 		require("mason-tool-installer").setup({ ensure_installed = ensure_installed })
	-- 		require("mason-lspconfig").setup({
	-- 			handlers = {
	-- 				function(server_name)
	-- 					local server = servers[server_name] or {}
	-- 					server.capabilities =
	-- 						vim.tbl_deep_extend("force", {}, capabilities or {}, server.capabilities or {})
	-- 					require("lspconfig")[server_name].setup(server)
	-- 				end,
	-- 			},
	-- 		})
	-- 	end,
	-- },

	--=====================================================================================
	-- INFO: AUTOFORMAT
	--=====================================================================================
	{ -- Autoformat
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>f",
				function()
					require("conform").format({ async = true, lsp_format = "fallback" })
				end,
				mode = "",
				desc = "[F]ormat buffer",
			},
		},
		opts = {
			notify_on_error = false,
			format_on_save = function(bufnr)
				local disable_filetypes = { c = true, cpp = true }
				local lsp_format_opt
				if disable_filetypes[vim.bo[bufnr].filetype] then
					lsp_format_opt = "never"
				else
					lsp_format_opt = "fallback"
				end
				return {
					timeout_ms = 500,
					lsp_format = lsp_format_opt,
				}
			end,
			formatters_by_ft = {
				lua = { "stylua" },
				java = {},
				nix = { "nixfmt" },
				javascript = { "prettierd" },
				typescript = { "prettierd" },
				javascriptreact = { "prettierd" },
				typescriptreact = { "prettierd" },
				svelte = { "prettierd" },
				css = { "prettierd" },
				html = { "prettierd" },
				json = { "prettierd" },
				yaml = { "prettierd" },
				markdown = { "prettierd" },
				graphql = { "prettierd" },
				liquid = { "prettierd" },
				python = { "isort", "black" },
				go = { "goimports" },
				sql = { "sql-formatter" },
				xml = { "prettierd" },
				terraform = { "terraform_fmt" },
			},
		},
	},

	--=====================================================================================
	-- INFO: HIGHLIGHT
	--=====================================================================================
	{
		"folke/todo-comments.nvim",
		event = "VimEnter",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = { signs = false },
	},

	{ -- Collection of various small independent plugins/modules
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

	--=====================================================================================
	-- INFO: TREESITTER
	--=====================================================================================
	{ -- Highlight, edit, and navigate code
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		main = "nvim-treesitter.configs", -- Sets main module to use for opts
		-- [[ Configure Treesitter ]] See `:help nvim-treesitter`
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
			},
			-- Autoinstall languages that are not installed
			auto_install = true,
			highlight = {
				enable = true,
				additional_vim_regex_highlighting = { "ruby" },
			},
			indent = { enable = true, disable = { "ruby" } },
		},
	},

	--=====================================================================================
	-- INFO: FILE EXPLORER
	--=====================================================================================
	{
		"nvim-neo-tree/neo-tree.nvim",
		version = "*",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
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

	-- --=====================================================================================
	-- -- NOTE: DEBUG
	-- --=====================================================================================
	-- {
	-- 	"mfussenegger/nvim-dap",
	-- 	dependencies = {
	-- 		"rcarriga/nvim-dap-ui",
	-- 		"nvim-neotest/nvim-nio",
	-- 		"williamboman/mason.nvim",
	-- 		"jay-babu/mason-nvim-dap.nvim",
	-- 		-- TODO: recheck later
	-- 		-- "leoluz/nvim-dap-go",
	-- 		-- "nvim-java/nvim-java",
	-- 	},
	-- 	keys = {
	-- 		{
	-- 			"<F5>",
	-- 			function()
	-- 				require("dap").continue()
	-- 			end,
	-- 			desc = "Debug: Start/Continue",
	-- 		},
	-- 		{
	-- 			"<F1>",
	-- 			function()
	-- 				require("dap").step_into()
	-- 			end,
	-- 			desc = "Debug: Step Into",
	-- 		},
	-- 		{
	-- 			"<F2>",
	-- 			function()
	-- 				require("dap").step_over()
	-- 			end,
	-- 			desc = "Debug: Step Over",
	-- 		},
	-- 		{
	-- 			"<F3>",
	-- 			function()
	-- 				require("dap").step_out()
	-- 			end,
	-- 			desc = "Debug: Step Out",
	-- 		},
	-- 		{
	-- 			"<leader>b",
	-- 			function()
	-- 				require("dap").toggle_breakpoint()
	-- 			end,
	-- 			desc = "Debug: Toggle Breakpoint",
	-- 		},
	-- 		{
	-- 			"<leader>B",
	-- 			function()
	-- 				require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
	-- 			end,
	-- 			desc = "Debug: Set Breakpoint",
	-- 		},
	-- 		-- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
	-- 		{
	-- 			"<F7>",
	-- 			function()
	-- 				require("dapui").toggle()
	-- 			end,
	-- 			desc = "Debug: See last session result.",
	-- 		},
	-- 	},
	-- 	config = function()
	-- 		local dap = require("dap")
	-- 		local dapui = require("dapui")
	--
	-- 		require("mason-nvim-dap").setup({
	-- 			automatic_installation = true,
	-- 			handlers = {},
	-- 			ensure_installed = {
	-- 				"delve",
	-- 			},
	-- 		})
	-- 		dapui.setup({
	-- 			icons = { expanded = "▾", collapsed = "▸", current_frame = "*" },
	-- 			controls = {
	-- 				icons = {
	-- 					pause = "⏸",
	-- 					play = "▶",
	-- 					step_into = "⏎",
	-- 					step_over = "⏭",
	-- 					step_out = "⏮",
	-- 					step_back = "b",
	-- 					run_last = "▶▶",
	-- 					terminate = "⏹",
	-- 					disconnect = "⏏",
	-- 				},
	-- 			},
	-- 		})
	-- 		dap.listeners.after.event_initialized["dapui_config"] = dapui.open
	-- 		dap.listeners.before.event_terminated["dapui_config"] = dapui.close
	-- 		dap.listeners.before.event_exited["dapui_config"] = dapui.close
	-- 		require("dap-go").setup({
	-- 			delve = {
	-- 				detached = vim.fn.has("win32") == 0,
	-- 			},
	-- 		})
	-- 	end,
	-- },
	--
	--=====================================================================================
	--INFO: INDENT
	--=====================================================================================
	{
		{ -- Add indentation guides even on blank lines
			"lukas-reineke/indent-blankline.nvim",
			-- Enable `lukas-reineke/indent-blankline.nvim`
			-- See `:help ibl`
			main = "ibl",
			opts = {},
		},
	},

	--=====================================================================================
	-- INFO: LINTING
	--=====================================================================================

	{ -- Linting
		"mfussenegger/nvim-lint",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local lint = require("lint")
			lint.linters_by_ft = {
				markdown = { "markdownlint" },
			}
			local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
			vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
				group = lint_augroup,
				callback = function()
					-- Only run the linter in buffers that you can modify in order to
					-- avoid superfluous noise, notably within the handy LSP pop-ups that
					-- describe the hovered symbol using Markdown.
					if vim.opt_local.modifiable:get() then
						lint.try_lint()
					end
				end,
			})
		end,
	},

	--=====================================================================================
	-- INFO: REST CLIENT
	--=====================================================================================
	{
		"rest-nvim/rest.nvim",
		dependencies = { "luarocks.nvim" },
		config = function()
			vim.keymap.set("n", "<leader>rr", "<cmd>Rest run<cr>", { desc = "[R]un [R]est API" })
			vim.bo.formatexpr = "v:vim.lsp.formatexpr()"
		end,
	},

	--=====================================================================================
	-- INFO: COLOR
	--=====================================================================================
	{
		"max397574/colortils.nvim",
		cmd = "Colortils",
		config = function()
			require("colortils").setup()
		end,
	},

	--=====================================================================================
	-- INFO: NEORG
	--=====================================================================================
	{
		"nvim-neorg/neorg",
		build = ":Neorg sync-parsers",                                                -- This ensures the parsers are built
		dependencies = { "luarocks.nvim", "nvim-treesitter", "nvim-lua/plenary.nvim" }, -- Add nvim-treesitter herelazy = false, -- Disable lazy loading as some `lazy.nvim` distributions set `lazy = true` by default
		lazy = false,
		config = function()
			require("neorg").setup({
				load = {
					["core.defaults"] = {}, -- Load all the default modules
					["core.concealer"] = {}, -- Allows for use of icons
					["core.dirman"] = { -- Manage your directories with Neorg
						config = {
							workspaces = {
								notes = "~/note", -- Change this to your Neorg notes directory
							},
						},
					},
				},
			})
		end,
	},

	--=====================================================================================
	-- INFO: UTIL
	--=====================================================================================
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		---@type snacks.Config
		opts = {
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
			animate = { enabled = false },
			bigfile = { enabled = true },
			dashboard = { enabled = false },
			indent = { enabled = true },
			quickfile = { enabled = true },
			scroll = { enabled = true },
			lazygit = { enabled = true },
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
	--=====================================================================================
	-- INFO:THEME
	--=====================================================================================
	{
		"navarasu/onedark.nvim",
		priority = 1000, -- Make sure to load this before all the other start plugins.
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
	--=====================================================================================
	-- INFO: MOVEMENT
	--=====================================================================================
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
	{
		"github/copilot.vim",
	},
	{
		"sindrets/diffview.nvim",
	},
	{
		'mfussenegger/nvim-jdtls',
		ft = { "java" },
	},
	{
		"christoomey/vim-tmux-navigator",
		cmd = {
			"TmuxNavigateLeft",
			"TmuxNavigateDown",
			"TmuxNavigateUp",
			"TmuxNavigateRight",
			"TmuxNavigatePrevious",
			"TmuxNavigatorProcessList",
		},
		keys = {
			{ "<c-h>",  "<cmd><C-U>TmuxNavigateLeft<cr>" },
			{ "<c-j>",  "<cmd><C-U>TmuxNavigateDown<cr>" },
			{ "<c-k>",  "<cmd><C-U>TmuxNavigateUp<cr>" },
			{ "<c-l>",  "<cmd><C-U>TmuxNavigateRight<cr>" },
			{ "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
		},
	},
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		dependencies = {
			{ "github/copilot.vim" },                    -- or zbirenbaum/copilot.lua
			{ "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log and async functions
		},
		build = "make tiktoken",                       -- Only on MacOS or Linux
		opts = {
			-- See Configuration section for options
		},
		-- See Commands section for default commands if you want to lazy load on them
	},
	{
		'MeanderingProgrammer/render-markdown.nvim',
		dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' }, -- if you use the mini.nvim suite
		-- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
		-- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
		---@module 'render-markdown'
		---@type render.md.UserConfig
		opts = {},
	}

})

vim.api.nvim_create_autocmd("FileType", {
	pattern = "json",
	callback = function(ev)
		vim.bo[ev.buf].formatprg = "jq"
	end,
})

-- vim.diagnostic.config({
-- 	virtual_lines = true,
-- })
-- vim.diagnostic.config({
-- 	virtual_text = {
-- 		spacing = 4,
-- 		prefix = "",
-- 	},
-- })

-- vim.lsp.enable("gopls", { filetypes = { "go" } })
local lsp_configs = {}
-- table.insert(lsp_configs, "jdtls") -- Java Development Tools Language Server
for _, f in pairs(vim.api.nvim_get_runtime_file('lsp/*.lua', true)) do
	local server_name = vim.fn.fnamemodify(f, ':t:r')
	table.insert(lsp_configs, server_name)
end
vim.lsp.enable(lsp_configs)

vim.diagnostic.config({
	-- virtual_lines = true,
	virtual_text = true,
	underline = true,
	update_in_insert = false,
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

vim.api.nvim_create_autocmd('TextYankPost', {
	desc = 'Highlight when yanking (copying) text',
	group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
	callback = function(event)
		local map = function(keys, func, desc)
			vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
		end

		-- defaults:
		-- https://neovim.io/doc/user/news-0.11.html#_defaults

		map("gl", vim.diagnostic.open_float, "Open Diagnostic Float")
		map("K", vim.lsp.buf.hover, "Hover Documentation")
		map("gs", vim.lsp.buf.signature_help, "Signature Documentation")
		map("gD", vim.lsp.buf.declaration, "Goto Declaration")
		map("gd", vim.lsp.buf.definition, "Goto Definition")
		map("<leader>la", vim.lsp.buf.code_action, "Code Action")
		map("<leader>lr", vim.lsp.buf.rename, "Rename all references")
		map("<leader>lf", vim.lsp.buf.format, "Format")
		map("<leader>v", "<cmd>vsplit | lua vim.lsp.buf.definition()<cr>", "Goto Definition in Vertical Split")

		local function client_supports_method(client, method, bufnr)
			if vim.fn.has 'nvim-0.11' == 1 then
				return client:supports_method(method, bufnr)
			else
				return client.supports_method(method, { bufnr = bufnr })
			end
		end

		local client = vim.lsp.get_client_by_id(event.data.client_id)
		if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
			local highlight_augroup = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })

			-- When cursor stops moving: Highlights all instances of the symbol under the cursor
			-- When cursor moves: Clears the highlighting
			vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
				buffer = event.buf,
				group = highlight_augroup,
				callback = vim.lsp.buf.document_highlight,
			})
			vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
				buffer = event.buf,
				group = highlight_augroup,
				callback = vim.lsp.buf.clear_references,
			})

			-- When LSP detaches: Clears the highlighting
			vim.api.nvim_create_autocmd('LspDetach', {
				group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
				callback = function(event2)
					vim.lsp.buf.clear_references()
					vim.api.nvim_clear_autocmds { group = 'lsp-highlight', buffer = event2.buf }
				end,
			})
		end
	end,

})

-- vim.cmd.colorscheme("habamax")
