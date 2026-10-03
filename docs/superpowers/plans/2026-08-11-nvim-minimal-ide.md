# Neovim Minimal-IDE Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add debugging (Go/Java/JS/Rust), format-on-save + lint, diagnostics/symbol pickers, richer git, a REST client, and a DB client to `shared/nvim/` while keeping startup cost at zero and the at-rest UI unchanged.

**Architecture:** Everything new lives in `shared/nvim/init.lua` (single-file convention; the only exception is the existing `lsp/*.lua` glob, which gains `eslint.lua`). Heavy plugins load through the file's existing `lazy_require(key, specs, setup)` / `lazy_keymap(...)` helpers on first keypress, or through a `FileType`/`BufWritePre` autocmd. Six new plugins total: nvim-dap, nvim-dap-view, conform.nvim, kulala.nvim, vim-dadbod, vim-dadbod-ui.

**Tech Stack:** Neovim 0.12 native `vim.pack`, mason + mason-tool-installer (already present), telescope + gitsigns (already present), delve/gofumpt/stylua from the Nix flake.

**Spec:** `docs/superpowers/specs/2026-08-11-nvim-minimal-ide-design.md`

## Global Constraints

- All new Lua goes into `shared/nvim/init.lua` — no new `lua/` modules. Only exception: `shared/nvim/lsp/eslint.lua`.
- Zero startup cost: no new eager `vim.pack.add` entries except where the plan says so; everything defers behind `lazy_require`, `lazy_keymap`, or autocmds.
- Nothing new is rendered at rest: no virtual text, no winbar, no always-on blame. `gitsigns` current-line blame defaults **off**.
- `lsp/gopls.lua` keeps `staticcheck = false` (deliberate memory trade-off — do not flip it).
- `mason-tool-installer` keeps `run_on_start = false`.
- DB connection strings must never be committed — they load from untracked `~/.config/dotfiles/scripts/db-connections.lua`.
- Every new keymap must carry a `desc` (they feed the `<leader>sk` keymaps picker).
- **The repo index currently holds a large staged-but-uncommitted merge resolution.** Every commit in this plan MUST use explicit pathspecs (`git commit -m "..." -- <files>`) so it never sweeps unrelated staged files. Do not run bare `git commit`.
- Verification style: this is editor config, not a library — "tests" are headless-nvim invocations (`nvim --headless ...`) plus the acceptance checks in each task. A task is done only when its Run/Expected steps pass.
- The user runs plugins via `vim.pack`, which clones on first use — verification steps that load a new plugin need network access and may take ~10s on first run.

---

### Task 1: Mason tool additions (groundwork)

**Files:**
- Modify: `shared/nvim/init.lua:301-312` (the `mason-tool-installer` setup)

**Interfaces:**
- Produces: mason packages `java-debug-adapter`, `js-debug-adapter`, `codelldb`, `prettier`, `eslint-lsp` installable via `:MasonToolsInstall`; later tasks resolve their binaries/jars under `vim.fn.stdpath("data") .. "/mason/packages/..."` and `.../mason/bin/...`.

- [ ] **Step 1: Extend `ensure_installed`**

In `shared/nvim/init.lua`, change the `mason-tool-installer` block to:

```lua
require("mason-tool-installer").setup({
  ensure_installed = {
    "gopls",
    "json-lsp",
    "lua-language-server",
    "rust-analyzer",
    "typescript-language-server",
    -- DAP adapters (see the Debugging section)
    "java-debug-adapter",
    "js-debug-adapter",
    "codelldb",
    -- Formatting / lint (see conform + lsp/eslint.lua)
    "prettier",
    "eslint-lsp",
  },
  auto_update = false,
  run_on_start = false,
})
```

- [ ] **Step 2: Verify config still loads**

Run: `nvim --headless "+lua print('config OK')" +q 2>&1 | tail -1`
Expected: `config OK` (no error trace)

- [ ] **Step 3: Install the tools**

Run: `nvim --headless "+MasonToolsInstallSync" +q` (first run downloads; allow a few minutes)
Then: `ls ~/.local/share/nvim/mason/bin/`
Expected: listing includes `js-debug-adapter`, `codelldb`, `prettier`, `vscode-eslint-language-server`; and `ls ~/.local/share/nvim/mason/packages/java-debug-adapter/extension/server/ | grep com.microsoft.java.debug.plugin` shows one jar.

- [ ] **Step 4: Commit**

```bash
git add shared/nvim/init.lua
git commit -m "feat(nvim): add DAP adapters + format/lint tools to mason ensure_installed" -- shared/nvim/init.lua
```

---

### Task 2: DAP core — nvim-dap + nvim-dap-view, Go and JS/TS adapters, keymaps

**Files:**
- Modify: `shared/nvim/init.lua` — add a `-- Debugging (DAP)` section right after the lazygit block (after line ~235, before the mini.starter block)

**Interfaces:**
- Consumes: `lazy_require(key, specs, setup)` and `lazy_keymap(mode, lhs, key, specs, setup, action, opts)` already defined at `init.lua:163-175`; `gh(repo)` URL helper.
- Produces: `dap_specs` (table) and `dap_setup()` (function) at file scope — Task 3 (Java) and Task 4 (Rust) extend the body of `dap_setup()`. Keymaps `<F5>`, `<F10>`, `<F11>`, `<S-F11>`, `<leader>db/dB/dd/dk/dq`.

- [ ] **Step 1: Add the DAP section to init.lua**

Insert after the lazygit `lazy_keymap` block:

```lua
-- Debugging (nvim-dap + nvim-dap-view). Loaded on the first debug keypress,
-- never at startup. dap-view is a single bottom panel (scopes/breakpoints/
-- watches/repl as tabs) that opens with the session and closes with it;
-- ad-hoc inspection goes through dap.ui.widgets hover instead of any
-- always-on panel.
local dap_specs = {
  gh("mfussenegger/nvim-dap"),
  gh("igorlfs/nvim-dap-view"),
}

local function dap_setup()
  local dap = require("dap")
  local dv = require("dap-view")
  dv.setup({})

  -- Open/close the panel with the session lifecycle.
  dap.listeners.before.attach["dap-view"] = function() dv.open() end
  dap.listeners.before.launch["dap-view"] = function() dv.open() end
  dap.listeners.before.event_terminated["dap-view"] = function() dv.close() end
  dap.listeners.before.event_exited["dap-view"] = function() dv.close() end

  -- Go: delve comes from the Nix flake (devPackages), not mason.
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

  -- JS/TS: js-debug-adapter from mason.
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
end

local function dap_do(fn, ...)
  local args = { ... }
  return function()
    lazy_require("dap", dap_specs, dap_setup)
    require("dap")[fn](unpack(args))
  end
end
vim.keymap.set("n", "<F5>", dap_do("continue"), { desc = "Debug: continue/start" })
vim.keymap.set("n", "<F10>", dap_do("step_over"), { desc = "Debug: step over" })
vim.keymap.set("n", "<F11>", dap_do("step_into"), { desc = "Debug: step into" })
vim.keymap.set("n", "<S-F11>", dap_do("step_out"), { desc = "Debug: step out" })
vim.keymap.set("n", "<leader>db", dap_do("toggle_breakpoint"), { desc = "Debug: toggle breakpoint" })
vim.keymap.set("n", "<leader>dB", function()
  lazy_require("dap", dap_specs, dap_setup)
  require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "Debug: conditional breakpoint" })
vim.keymap.set("n", "<leader>dq", dap_do("terminate"), { desc = "Debug: terminate session" })
vim.keymap.set("n", "<leader>dd", function()
  lazy_require("dap", dap_specs, dap_setup)
  require("dap-view").toggle()
end, { desc = "Debug: toggle panel" })
vim.keymap.set("n", "<leader>dk", function()
  lazy_require("dap", dap_specs, dap_setup)
  require("dap.ui.widgets").hover()
end, { desc = "Debug: inspect symbol" })
```

Note: before writing, skim both plugin READMEs (`mfussenegger/nvim-dap`, `igorlfs/nvim-dap-view`) for API drift — the listener names and `dv.setup/open/close/toggle` calls above are current as of writing but must match the installed version.

- [ ] **Step 2: Verify lazy path — config loads with zero new startup cost**

Run: `nvim --headless "+lua assert(not package.loaded['dap'], 'dap must not load at startup'); print('lazy OK')" +q 2>&1 | tail -1`
Expected: `lazy OK`

- [ ] **Step 3: Verify DAP loads and adapters register on demand**

Run: `nvim --headless "+lua vim.wait(200)" "+lua require('dap')" +q 2>&1 | tail -1` — this must FAIL (dap not installed/loaded eagerly is expected; ignore).
Then run the real check through the lazy loader:

```bash
nvim --headless \
  "+lua local m = vim.fn.maparg('<F5>', 'n', false, true); assert(m.callback, 'F5 mapped'); m.callback()" \
  "+lua local dap = require('dap'); assert(dap.adapters.go, 'go adapter'); assert(dap.adapters['pwa-node'], 'js adapter'); print('dap OK')" \
  +q 2>&1 | tail -1
```
Expected: `dap OK` (first run clones the two plugins — needs network). `<F5>` with no debuggee just prompts/no-ops headlessly; errors about "no configuration" are acceptable, assertion failures are not.

- [ ] **Step 4: Manual smoke test — Go**

In a scratch Go module (`mkdir /tmp/dbg && cd /tmp/dbg && go mod init dbg` + a `main.go` with a few lines), open `main.go`, `<leader>db` on a line, `<F5>`, pick "Debug package".
Expected: dap-view panel opens at the bottom, execution stops on the breakpoint, scopes tab shows locals; `<leader>dq` closes the session and the panel disappears.

- [ ] **Step 5: Commit**

```bash
git add shared/nvim/init.lua shared/nvim/nvim-pack-lock.json
git commit -m "feat(nvim): nvim-dap + dap-view with Go and JS/TS adapters, lazy-loaded" -- shared/nvim/init.lua shared/nvim/nvim-pack-lock.json
```

---

### Task 3: Java debugging (jdtls bundle + adapter)

**Files:**
- Modify: `shared/nvim/lsp/jdtls.lua` (add `init_options.bundles`)
- Modify: `shared/nvim/init.lua` (extend `dap_setup()` from Task 2)

**Interfaces:**
- Consumes: `dap_setup()` body from Task 2; mason package `java-debug-adapter` from Task 1; existing jdtls config table in `lsp/jdtls.lua`.
- Produces: `dap.adapters.java` (function) + `dap.configurations.java` (attach :5005).

- [ ] **Step 1: Wire the debug bundle into jdtls**

In `shared/nvim/lsp/jdtls.lua`, add to the returned table (sibling of `cmd`/`filetypes`):

```lua
  -- java-debug plugin jar (mason: java-debug-adapter). jdtls loads it as an
  -- OSGi bundle and then serves DAP sessions via the
  -- vscode.java.startDebugSession workspace command (see init.lua dap_setup).
  init_options = {
    bundles = vim.fn.glob(
      vim.fn.stdpath("data")
        .. "/mason/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar",
      false,
      true
    ),
  },
```

(`glob(..., false, true)` returns a list; an empty list when the mason package is missing is harmless — jdtls just starts without debug support.)

- [ ] **Step 2: Add the java adapter + attach configuration**

Inside `dap_setup()` in `init.lua`, after the JS/TS block:

```lua
  -- Java: the adapter is served BY jdtls (java-debug bundle, wired in
  -- lsp/jdtls.lua). Ask the running jdtls for a debug port, then connect.
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
```

- [ ] **Step 3: Verify config loads and jdtls still starts**

Run: `nvim --headless "+lua print('config OK')" +q 2>&1 | tail -1` → `config OK`.
Then in a Java project (mem-system): open a `.java` file, `:checkhealth vim.lsp` or `:lua =vim.lsp.get_clients({name='jdtls'})[1].name` → `jdtls`.

- [ ] **Step 4: Manual smoke test — attach to Spring Boot**

Start the app with the standard debug agent, e.g.
`mvn spring-boot:run -Dspring-boot.run.jvmArguments="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005"`.
In nvim: breakpoint in a controller method (`<leader>db`), `<F5>`, pick "Attach to JVM (:5005)", hit the endpoint with curl.
Expected: execution stops on the breakpoint; dap-view shows frames/locals.

- [ ] **Step 5: Commit**

```bash
git add shared/nvim/init.lua shared/nvim/lsp/jdtls.lua
git commit -m "feat(nvim): Java debugging via jdtls java-debug bundle (attach :5005)" -- shared/nvim/init.lua shared/nvim/lsp/jdtls.lua
```

---

### Task 4: Rust debugging (rustaceanvim + codelldb)

**Files:**
- Modify: `shared/nvim/init.lua` (the existing `vim.g.rustaceanvim` block, ~line 314)

**Interfaces:**
- Consumes: mason package `codelldb` (Task 1); existing `vim.g.rustaceanvim` table.
- Produces: working `:RustLsp debuggables` sessions rendered by dap-view.

- [ ] **Step 1: Point rustaceanvim at mason's codelldb**

Extend the existing `vim.g.rustaceanvim` table with a `dap` key (keep the `server` key untouched):

```lua
vim.g.rustaceanvim = {
  server = {
    default_settings = {
      ["rust-analyzer"] = {
        check = { command = "clippy" },
        cargo = { allFeatures = true },
        procMacro = { enable = true },
      },
    },
  },
  dap = {
    adapter = function()
      local mason = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension"
      local liblldb = mason .. "/lldb/lib/liblldb" .. (vim.uv.os_uname().sysname == "Darwin" and ".dylib" or ".so")
      return require("rustaceanvim.config").get_codelldb_adapter(mason .. "/adapter/codelldb", liblldb)
    end,
  },
}
```

Note: verify against the installed rustaceanvim README that `get_codelldb_adapter(codelldb_path, liblldb_path)` is still the exported helper, and confirm the two paths exist: `ls ~/.local/share/nvim/mason/packages/codelldb/extension/adapter/codelldb` and `.../extension/lldb/lib/`.

- [ ] **Step 2: Verify config loads**

Run: `nvim --headless "+lua print('config OK')" +q 2>&1 | tail -1` → `config OK`.

- [ ] **Step 3: Manual smoke test**

In any cargo project: `:RustLsp debuggables`, pick a target.
Expected: session starts, dap-view opens, breakpoints hit.

- [ ] **Step 4: Commit**

```bash
git add shared/nvim/init.lua
git commit -m "feat(nvim): rust debugging via rustaceanvim + mason codelldb" -- shared/nvim/init.lua
```

---

### Task 5: Format-on-save — conform.nvim

**Files:**
- Modify: `shared/nvim/init.lua` — new `-- Formatting` section replacing the current `<leader>lf` global keymap block (init.lua:56-70); also repoint the LspAttach `<leader>lf` map (init.lua:372).

**Interfaces:**
- Consumes: `lazy_require`, `gh`; flake-provided `gofumpt`, `goimports-reviser`, `stylua`; mason `prettier` (Task 1).
- Produces: `:FormatToggle` / `:FormatToggle!` commands; `<leader>lf` formats via conform everywhere (the jq fallback for large JSON stays).

- [ ] **Step 1: Add the conform section**

Replace the existing global `<leader>lf` keymap block (keep the jq behavior inside the new function) with:

```lua
-- Formatting (conform.nvim). Loaded on first save/format, never at startup.
local conform_specs = { gh("stevearc/conform.nvim") }
local function conform_setup()
  require("conform").setup({
    formatters_by_ft = {
      go = { "gofumpt", "goimports-reviser" },
      javascript = { "prettier" },
      javascriptreact = { "prettier" },
      typescript = { "prettier" },
      typescriptreact = { "prettier" },
      json = { "prettier" },
      lua = { "stylua" },
      -- rust/java fall through to LSP (rust-analyzer / jdtls) via lsp_format below
    },
  })
end

local function conform_format(bufnr, async)
  lazy_require("conform", conform_specs, conform_setup)
  require("conform").format({ bufnr = bufnr, async = async, timeout_ms = 500, lsp_format = "fallback" })
end

vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("format-on-save", { clear = true }),
  callback = function(args)
    if vim.g.disable_autoformat or vim.b[args.buf].disable_autoformat then return end
    if vim.b[args.buf].bigfile then return end
    conform_format(args.buf, false)
  end,
})

-- :FormatToggle (global) / :FormatToggle! (this buffer) — escape hatch for
-- vendored or generated files.
vim.api.nvim_create_user_command("FormatToggle", function(cmd)
  if cmd.bang then
    vim.b.disable_autoformat = not vim.b.disable_autoformat
    vim.notify("Format-on-save (buffer): " .. (vim.b.disable_autoformat and "off" or "on"))
  else
    vim.g.disable_autoformat = not vim.g.disable_autoformat
    vim.notify("Format-on-save (global): " .. (vim.g.disable_autoformat and "off" or "on"))
  end
end, { bang = true, desc = "Toggle format-on-save" })

vim.keymap.set("n", "<leader>lf", function()
  local ft = vim.bo.filetype
  if (ft == "json" or ft == "jsonc") and vim.b.bigfile and vim.fn.executable("jq") == 1 then
    local view = vim.fn.winsaveview()
    vim.cmd("silent keepjumps %!jq .")
    if vim.v.shell_error ~= 0 then
      vim.cmd("silent undo")
      vim.notify("jq failed (invalid JSON, or comments in jsonc)", vim.log.levels.ERROR)
    end
    vim.fn.winrestview(view)
  else
    conform_format(0, true)
  end
end, { desc = "Format buffer" })
```

Also delete the `map("<leader>lf", vim.lsp.buf.format, "Format")` line inside the LspAttach callback (init.lua:372) — the global conform mapping now covers attached buffers too, and the buffer-local override would bypass conform.

- [ ] **Step 2: Verify format-on-save**

```bash
printf 'local x   =    1\nprint(x)\n' > /tmp/fmt_test.lua
nvim --headless /tmp/fmt_test.lua +w +q 2>&1 | tail -1
cat /tmp/fmt_test.lua
```
Expected: file rewritten as `local x = 1` (stylua ran; first invocation clones conform — needs network).

- [ ] **Step 3: Verify the toggle**

```bash
printf 'local y   =    2\n' > /tmp/fmt_test2.lua
nvim --headless /tmp/fmt_test2.lua "+FormatToggle" +w +q >/dev/null 2>&1
grep -c 'y   =' /tmp/fmt_test2.lua
```
Expected: `1` (file untouched while toggled off).

- [ ] **Step 4: Commit**

```bash
git add shared/nvim/init.lua shared/nvim/nvim-pack-lock.json
git commit -m "feat(nvim): conform.nvim format-on-save with :FormatToggle escape hatch" -- shared/nvim/init.lua shared/nvim/nvim-pack-lock.json
```

---

### Task 6: Lint — eslint language server

**Files:**
- Create: `shared/nvim/lsp/eslint.lua`

**Interfaces:**
- Consumes: mason binary `vscode-eslint-language-server` (Task 1); the existing `lsp/*.lua` auto-enable glob in init.lua:328-332 (no init.lua change needed).
- Produces: eslint diagnostics through `vim.diagnostic` in projects that have an eslint config; silence everywhere else.

- [ ] **Step 1: Create `shared/nvim/lsp/eslint.lua`**

```lua
-- eslint language server (mason: eslint-lsp). Lint only — formatting stays
-- with conform/prettier. workspace_required + root_markers gate it to
-- projects that actually configure eslint, so no spurious diagnostics
-- elsewhere.
return {
  cmd = { "vscode-eslint-language-server", "--stdio" },
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  root_markers = {
    ".eslintrc", ".eslintrc.js", ".eslintrc.cjs", ".eslintrc.json", ".eslintrc.yaml", ".eslintrc.yml",
    "eslint.config.js", "eslint.config.mjs", "eslint.config.cjs", "eslint.config.ts",
  },
  workspace_required = true,
  settings = {
    validate = "on",
    run = "onType",
    workingDirectory = { mode = "auto" },
    format = false,
    codeAction = {
      disableRuleComment = { enable = true, location = "separateLine" },
      showDocumentation = { enable = true },
    },
    experimental = { useFlatConfig = false },
    problems = { shortenToSingleLine = false },
  },
  -- The server asks for this on newer protocol versions; answer statically.
  handlers = {
    ["eslint/noConfig"] = function() return {} end,
    ["eslint/openDoc"] = function(_, params)
      vim.ui.open(params.url)
      return {}
    end,
  },
}
```

Note: cross-check the settings block against nvim-lspconfig's `eslint.lua` for the installed server version (`~/.local/share/nvim/mason/packages/eslint-lsp`) — the server errors on missing `settings` keys more than most; copy any newly-required defaults from lspconfig rather than inventing them.

- [ ] **Step 2: Verify gating — no eslint in non-JS projects**

Run: `cd /tmp && nvim --headless /tmp/x.ts "+lua vim.wait(500)" "+lua print(#vim.lsp.get_clients({name='eslint'}))" +q 2>&1 | tail -1`
Expected: `0` (no eslint config in /tmp → server never starts).

- [ ] **Step 3: Verify diagnostics in an eslint project**

```bash
mkdir -p /tmp/eslint_test && cd /tmp/eslint_test
printf '{ "rules": { "no-unused-vars": "error" } }\n' > .eslintrc.json
printf 'const unused = 1\n' > a.js
npm init -y >/dev/null 2>&1 && npm i -D eslint@8 >/dev/null 2>&1
nvim --headless a.js "+lua vim.wait(3000)" "+lua print(#vim.diagnostic.get(0))" +q 2>&1 | tail -1
```
Expected: a number ≥ 1 (the `no-unused-vars` diagnostic).

- [ ] **Step 4: Commit**

```bash
git add shared/nvim/lsp/eslint.lua
git commit -m "feat(nvim): eslint language server, root-gated to eslint-configured projects" -- shared/nvim/lsp/eslint.lua
```

---

### Task 7: Telescope pickers — diagnostics, symbols, keymaps, file history

**Files:**
- Modify: `shared/nvim/init.lua` — next to the existing `<leader>s*` telescope keymaps (init.lua:233-238)

**Interfaces:**
- Consumes: the existing `tb(name, opts)` lazy-telescope helper (init.lua:227-232).
- Produces: `<leader>sd`, `<leader>ss`, `<leader>sS`, `<leader>sk`, `<leader>sc`.

- [ ] **Step 1: Add the keymaps**

After the existing `<leader><leader>` mapping:

```lua
vim.keymap.set("n", "<leader>sd", tb("diagnostics"), { desc = "Search diagnostics (project)" })
vim.keymap.set("n", "<leader>ss", tb("lsp_document_symbols"), { desc = "Search symbols (file outline)" })
vim.keymap.set("n", "<leader>sS", tb("lsp_workspace_symbols"), { desc = "Search symbols (workspace)" })
vim.keymap.set("n", "<leader>sk", tb("keymaps"), { desc = "Search keymaps" })
vim.keymap.set("n", "<leader>sc", tb("git_bcommits"), { desc = "Search commits touching this file" })
```

- [ ] **Step 2: Verify**

Run: `nvim --headless "+lua print(vim.fn.maparg('<leader>sk','n') ~= '' and 'maps OK' or 'MISSING')" +q 2>&1 | tail -1`
Expected: `maps OK`. Then interactively: `<leader>sk` lists keymaps including the new `Debug:` and `Search` descriptions.

- [ ] **Step 3: Commit**

```bash
git add shared/nvim/init.lua
git commit -m "feat(nvim): telescope pickers for diagnostics, symbols, keymaps, file history" -- shared/nvim/init.lua
```

---

### Task 8: Gitsigns keymaps

**Files:**
- Modify: `shared/nvim/init.lua:145` — replace `require("gitsigns").setup()` with a configured call

**Interfaces:**
- Consumes: gitsigns (already an eager plugin).
- Produces: hunk navigation/staging keymaps; current-line blame stays off by default.

- [ ] **Step 1: Configure gitsigns**

```lua
require("gitsigns").setup({
  current_line_blame = false, -- keep the at-rest UI clean; toggle with <leader>htb
  on_attach = function(bufnr)
    local gs = require("gitsigns")
    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = "Git: " .. desc })
    end
    map("n", "]h", function()
      if vim.wo.diff then vim.cmd.normal({ "]c", bang = true }) else gs.nav_hunk("next") end
    end, "next hunk")
    map("n", "[h", function()
      if vim.wo.diff then vim.cmd.normal({ "[c", bang = true }) else gs.nav_hunk("prev") end
    end, "previous hunk")
    map("n", "<leader>hs", gs.stage_hunk, "stage hunk")
    map("n", "<leader>hr", gs.reset_hunk, "reset hunk")
    map("v", "<leader>hs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "stage selection")
    map("v", "<leader>hr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "reset selection")
    map("n", "<leader>hS", gs.stage_buffer, "stage buffer")
    map("n", "<leader>hR", gs.reset_buffer, "reset buffer")
    map("n", "<leader>hp", gs.preview_hunk, "preview hunk")
    map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, "blame line")
    map("n", "<leader>htb", gs.toggle_current_line_blame, "toggle line blame")
    map("n", "<leader>hd", gs.diffthis, "diff against index")
  end,
})
```

- [ ] **Step 2: Verify**

Open any tracked file in this repo, edit a line:
- signs appear in the gutter; `]h` jumps to the hunk; `<leader>hp` previews; `<leader>hb` pops blame; nothing new shows at rest.
Headless check: `nvim --headless shared/nvim/init.lua "+lua vim.wait(300)" "+lua print(vim.fn.maparg('<leader>hs','n') ~= '' and 'gs OK' or 'MISSING')" +q 2>&1 | tail -1` → `gs OK`.

- [ ] **Step 3: Commit**

```bash
git add shared/nvim/init.lua
git commit -m "feat(nvim): gitsigns hunk keymaps (stage/reset/preview/blame), blame off at rest" -- shared/nvim/init.lua
```

---

### Task 9: REST client — kulala.nvim

**Files:**
- Modify: `shared/nvim/init.lua` — new `-- REST client` section after the DAP section

**Interfaces:**
- Consumes: `gh`; curl on PATH.
- Produces: `.http` buffers get `<CR>` (run), `[r`/`]r` (jump), `<leader>re` (select env).

- [ ] **Step 1: Add the section**

```lua
-- REST client (kulala.nvim). Requests live in plain .http files; the plugin
-- loads on the first http buffer and never otherwise.
vim.filetype.add({ extension = { http = "http" } })
local kulala_specs = { gh("mistweaverco/kulala.nvim") }
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("kulala-load", { clear = true }),
  pattern = "http",
  callback = function(ev)
    lazy_require("kulala", kulala_specs, function()
      require("kulala").setup({})
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
```

Note: check kulala's README for the current function names (`run`, `jump_next`, `jump_prev`, `set_selected_env`) and default response-view behavior; adjust `setup({})` only if a default violates the clean-UI constraint.

- [ ] **Step 2: Verify lazy gating + a real request**

```bash
nvim --headless "+lua assert(not package.loaded['kulala'], 'kulala must not load at startup'); print('lazy OK')" +q 2>&1 | tail -1
printf 'GET https://httpbin.org/get\n' > /tmp/t.http
```
Expected: `lazy OK`. Then interactively open `/tmp/t.http`, press `<CR>` on the request line → a split opens with the JSON response; `q` closes it.

- [ ] **Step 3: Commit**

```bash
git add shared/nvim/init.lua shared/nvim/nvim-pack-lock.json
git commit -m "feat(nvim): kulala REST client on .http filetypes" -- shared/nvim/init.lua shared/nvim/nvim-pack-lock.json
```

---

### Task 10: DB client — vim-dadbod + vim-dadbod-ui (+ psql in the flake)

**Files:**
- Modify: `shared/nvim/init.lua` — new `-- DB client` section after the REST section
- Modify: `flake.nix` — add `postgresql` to `devPackages`

**Interfaces:**
- Consumes: `lazy_require`, `gh`; untracked `~/.config/dotfiles/scripts/db-connections.lua` returning a table like `{ { name = "local", url = "postgresql://user@localhost/db" } }`.
- Produces: `<leader>du` opens DBUI; `:DB` available after first use.

- [ ] **Step 1: Add psql to the flake**

In `flake.nix` `devPackages`, after the Java block:

```nix
        # DB clients used by vim-dadbod (psql speaks postgres; add mysql/mariadb
        # client here if a project needs it)
        postgresql
```

Run: `nix eval .#homeConfigurations.ubuntu.activationPackage.drvPath 2>&1 | tail -1` → a `.drv` path (config still evaluates). Apply later with `make install`.

- [ ] **Step 2: Add the DB section to init.lua**

```lua
-- DB client (vim-dadbod + vim-dadbod-ui). Connections are per-machine
-- secrets: they load from an untracked file, never from this repo.
--   ~/.config/dotfiles/scripts/db-connections.lua  should  `return` a table:
--   return { { name = "local-pg", url = "postgresql://user:pass@localhost:5432/db" } }
local dadbod_specs = {
  gh("tpope/vim-dadbod"),
  { src = gh("kristijanhusak/vim-dadbod-ui"), name = "vim-dadbod-ui" },
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
lazy_keymap("n", "<leader>du", "dadbod", dadbod_specs, dadbod_setup,
  function() vim.cmd.DBUI() end, { desc = "DB: open UI" })
```

- [ ] **Step 3: Verify**

```bash
nvim --headless "+lua assert(vim.fn.exists(':DBUI') == 0, 'dadbod must not load at startup'); print('lazy OK')" +q 2>&1 | tail -1
```
Expected: `lazy OK`. Then interactively: `<leader>du` on a machine without the connections file → the "No DB connections configured" warning plus an empty DBUI drawer (no error). Create the file with a real URL, `<leader>du` → connection listed, `o` expands schema, a query buffer executes with `<leader>W` (dadbod-ui default save-and-execute is `:w`).

- [ ] **Step 4: Commit**

```bash
git add shared/nvim/init.lua shared/nvim/nvim-pack-lock.json flake.nix
git commit -m "feat(nvim): dadbod DB client with untracked per-machine connections; add psql to flake" -- shared/nvim/init.lua shared/nvim/nvim-pack-lock.json flake.nix
```

---

### Task 11: Apply + startup regression check

**Files:**
- None new (runs `make install`, measures startup)

**Interfaces:**
- Consumes: everything above.

- [ ] **Step 1: Apply the flake change**

Run: `make install` (installs psql via home-manager).
Expected: activation completes; `psql --version` prints.

- [ ] **Step 2: Startup regression**

```bash
nvim --headless --startuptime /tmp/st_after.txt +q && tail -1 /tmp/st_after.txt
```
Expected: total within a few ms of the pre-change baseline (measure the baseline the same way on `git stash` of init.lua if not recorded earlier; the six new plugins must NOT appear in the startuptime log at all).
Also: `grep -c 'dap\|conform\|kulala\|dadbod' /tmp/st_after.txt` → `0`.

- [ ] **Step 3: Full acceptance sweep**

Walk the spec's Testing/acceptance list (items 1–10) and check each off. Fix anything that fails before declaring done.

- [ ] **Step 4: Commit any lockfile drift**

```bash
git add shared/nvim/nvim-pack-lock.json
git commit -m "chore(nvim): update pack lockfile after plugin installs" -- shared/nvim/nvim-pack-lock.json || true
```
