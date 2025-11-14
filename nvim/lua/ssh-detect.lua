-- SSH Detection Module
-- Detects if Neovim is running over SSH and sets global flag

local M = {}

-- Detect if running over SSH
function M.is_ssh()
	-- Check multiple environment variables that indicate SSH
	return os.getenv("SSH_CONNECTION") ~= nil
		or os.getenv("SSH_CLIENT") ~= nil
		or os.getenv("SSH_TTY") ~= nil
end

-- Initialize SSH detection
function M.setup()
	vim.g.is_ssh = M.is_ssh()

	if vim.g.is_ssh then
		vim.notify("SSH session detected - applying performance optimizations", vim.log.levels.INFO)
	end
end

return M
