-- Linter + formatter. Hover is turned off at LspAttach (see init.lua) so
-- basedpyright owns documentation; ruff's hover only renders rule text.
-- Formatting runs through conform's ruff_fix/ruff_format, not this client.
return {
  cmd = { "ruff", "server" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "ruff.toml", ".ruff.toml", ".git" },
  init_options = {
    settings = {
      -- Per-project rules belong in the project's pyproject.toml / ruff.toml;
      -- leaving this empty means ruff picks those up as it normally would.
    },
  },
}
