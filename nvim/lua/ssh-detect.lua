-- SSH Detection Module
-- Detects if Neovim is running over SSH/Mosh and sets global flag

local M = {}

-- Detect if running over SSH
function M.is_ssh()
	-- Check multiple environment variables that indicate SSH
	return os.getenv("SSH_CONNECTION") ~= nil
		or os.getenv("SSH_CLIENT") ~= nil
		or os.getenv("SSH_TTY") ~= nil
end

-- Detect if running over Mosh
function M.is_mosh()
	return os.getenv("MOSH_CONNECTION") ~= nil
end

-- Initialize SSH detection
function M.setup()
	vim.g.is_ssh = M.is_ssh()
	vim.g.is_mosh = M.is_mosh()

	-- Fix Mosh color and encoding issues
	if vim.g.is_mosh then
		-- Force 256 color support
		vim.env.TERM = "xterm-256color"
		vim.opt.termguicolors = false -- Disable true color, use 256 colors
		vim.opt.t_Co = 256

		-- Set encoding for proper icon/unicode support
		vim.opt.encoding = "utf-8"
		vim.opt.fileencoding = "utf-8"

		vim.notify("Mosh session detected - applying color fixes", vim.log.levels.INFO)
	end

	if vim.g.is_ssh then
		vim.notify("SSH session detected - applying performance optimizations", vim.log.levels.INFO)
	end
end

return M
