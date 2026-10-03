-- pi.nvim — integration with the `pi` CLI agent (https://pi.dev)
-- Requires `pi` installed: curl -fsSL https://pi.dev/install.sh | sh

require("pi").setup({
	provider = "mlx-lm",
	model = "ornith-ai/Ornith-1.5-9B-MLX-4bit",
})

vim.keymap.set("n", "<leader>ai", ":PiAsk<CR>", { desc = "Ask pi" })
vim.keymap.set("v", "<leader>ai", ":PiAskSelection<CR>", { desc = "Ask pi (selection)" })
