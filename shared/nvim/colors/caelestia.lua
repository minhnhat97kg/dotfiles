-- Caelestia shell's active palette (seed-derived or a preset like Catppuccin,
-- light/dark), read from the scheme.json the shell rewrites on every theme
-- change. plugins/theme.lua watches that file and re-applies this scheme.
-- Errors when the file is missing (e.g. macOS), so callers pcall it and fall
-- back to another scheme.
local path = vim.fn.expand("~/.local/state/caelestia/scheme.json")
-- macOS (modules/home/caelestia-static.nix) ships a palette per mode; pick the
-- one matching 'background', which Neovim detects from the terminal.
local per_mode = path:gsub("%.json$", "-" .. vim.o.background .. ".json")
if vim.uv.fs_stat(per_mode) then path = per_mode end

local f = assert(io.open(path))
local scheme = vim.json.decode(f:read("a"))
f:close()
local c = {}
for k, v in pairs(scheme.colours) do c[k] = "#" .. v end
assert(c.background and c.primary, "caelestia: palette not generated yet")

vim.o.background = scheme.mode == "dark" and "dark" or "light"

require("mini.base16").setup({
  palette = {
    base00 = c.background,              -- background
    base01 = c.surfaceContainerHigh,    -- statusline, floats, cursorline
    base02 = c.surfaceContainerHighest, -- selection
    base03 = c.outline,                 -- comments, line numbers
    base04 = c.onSurfaceVariant,        -- dark foreground
    base05 = c.onSurface,               -- foreground
    base06 = c.onSurface,
    base07 = c.onBackground,
    base08 = c.term1,                   -- variables, errors
    base09 = c.tertiary,                -- numbers, constants
    base0A = c.term3,                   -- types, search
    base0B = c.term2,                   -- strings
    base0C = c.term6,                   -- escapes, regex
    base0D = c.primary,                 -- functions
    base0E = c.term5,                   -- keywords
    base0F = c.error,                   -- deprecated, delimiters
  },
})

vim.g.colors_name = "caelestia"
