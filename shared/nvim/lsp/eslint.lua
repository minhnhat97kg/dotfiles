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
    packageManager = nil,
    useESLintClass = false,
    experimental = {},
    codeActionOnSave = { enable = false, mode = "all" },
    -- Linting only — formatting stays with conform/prettier.
    format = false,
    quiet = false,
    onIgnoredFiles = "off",
    rulesCustomizations = {},
    run = "onType",
    problems = { shortenToSingleLine = false },
    nodePath = "",
    workingDirectory = { mode = "auto" },
    codeAction = {
      disableRuleComment = { enable = true, location = "separateLine" },
      showDocumentation = { enable = true },
    },
  },
  -- Requests the server makes that need a client-side answer; match
  -- nvim-lspconfig's defaults so a newer server version doesn't error on
  -- something this config doesn't otherwise handle.
  handlers = {
    ["eslint/openDoc"] = function(_, result)
      if result then vim.ui.open(result.url) end
      return {}
    end,
    ["eslint/confirmESLintExecution"] = function(_, result)
      if not result then return end
      return 4 -- approved
    end,
    ["eslint/probeFailed"] = function()
      vim.notify("eslint probe failed", vim.log.levels.WARN)
      return {}
    end,
    ["eslint/noLibrary"] = function()
      vim.notify("Unable to find ESLint library for this file", vim.log.levels.WARN)
      return {}
    end,
  },
}
