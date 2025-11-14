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
	-- Mosh sets multiple environment variables
	-- Try all possible Mosh indicators
	local term = os.getenv("TERM")

	return os.getenv("MOSH_CONNECTION") ~= nil
		or os.getenv("LC_TERMINAL") == "mosh"
		or (term and term:match("^screen")) -- Mosh often uses screen-256color
end

-- Initialize SSH detection
function M.setup()
	vim.g.is_ssh = M.is_ssh()
	vim.g.is_mosh = M.is_mosh()

	-- Always apply color fixes for SSH/Mosh sessions
	-- (Mosh detection might fail, so we apply fixes for all SSH)
	if vim.g.is_ssh or vim.g.is_mosh then
		-- Ensure TERM is set properly FIRST (before Neovim reads it)
		if vim.env.TERM ~= "xterm-256color" and vim.env.TERM ~= "screen-256color" then
			vim.env.TERM = "xterm-256color"
		end

		-- Force 256 color support (safe for both SSH and Mosh)
		vim.opt.termguicolors = false -- Disable true color, use 256 colors

		-- Set encoding for proper icon/unicode support
		vim.opt.encoding = "utf-8"
		vim.opt.fileencoding = "utf-8"
	end

	if vim.g.is_mosh then
		vim.notify("Mosh session detected - applying color fixes", vim.log.levels.INFO)
	elseif vim.g.is_ssh then
		vim.notify("SSH session detected - applying optimizations (256 colors for compatibility)", vim.log.levels.INFO)
	end
end

return M
