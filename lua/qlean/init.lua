local M = {}

---@type qlean.Config
local default_config = {
  keep = function(ctx)
    return (ctx.bo.buftype or "") == ""
  end,
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

---@return qlean.Context
local function build_ctx(winId, bufnr)
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
    bufnr = bufnr,
    winId = winId,
  }
end

---@return qlean.ContextStore
local function ctx_cache()
  ---@type table<string, qlean.Context>
  local cache = {}
  ---@param winId integer
  ---@param bufnr integer
  return function(winId, bufnr)
    local key = string.format("%d-%d", winId, bufnr)
    local ctx = cache[key]
    if ctx then
      return ctx
    end

    ctx = build_ctx(winId, bufnr)
    cache[key] = ctx
    return ctx
  end
end

local function keep_predicate(ctx)
  local keep = state.config.keep
  if not keep then
    return true
  end

  local ok, result = pcall(keep, ctx)
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

---@param winId integer
---@param curWinId integer
---@param ctx_of qlean.ContextStore
---@return "abort"|"cleanup"|"keep"|"ignore"
local function classify_win(winId, curWinId, ctx_of)
  if not vim.api.nvim_win_is_valid(winId) then
    return ACTION.ignore
  end

  local buf = vim.api.nvim_win_get_buf(winId)
  if not vim.api.nvim_buf_is_valid(buf) then
    return ACTION.ignore
  end

  local ctx = ctx_of(winId, buf)
  if keep_predicate(ctx) then
    return ACTION.keep
  end

  -- If the current window is non-keep, abort cleanup.
  if winId == curWinId then
    return ACTION.abort
  end

  return ACTION.cleanup
end

---@param ctx_of qlean.ContextStore
---@return integer[] Window-IDs to cleanup
local function collect_cleanup_wins(ctx_of)
  local current = vim.api.nvim_get_current_win()
  local exist = false
  local winIds = {}

  for _, winId in ipairs(vim.api.nvim_list_wins()) do
    local action = classify_win(winId, current, ctx_of)
    if action == ACTION.keep then
      if exist then
        -- Cleanup happens only when there is exactly one keep-designated window.
        -- So if the another one is exist, don't close any window.
        return {}
      end
      exist = true
    elseif action == ACTION.abort then
      -- If the current window is non-keep, abort cleanup.
      return {}
    elseif action == ACTION.cleanup then
      -- Non-keep, non-current candidates for cleanup.
      table.insert(winIds, winId)
    end
  end
  return winIds
end

--- @param winIds integer[]
local function close_windows(winIds)
  for _, winId in ipairs(winIds) do
    if vim.api.nvim_win_is_valid(winId) then
      pcall(vim.api.nvim_win_call, winId, function()
        vim.cmd("silent! noautocmd close")
      end)
    end
  end
end

local in_quit_pre = false

local function on_quit_pre()
  if in_quit_pre then
    return
  end
  in_quit_pre = true
  close_windows(collect_cleanup_wins(ctx_cache()))
  in_quit_pre = false
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
