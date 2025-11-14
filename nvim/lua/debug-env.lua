-- Debug Environment Variables
-- Use this to check what variables are set in your session

local M = {}

function M.show_env()
	print("=== SSH/Mosh Detection Debug ===")
	print("")

	-- SSH variables
	print("SSH Detection:")
	print("  SSH_CONNECTION: " .. (os.getenv("SSH_CONNECTION") or "not set"))
	print("  SSH_CLIENT: " .. (os.getenv("SSH_CLIENT") or "not set"))
	print("  SSH_TTY: " .. (os.getenv("SSH_TTY") or "not set"))
	print("")

	-- Mosh variables
	print("Mosh Detection:")
	print("  MOSH_CONNECTION: " .. (os.getenv("MOSH_CONNECTION") or "not set"))
	print("  LC_TERMINAL: " .. (os.getenv("LC_TERMINAL") or "not set"))
	print("")

	-- Terminal info
	print("Terminal Info:")
	print("  TERM: " .. (os.getenv("TERM") or "not set"))
	print("  COLORTERM: " .. (os.getenv("COLORTERM") or "not set"))
	print("")

	-- Locale info
	print("Locale Info:")
	print("  LC_ALL: " .. (os.getenv("LC_ALL") or "not set"))
	print("  LANG: " .. (os.getenv("LANG") or "not set"))
	print("")

	-- Detection results
	print("Detection Results:")
	print("  is_ssh: " .. tostring(vim.g.is_ssh))
	print("  is_mosh: " .. tostring(vim.g.is_mosh))
	print("")

	-- Neovim settings
	print("Neovim Color Settings:")
	print("  termguicolors: " .. tostring(vim.opt.termguicolors:get()))
	print("  encoding: " .. vim.opt.encoding:get())
	print("  has('termguicolors'): " .. tostring(vim.fn.has("termguicolors")))
	print("")
end

-- Create a command to run this easily
vim.api.nvim_create_user_command("DebugEnv", M.show_env, {})

return M
