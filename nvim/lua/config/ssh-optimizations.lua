-- SSH Performance Optimizations
-- Applied when vim.g.is_ssh == true

local M = {}

function M.setup()
	if not vim.g.is_ssh then
		return
	end

	-- ============================================================================
	-- VISUAL OPTIMIZATIONS (Reduce redraws)
	-- ============================================================================

	-- Disable cursorline (causes redraw on every cursor move)
	vim.opt.cursorline = false

	-- Disable mouse support (reduces escape sequence overhead)
	vim.opt.mouse = ""

	-- Increase update time (less frequent updates)
	vim.opt.updatetime = 1000 -- Was 250ms, now 1s

	-- Increase timeout for mappings (less responsive but less overhead)
	vim.opt.timeoutlen = 500 -- Was 300ms, now 500ms

	-- Disable list characters rendering (slight performance gain)
	vim.opt.list = false

	-- ============================================================================
	-- TERMINAL OPTIMIZATIONS
	-- ============================================================================

	-- Disable cursor shape changes (escape sequences cause lag over SSH)
	vim.opt.guicursor = ""

	-- Disable bracketed paste (can cause lag)
	vim.opt.paste = false

	-- Set term for better compatibility
	vim.env.TERM = "xterm-256color"

	-- ============================================================================
	-- LSP OPTIMIZATIONS
	-- ============================================================================

	-- Reduce diagnostic update frequency
	vim.diagnostic.config({
		virtual_text = false, -- Disable virtual text (causes redraws)
		update_in_insert = false, -- Never update in insert mode
		severity_sort = true,
	})

	-- ============================================================================
	-- CLIPBOARD OPTIMIZATIONS
	-- ============================================================================

	-- Disable clipboard sync over SSH (can be very slow)
	vim.schedule(function()
		vim.opt.clipboard = "" -- Empty, don't sync with system
	end)

	-- ============================================================================
	-- NOTIFICATION
	-- ============================================================================

	vim.notify("SSH optimizations applied - Neovim should feel much faster!", vim.log.levels.INFO)
end

return M
