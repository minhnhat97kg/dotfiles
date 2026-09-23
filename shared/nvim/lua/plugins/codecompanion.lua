-- codecompanion.nvim — AI chat/inline assistant.
--
-- Two adapters are registered:
--   * mlx_ornith       — local MLX server on 127.0.0.1:8081 (fallback).
--   * mtplx_qwen       — Qwen 3.5 9B native MTP on 127.0.0.1:8000 (default).
--   * ollama_ornith    — optional Ollama fallback.
--   * deepseek_flash   — DeepSeek V4.1 Flash via the OpenCode Go gateway.
-- Press `ga` inside a chat buffer to switch adapter/model per conversation.
--
-- ollama_ornith: `ornith-1.5:coder` is a text-only rebuild of `ornith-1.5:9b`
-- (the 0.9GB vision projector layer is dropped since a code assistant never sends
-- images) with num_ctx raised to 32768 and code-tuned sampling baked into the
-- Modelfile (temperature 0.15, top_p 0.9, repeat_penalty 1.05 — Ollama's 0.8
-- default is far too random for code). The server runs with
-- OLLAMA_KV_CACHE_TYPE=q8_0 so the 32k context fits without swapping on 16GB.
-- Ornith always runs a hidden "thinking" pass; codecompanion's ollama adapter
-- talks to the native /api/chat endpoint (unlike avante's old openai-inherited
-- setup, which hit /v1 and ignored think:false) so `think = false` here
-- actually works and skips the slow reasoning step.
--
-- Battery: `num_predict` caps how many tokens a single reply can generate (the
-- dominant drain is GPU time per token), and `keep_alive` is read from
-- OLLAMA_KEEP_ALIVE so a low value lets the ~6GB model unload while idle instead
-- of forcing everything else into swap. Run nvim with a longer value on AC:
--   OLLAMA_KEEP_ALIVE=30m nvim
--
-- deepseek_flash: OpenCode Go is a flat $10/mo subscription that is already
-- authenticated on this machine, so we reuse the `opencode-go` key from
-- ~/.local/share/opencode/auth.json instead of provisioning a separate
-- DEEPSEEK_API_KEY. The gateway is OpenAI-compatible but asks callers to
-- identify themselves — a real `User-Agent` plus a stable `x-opencode-session`
-- per conversation (used for routing/prompt caching); without the session
-- header requests are rejected as unroutable. We extend the built-in `deepseek`
-- adapter (rather than openai_compatible) because it knows how to surface
-- `reasoning_content` and expose the thinking/reasoning_effort knobs this
-- reasoning model uses. Thinking is off by default to keep everyday edits
-- snappy and cheap; flip it back on from the chat settings header
-- (`show_settings`) for harder problems.

---Read the OpenCode Go API key from opencode's own auth store.
---Memoised so we only touch the filesystem once per nvim session.
---@return string|nil
local function opencode_go_api_key()
  if _G.__cc_opencode_go_key ~= nil then
    return _G.__cc_opencode_go_key
  end

  local path = vim.fs.normalize("~/.local/share/opencode/auth.json")
  local ok, lines = pcall(vim.fn.readfile, path)
  if ok and type(lines) == "table" then
    local decoded_ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
    if decoded_ok and type(decoded["opencode-go"]) == "table" then
      local key = decoded["opencode-go"].key
      if type(key) == "string" and key ~= "" then
        _G.__cc_opencode_go_key = key
        return key
      end
    end
  end

  -- Fall back to an explicitly exported key if the auth store isn't readable.
  _G.__cc_opencode_go_key = vim.env.OPENCODE_GO_API_KEY or vim.env.DEEPSEEK_API_KEY
  return _G.__cc_opencode_go_key
end

-- Stable per-nvim-session id so the gateway can route and cache prompts.
local opencode_session = "codecompanion-"
  .. string.sub(vim.fn.sha256(tostring(vim.fn.getpid()) .. tostring(os.time())), 1, 16)

require("codecompanion").setup({
  adapters = {
    http = {
      mlx_ornith = function()
        return require("codecompanion.adapters").extend("openai_compatible", {
          name = "mlx_ornith",
          formatted_name = "Ornith-1.5-9B MLX",
          env = {
            api_key = "none",
            url = "http://127.0.0.1:8081",
            chat_url = "/v1/chat/completions",
            models_endpoint = "/v1/models",
          },
          schema = {
            model = { default = "ornith-ai/Ornith-1.5-9B-MLX-4bit" },
          },
        })
      end,

      mtplx_qwen = function()
        return require("codecompanion.adapters").extend("openai_compatible", {
          name = "mtplx_qwen",
          formatted_name = "Qwen 3.5 9B MTP (MTPLX)",
          env = {
            api_key = "none",
            url = "http://127.0.0.1:8000",
            chat_url = "/v1/chat/completions",
            models_endpoint = "/v1/models",
          },
          schema = {
            model = { default = "qwen35-9b-mtp" },
          },
        })
      end,

      ollama_ornith = function()
        return require("codecompanion.adapters").extend("ollama", {
          schema = {
            model = { default = "ornith-1.5:coder" },
            think = { default = false },
            keep_alive = {
              order = 13,
              mapping = "parameters",
              type = "string",
              optional = true,
              default = function()
                return vim.env.OLLAMA_KEEP_ALIVE or "5m"
              end,
            },
            num_predict = {
              order = 14,
              mapping = "parameters.options",
              type = "number",
              optional = true,
              default = 3072,
              desc = "Max tokens to generate per reply. Lower = less GPU time = less battery.",
            },
          },
        })
      end,

      deepseek_flash = function()
        return require("codecompanion.adapters").extend("deepseek", {
          name = "opencode_go_deepseek",
          formatted_name = "DeepSeek V4.1 Flash (OpenCode Go)",
          url = "https://opencode.ai/zen/go/v1/chat/completions",
          env = {
            api_key = opencode_go_api_key,
          },
          headers = {
            ["User-Agent"] = "codecompanion.nvim/1.0",
            ["x-opencode-session"] = opencode_session,
          },
          schema = {
            -- Everyday coding edits: skip the reasoning pass for speed/cost.
            -- Toggle to "enabled" from the chat settings header when needed.
            ["thinking.type"] = { default = "disabled" },
            reasoning_effort = { default = "high" },
            model = {
              default = "deepseek-v4.1-flash",
              choices = {
                ["deepseek-v4.1-flash"] = {
                  formatted_name = "DeepSeek V4.1 Flash",
                  meta = { context_window = 1048576 },
                  opts = { can_reason = true, can_use_tools = true },
                },
                ["deepseek-v4-pro"] = {
                  formatted_name = "DeepSeek V4 Pro",
                  meta = { context_window = 1048576 },
                  opts = { can_reason = true, can_use_tools = true },
                },
                ["deepseek-v4-flash"] = {
                  formatted_name = "DeepSeek V4 Flash",
                  meta = { context_window = 1048576 },
                  opts = { can_reason = true, can_use_tools = true },
                },
              },
            },
          },
        })
      end,
    },
  },
  interactions = {
    chat = { adapter = "mtplx_qwen" },
    inline = { adapter = "mtplx_qwen" },
  },
  display = {
    chat = {
      -- Shows model/think/temperature as an editable header in the chat
      -- buffer, so `think` can be flipped to true per-conversation for
      -- harder problems without touching this config (default stays false
      -- for speed on everyday quick edits).
      show_settings = true,
    },
  },
})

vim.keymap.set({ "n", "v" }, "<leader>cc", "<cmd>CodeCompanionChat Toggle<CR>", { desc = "CodeCompanion chat" })
vim.keymap.set("v", "<leader>ca", "<cmd>CodeCompanionChat Add<CR>", { desc = "CodeCompanion add to chat" })
vim.keymap.set({ "n", "v" }, "<leader>ci", "<cmd>CodeCompanion<CR>", { desc = "CodeCompanion inline" })

-- Start a chat straight on DeepSeek V4.1 Flash (OpenCode Go) instead of Ornith.
vim.keymap.set({ "n", "v" }, "<leader>cD", function()
  require("codecompanion").chat({ params = { adapter = "deepseek_flash" } })
end, { desc = "CodeCompanion chat (DeepSeek Flash)" })

vim.keymap.set({ "n", "v" }, "<leader>cM", function()
  require("codecompanion").chat({ params = { adapter = "mtplx_qwen" } })
end, { desc = "CodeCompanion chat (Qwen MTP)" })
