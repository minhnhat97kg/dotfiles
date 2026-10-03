return {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl", "gosum" },
  root_markers = { "go.work", "go.mod", ".git" },
  settings = {
    gopls = {
      -- Keep these trees out of the package graph to cut memory/indexing.
      directoryFilters = { "-node_modules", "-.git", "-vendor" },
      gofumpt = true,
      -- staticcheck disabled to keep gopls memory down; core diagnostics and
      -- completion are unaffected.
      staticcheck = false,
      usePlaceholders = true,
      completeUnimported = true,
      analyses = {
        nilness = true,
        unusedparams = true,
        unusedwrite = true,
        unusedvariable = true,
        unreachable = true,
      },
    },
  },
}
