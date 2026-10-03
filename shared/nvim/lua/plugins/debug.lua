local U = require("utils")

local dap_specs = {
  U.gh("mfussenegger/nvim-dap"),
  U.gh("igorlfs/nvim-dap-view"),
}

local function dap_setup()
  local dap = require("dap")
  require("dap-view").setup({ auto_toggle = true })

  dap.adapters.go = {
    type = "server",
    port = "${port}",
    executable = { command = "dlv", args = { "dap", "-l", "127.0.0.1:${port}" } },
  }
  dap.configurations.go = {
    { type = "go", name = "Debug package", request = "launch", program = "${fileDirname}" },
    { type = "go", name = "Debug test (package)", request = "launch", mode = "test", program = "${fileDirname}" },
    {
      type = "go",
      name = "Attach to process",
      request = "attach",
      mode = "local",
      processId = function() return require("dap.utils").pick_process() end,
    },
  }

  local js_debug = vim.fn.stdpath("data") .. "/mason/bin/js-debug-adapter"
  if vim.fn.executable(js_debug) == 0 then
    vim.notify("js-debug-adapter missing — run :MasonToolsInstall", vim.log.levels.WARN)
  end
  dap.adapters["pwa-node"] = {
    type = "server",
    host = "localhost",
    port = "${port}",
    executable = { command = js_debug, args = { "${port}" } },
  }
  for _, ft in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
    dap.configurations[ft] = {
      {
        type = "pwa-node",
        name = "Launch current file (node)",
        request = "launch",
        program = "${file}",
        cwd = "${workspaceFolder}",
      },
      {
        type = "pwa-node",
        name = "Attach (--inspect, :9229)",
        request = "attach",
        processId = function() return require("dap.utils").pick_process() end,
        cwd = "${workspaceFolder}",
      },
    }
  end

  dap.adapters.java = function(callback)
    local client = vim.lsp.get_clients({ name = "jdtls" })[1]
    if not client then
      vim.notify("jdtls is not attached — open a Java file in the project first", vim.log.levels.WARN)
      return
    end
    client:request("workspace/executeCommand", { command = "vscode.java.startDebugSession" }, function(err, port)
      if err or not port then
        vim.notify("jdtls could not start a debug session: " .. vim.inspect(err), vim.log.levels.ERROR)
        return
      end
      callback({ type = "server", host = "127.0.0.1", port = port })
    end)
  end
  dap.configurations.java = {
    {
      type = "java",
      request = "attach",
      name = "Attach to JVM (:5005)",
      hostName = "127.0.0.1",
      port = 5005,
    },
  }
end

local function dap_do(fn)
  return function()
    U.lazy_require("dap", dap_specs, dap_setup)
    require("dap")[fn]()
  end
end

vim.keymap.set("n", "<F5>", dap_do("continue"), { desc = "Debug: continue/start" })
vim.keymap.set("n", "<F10>", dap_do("step_over"), { desc = "Debug: step over" })
vim.keymap.set("n", "<F11>", dap_do("step_into"), { desc = "Debug: step into" })
vim.keymap.set("n", "<S-F11>", dap_do("step_out"), { desc = "Debug: step out" })
vim.keymap.set("n", "<leader>db", dap_do("toggle_breakpoint"), { desc = "Debug: toggle breakpoint" })
vim.keymap.set("n", "<leader>dB", function()
  U.lazy_require("dap", dap_specs, dap_setup)
  require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "Debug: conditional breakpoint" })
vim.keymap.set("n", "<leader>dq", dap_do("terminate"), { desc = "Debug: terminate session" })
vim.keymap.set("n", "<leader>dd", function()
  U.lazy_require("dap", dap_specs, dap_setup)
  require("dap-view").toggle()
end, { desc = "Debug: toggle panel" })
vim.keymap.set("n", "<leader>dk", function()
  U.lazy_require("dap", dap_specs, dap_setup)
  require("dap.ui.widgets").hover()
end, { desc = "Debug: inspect symbol" })
