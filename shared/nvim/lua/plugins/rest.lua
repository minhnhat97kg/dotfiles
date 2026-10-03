local U = require("utils")

vim.filetype.add({ extension = { http = "http" } })

local kulala_specs = { U.gh("mistweaverco/kulala.nvim") }

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("kulala-load", { clear = true }),
  pattern = "http",
  callback = function(ev)
    U.lazy_require("kulala", kulala_specs, function()
      require("kulala").setup({ global_keymaps = false })
    end)
    local function bmap(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = "REST: " .. desc })
    end
    bmap("<CR>", function() require("kulala").run() end, "run request under cursor")
    bmap("]r", function() require("kulala").jump_next() end, "next request")
    bmap("[r", function() require("kulala").jump_prev() end, "previous request")
    bmap("<leader>re", function() require("kulala").set_selected_env() end, "select environment")
  end,
})
