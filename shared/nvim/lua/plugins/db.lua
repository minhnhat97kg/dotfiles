local U = require("utils")

local dadbod_specs = {
  U.gh("tpope/vim-dadbod"),
  { src = U.gh("kristijanhusak/vim-dadbod-ui"), name = "vim-dadbod-ui" },
}

local function dadbod_setup()
  local conn_file = vim.fn.expand("~/.config/dotfiles/scripts/db-connections.lua")
  if vim.uv.fs_stat(conn_file) then
    local ok, dbs = pcall(dofile, conn_file)
    if ok and type(dbs) == "table" then
      vim.g.dbs = dbs
    else
      vim.notify("db-connections.lua exists but did not return a table", vim.log.levels.ERROR)
    end
  else
    vim.notify("No DB connections configured — create " .. conn_file, vim.log.levels.WARN)
  end
  vim.g.db_ui_use_nerd_fonts = 1
end

U.lazy_keymap("n", "<leader>du", "dadbod", dadbod_specs, dadbod_setup,
  function() vim.cmd.DBUI() end, { desc = "DB: open UI" })
