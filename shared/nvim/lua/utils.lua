local M = {}

function M.gh(repo) return "https://github.com/" .. repo end

M.lazy_loaded = {}
function M.lazy_require(key, specs, setup)
  if M.lazy_loaded[key] then return end
  M.lazy_loaded[key] = true
  vim.pack.add(specs, { load = true })
  setup()
end

function M.lazy_keymap(mode, lhs, key, specs, setup, action, opts)
  vim.keymap.set(mode, lhs, function()
    M.lazy_require(key, specs, setup)
    action()
  end, opts)
end

function M.menu_shortcut(keys)
  local cmd = keys:match("^<Cmd>(.-)<CR>$")
  if cmd then return ":" .. cmd end
  return (keys:gsub("<leader>", "<Space>"))
end

function M.menu_feed(keys)
  return function()
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "m", false)
  end
end

function M.menu_items(entries)
  local items = {}
  for _, entry in ipairs(entries) do
    if entry[1] == nil then
      items[#items + 1] = { name = "separator" }
    else
      items[#items + 1] = { name = entry[1], cmd = M.menu_feed(entry[2]), rtxt = M.menu_shortcut(entry[2]) }
    end
  end
  return items
end

function M.menu_open(entries, opts)
  require("menu").open(M.menu_items(entries), vim.tbl_extend("force", { border = true }, opts or {}))
end

return M
