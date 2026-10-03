# Neovim "minimal IDE" — design

Date: 2026-08-11
Target: `shared/nvim/` (nvim 0.12, native `vim.pack`, no plugin manager)

## Goal

Add IDE capabilities — debugging (Go, Java/Spring, JS/TS, Rust), automatic
format + lint, project-wide diagnostics/symbol navigation, richer git — while
keeping the config's philosophy:

- **Few plugins, built-in first.** Reuse telescope, gitsigns, mason,
  rustaceanvim, `vim.diagnostic`, quickfix before adding anything.
- **Clean UI.** Nothing new permanently on screen. Panels/popups appear only
  when invoked and close when done. No virtual-text debug values, no
  breadcrumbs, no always-on blame.
- **Zero startup cost.** Everything new is lazy-loaded through the existing
  `lazy_require`/`lazy_keymap` pattern in `init.lua`.

**Net new plugins: 6** — `nvim-dap`, `nvim-dap-view`, `conform.nvim`,
`kulala.nvim` (REST client), `vim-dadbod` + `vim-dadbod-ui` (DB client).

## Non-goals

- `nvim-dap-ui`, `trouble.nvim`, `neotest`, `nvim-dap-virtual-text`,
  breadcrumb/winbar plugins — rejected as UI/plugin bloat.
- Go lint via `staticcheck`: stays **off** (deliberate gopls memory trade-off
  documented in `lsp/gopls.lua`).
- Test-runner integration (not requested).

## 1. Debugging — `nvim-dap` + `nvim-dap-view`

### Structure

**Everything lives in `init.lua`** — no new Lua modules; the config stays
single-file (the existing `lsp/*.lua` server-config convention is the only
exception, unchanged). All DAP setup — adapters, configurations, dap-view —
sits in one `dap_setup()` function in `init.lua`, wired through the existing
`lazy_require`/`lazy_keymap` helpers: the DAP keymaps below call
`lazy_require("dap", dap_specs, dap_setup)` so the two plugins load on first
keypress, never at startup.

`nvim-dap-view` is the UI: a single bottom panel (scopes / breakpoints /
watches / repl as tabs in one window), auto-opens on session start,
auto-closes on session end. Ad-hoc inspection uses built-in
`require("dap.ui.widgets").hover()` instead of a persistent panel.

### Keymaps (global, load DAP on first use)

| Key | Action |
|-----|--------|
| `<F5>` | continue / start |
| `<F10>` / `<F11>` / `<S-F11>` | step over / into / out |
| `<leader>db` | toggle breakpoint |
| `<leader>dB` | conditional breakpoint |
| `<leader>dd` | toggle dap-view panel |
| `<leader>dk` | hover-inspect symbol under cursor |
| `<leader>dq` | terminate session |

### Adapters (config only, no adapter plugins)

- **Go** — adapter `dlv dap` (delve already in flake `devPackages`).
  Configurations: debug current package, debug test under cursor (via
  `vim.fn.expand` + `dlv test`), attach to running process.
- **Java** — `java-debug-adapter` installed by mason-tool-installer.
  `lsp/jdtls.lua` gains `init_options.bundles` globbing the mason package's
  `com.microsoft.java.debug.plugin-*.jar`. `debugging.lua` registers the
  `java` adapter through jdtls's `vscode.java.startDebugSession` command.
  Configurations: attach to `localhost:5005` (Spring Boot started with
  standard `-agentlib:jdwp` flags), plus jdtls-provided launch of current
  main class.
- **JS/TS** — `js-debug-adapter` installed by mason-tool-installer. Adapter
  `pwa-node`; configurations: launch current file with node, attach to
  `--inspect` (port 9229).
- **Rust** — nothing to write: `codelldb` installed by mason-tool-installer;
  `rustaceanvim` auto-detects it from the mason path and exposes
  `:RustLsp debuggables`. (Its DAP sessions still render in dap-view.)

## 2. Format + lint

### Format — `conform.nvim`

Loaded lazily on `BufWritePre` (conform's standard pattern; still zero
startup cost). Per-filetype formatters, all falling back to LSP:

| Filetype | Formatter |
|----------|-----------|
| go | `gofumpt` (flake) + `goimports-reviser` (flake) |
| javascript/typescript/tsx/json | `prettier` (mason) |
| lua | `stylua` (flake) |
| rust, java | LSP fallback (rust-analyzer / jdtls) |

- Format-on-save: `format_on_save` with 500 ms timeout, `lsp_format =
  "fallback"`.
- Escape hatch: `:FormatToggle` (buffer/global toggle via `vim.g/vim.b`
  flag checked in the `format_on_save` callback) for editing vendored or
  generated files.
- The existing `<leader>lf` LSP-attach keymap is repointed at
  `require("conform").format`.

### Lint — no plugin

- **JS/TS**: new `lsp/eslint.lua` (eslint language server, mason package
  `eslint-lsp`). Auto-enabled by the existing `lsp/*.lua` glob in
  `init.lua`; diagnostics arrive through `vim.diagnostic` like every other
  server. Root-gated on eslint config files so it stays silent elsewhere.
- **Go/Rust/Java/Lua**: existing LSP diagnostics already cover them
  (clippy is already wired via rust-analyzer `check.command`).

### mason-tool-installer additions

`ensure_installed` grows by: `java-debug-adapter`, `js-debug-adapter`,
`codelldb`, `prettier`, `eslint-lsp`. (`run_on_start = false` is preserved —
install is explicit via `:MasonToolsInstall`, as today.)

## 3. Diagnostics & symbols — 0 plugins

Telescope keymaps added next to the existing `<leader>s*` family:

| Key | Picker |
|-----|--------|
| `<leader>sd` | `diagnostics` (project-wide) |
| `<leader>ss` | `lsp_document_symbols` (file outline) |
| `<leader>sS` | `lsp_workspace_symbols` |
| `<leader>sk` | `keymaps` — searchable list of every keymap + description |

These reuse the existing `tb()` lazy-telescope helper. The current
`<leader>q` loclist binding stays.

`<leader>sk` doubles as the discoverability story for everything this spec
adds: every new keymap carries a `desc`, so the picker is the single place
to answer "what was that binding again?" — no which-key-style plugin needed.

## 4. Git — 0 plugins

Extend the existing `require("gitsigns").setup()` with an `on_attach`
keymap set:

| Key | Action |
|-----|--------|
| `]h` / `[h` | next / previous hunk |
| `<leader>hs` / `<leader>hr` | stage / reset hunk (visual-mode aware) |
| `<leader>hS` / `<leader>hR` | stage / reset buffer |
| `<leader>hp` | preview hunk inline |
| `<leader>hb` | blame line (popup, full message) |
| `<leader>htb` | toggle current-line blame (default **off**) |
| `<leader>hd` | diff buffer against index |

History browsing stays in lazygit / telescope `git_bcommits` (added as
`<leader>sc`).

## 5. REST client — `kulala.nvim`

Requests live in plain `.http` files (JetBrains/VS Code-compatible format) —
they are project files, editable/committable like code, no special UI to
learn. `kulala.nvim` executes them with curl and shows the response in a
split that opens on run and closes with `q`.

- Lazy-loaded via `FileType http` autocmd (`vim.pack.add` + setup on first
  `.http` buffer). Zero startup cost, invisible until used.
- Buffer-local keymaps on `http` filetypes only: `<CR>` run request under
  cursor, `[r` / `]r` jump between requests, `<leader>re` select
  environment (kulala's `http-client.env.json` — per-project base URLs,
  tokens).
- Needs only `curl` (already a system dependency everywhere).

## 6. DB client — `vim-dadbod` + `vim-dadbod-ui`

`vim-dadbod` is the minimal core (one `:DB` command, speaks
postgres/mysql/sqlite/… through their CLI clients); `vim-dadbod-ui` adds an
on-demand drawer for browsing connections/schemas and saved queries.

- Lazy-loaded on `<leader>du` → `:DBUI` (and `:DB` command shim) via the
  existing `lazy_require` pattern. Drawer opens when invoked, `q` closes;
  nothing at rest. (No clash: DAP's panel toggle is `<leader>dd`.)
- **Connections are never committed**: `vim.g.dbs` is read from an
  optional, untracked per-machine file
  `~/.config/dotfiles/scripts/db-connections.lua` (same pattern as the
  existing `load-aliases.sh`) — the repo is public, DB URLs are secrets.
- DB CLI clients (`psql`, `mysql`) come from the flake's `devPackages`
  (add `postgresql` client tools; mysql client optional per need).
- SQL completion in DB buffers: skipped for now (would need
  `vim-dadbod-completion` + a blink.cmp compat shim — revisit only if
  missed in practice).

## Error handling

- DAP adapters resolve mason paths at setup time; a missing adapter
  produces a single `vim.notify` warning naming the `:MasonToolsInstall`
  fix, not a stacktrace.
- conform with no formatter for a filetype silently falls back to LSP or
  no-ops — saving a file must never error.
- eslint LSP only attaches when an eslint config exists in the project
  root, so no spurious diagnostics in non-JS repos.

## Testing / acceptance

1. `nvim --startuptime` before/after: startup delta ≈ 0 (all new code
   behind lazy loads / BufWritePre).
2. Go: breakpoint in a `main.go`, `<F5>`, hits and shows scopes in
   dap-view; debug-test-under-cursor works.
3. Java: Spring Boot app started with jdwp on 5005 → attach config hits a
   controller breakpoint.
4. JS: `node --inspect` attach works.
5. Rust: `:RustLsp debuggables` runs a debug session rendered by dap-view.
6. `:w` on a `.go`/`.ts`/`.lua` file reformats; `:FormatToggle` disables it.
7. Opening a repo with `.eslintrc*` shows eslint diagnostics; a repo
   without stays clean.
8. gitsigns hunk staging/preview and telescope diagnostics/symbol pickers
   work; nothing new is rendered on screen at rest.
9. A `.http` file runs a request with `<CR>` and shows the response; a
   non-http buffer never loads kulala.
10. `<leader>du` opens the DBUI drawer against a connection defined in the
    untracked per-machine file; a machine without that file gets a clear
    "no connections configured" notice, not an error.
