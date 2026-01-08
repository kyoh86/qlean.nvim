local M = {}

local rule = require("qlean.rule")

---@class qlean.ContextBo
---@field buftype string
---@field filetype string
---@field buflisted boolean
---@field bufhidden string
---@field modifiable boolean
---@field readonly boolean
---@field modified boolean

---@class qlean.Context
---@field bo qlean.ContextBo
---@field bufname string

---@alias qlean.Predicate fun(bufnr: integer, ctx: qlean.Context): boolean

---@class qlean.Config
---@field keep? qlean.Predicate|nil
---@field debug? boolean

---@type qlean.Config
local default_config = {
  keep = rule.buftype(""),
  debug = false,
}

local state = {
  config = vim.deepcopy(default_config),
}

local function notify(message)
  if not state.config.debug then
    return
  end

  vim.schedule(function()
    vim.notify(message, vim.log.levels.WARN)
  end)
end

local function get_buf_option(bufnr, name, fallback)
  local ok, value = pcall(vim.api.nvim_get_option_value, name, { buf = bufnr })
  if ok then
    return value
  end
  return fallback
end

local function build_ctx(bufnr)
  local bufname_ok, bufname = pcall(vim.api.nvim_buf_get_name, bufnr)
  if not bufname_ok then
    bufname = ""
  end

  return {
    bo = {
      buftype = get_buf_option(bufnr, "buftype", ""),
      filetype = get_buf_option(bufnr, "filetype", ""),
      buflisted = get_buf_option(bufnr, "buflisted", false),
      bufhidden = get_buf_option(bufnr, "bufhidden", ""),
      modifiable = get_buf_option(bufnr, "modifiable", false),
      readonly = get_buf_option(bufnr, "readonly", false),
      modified = get_buf_option(bufnr, "modified", false),
    },
    bufname = bufname,
  }
end

local function ctx_cache()
  local cache = {}
  return function(bufnr)
    local ctx = cache[bufnr]
    if ctx then
      return ctx
    end

    ctx = build_ctx(bufnr)
    cache[bufnr] = ctx
    return ctx
  end
end

local function keep_predicate(bufnr, ctx)
  local keep = state.config.keep
  if not keep then
    return true
  end

  local ok, result = pcall(keep, bufnr, ctx)
  if not ok then
    notify("qlean: keep predicate error: " .. tostring(result))
    return true
  end

  return result and true or false
end

local ACTION = {
  abort = "abort",
  cleanup = "cleanup",
  keep = "keep",
  ignore = "ignore",
}

local function classify_win(win, current, ctx_of)
  if not vim.api.nvim_win_is_valid(win) then
    return ACTION.ignore
  end

  local buf = vim.api.nvim_win_get_buf(win)
  if not vim.api.nvim_buf_is_valid(buf) then
    return ACTION.ignore
  end

  local ctx = ctx_of(buf)
  if keep_predicate(buf, ctx) then
    return ACTION.keep
  end

  -- If the current window is non-keep, abort cleanup.
  if win == current then
    return ACTION.abort
  end

  return ACTION.cleanup
end

local function collect_cleanup_wins(ctx_of)
  local current = vim.api.nvim_get_current_win()
  local keep_count = 0
  local cleanup_wins = {}

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local action = classify_win(win, current, ctx_of)
    if action == ACTION.keep then
      keep_count = keep_count + 1
      if keep_count >= 2 then
        -- Cleanup happens only when there is exactly one keep window.
        return {}
      end
    elseif action == ACTION.abort then
      -- If the current window is non-keep, abort cleanup.
      return {}
    elseif action == ACTION.cleanup then
      -- Non-keep, non-current candidates for cleanup.
      table.insert(cleanup_wins, win)
    end
  end

  if keep_count == 1 then
    return cleanup_wins
  end
  return {}
end

local function close_windows(wins)
  for _, win in ipairs(wins) do
    if vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_close, win, false)
    end
  end
end

local function on_quit_pre()
  local ctx_of = ctx_cache()

  local wins = collect_cleanup_wins(ctx_of)
  if #wins > 0 then
    close_windows(wins)
  end
end

---@param opts qlean.Config|nil
function M.setup(opts)
  state.config = vim.tbl_deep_extend("force", {}, default_config, opts or {})

  local group = vim.api.nvim_create_augroup("qlean", { clear = true })
  vim.api.nvim_create_autocmd("QuitPre", {
    group = group,
    callback = on_quit_pre,
  })
end

return M
