return {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl", "gosum" },
  root_markers = { "go.work", "go.mod", ".git" },
  settings = {
    gopls = {
      gofumpt = true,
      staticcheck = true,
      usePlaceholders = true,
      completeUnimported = true,
      analyses = {
        nilness = true,
        unusedparams = true,
        unusedwrite = true,
        unusedvariable = true,
        unreachable = true,
        shadow = true,
      },
    },
  },
}
