-- Type checking / navigation. Linting and formatting are ruff's job
-- (lsp/ruff.lua), so nothing here duplicates a ruff rule.
return {
  cmd = { "basedpyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "uv.lock", "setup.py", "setup.cfg", "requirements.txt", ".git" },

  -- uv puts the project venv at <root>/.venv, and basedpyright does not look
  -- there on its own — without this every third-party import resolves to
  -- nothing. Point it at that interpreter when it exists; otherwise leave the
  -- default so a bare script still gets stdlib checking.
  before_init = function(_, config)
    if not config.root_dir then return end
    local python = config.root_dir .. "/.venv/bin/python"
    if not vim.uv.fs_stat(python) then return end
    config.settings = vim.tbl_deep_extend("force", config.settings or {}, {
      python = { pythonPath = python },
    })
  end,

  settings = {
    basedpyright = {
      analysis = {
        -- Whole-project analysis on a large repo is the memory hog here, same
        -- tradeoff as gopls' directoryFilters: check what's open.
        diagnosticMode = "openFilesOnly",
        typeCheckingMode = "standard",
        useLibraryCodeForTypes = true,
        autoImportCompletions = true,
      },
    },
  },
}
