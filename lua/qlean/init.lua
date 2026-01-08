local M = {}

local default_config = {
  keep = nil,
  skip_if_modified_keep = true,
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
  local name_ok, name = pcall(vim.api.nvim_buf_get_name, bufnr)
  if not name_ok then
    name = ""
  end

  return {
    bo = {
      buftype = get_buf_option(bufnr, "buftype", ""),
      filetype = get_buf_option(bufnr, "filetype", ""),
      buflisted = get_buf_option(bufnr, "buflisted", false),
      bufhidden = get_buf_option(bufnr, "bufhidden", ""),
      modifiable = get_buf_option(bufnr, "modifiable", false),
      readonly = get_buf_option(bufnr, "readonly", false),
    },
    name = name,
    modified = get_buf_option(bufnr, "modified", false),
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

local function gate_modified_keep(ctx_of)
  if not state.config.skip_if_modified_keep then
    return false
  end

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      local ctx = ctx_of(buf)
      if keep_predicate(buf, ctx) and ctx.modified then
        return true
      end
    end
  end

  return false
end

local function close_non_keep_windows(ctx_of)
  local current = vim.api.nvim_get_current_win()

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if win ~= current and vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_buf_is_valid(buf) then
        local ctx = ctx_of(buf)
        if not keep_predicate(buf, ctx) then
          pcall(vim.api.nvim_win_close, win, false)
        end
      end
    end
  end
end

local function on_quit_pre()
  local ctx_of = ctx_cache()

  if gate_modified_keep(ctx_of) then
    return
  end

  close_non_keep_windows(ctx_of)
end

function M.setup(opts)
  state.config = vim.tbl_deep_extend("force", {}, default_config, opts or {})

  local group = vim.api.nvim_create_augroup("qlean", { clear = true })
  vim.api.nvim_create_autocmd("QuitPre", {
    group = group,
    callback = on_quit_pre,
  })
end

return M
