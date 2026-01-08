local M = {}

---@param p qlean.Predicate
---@vararg qlean.Predicate
---@return qlean.Predicate
function M.all(p, ...)
  local predicates = { p, ... }
  return function(ctx)
    for _, predicate in ipairs(predicates) do
      if not predicate(ctx) then
        return false
      end
    end
    return true
  end
end

---@param p qlean.Predicate
---@vararg qlean.Predicate
---@return qlean.Predicate
function M.any(p, ...)
  local predicates = { p, ... }
  return function(ctx)
    for _, predicate in ipairs(predicates) do
      if predicate(ctx) then
        return true
      end
    end
    return false
  end
end

---@param predicate qlean.Predicate
---@return qlean.Predicate
M["not"] = function(predicate)
  return function(ctx)
    return not predicate(ctx)
  end
end

---@param value string
---@vararg string
---@return qlean.Predicate
function M.buftype(value, ...)
  local values = { value, ... }
  return function(ctx)
    return vim.list_contains(values, ctx.bo.buftype or "")
  end
end

---@param value string
---@vararg string
---@return qlean.Predicate
function M.filetype(value, ...)
  local values = { value, ... }
  return function(ctx)
    return vim.list_contains(values, ctx.bo.filetype or "")
  end
end

---@param pattern string
---@return qlean.Predicate
function M.bufname(pattern)
  return function(ctx)
    return (ctx.bufname or ""):match(pattern) ~= nil
  end
end

---@return qlean.Predicate
function M.buflisted()
  return function(ctx)
    return ctx.bo.buflisted
  end
end

---@param value string
---@vararg string
---@return qlean.Predicate
function M.bufhidden(value, ...)
  local values = { value, ... }
  return function(ctx)
    return vim.list_contains(values, ctx.bo.bufhidden or "")
  end
end

---@return qlean.Predicate
function M.modified()
  return function(ctx)
    return ctx.bo.modified
  end
end

---@return qlean.Predicate
function M.modifiable()
  return function(ctx)
    return ctx.bo.modifiable
  end
end

---@param key string
---@param value? any
---@return qlean.Predicate
function M.bvar(key, value)
  if value == nil then
    return function(ctx)
      local ok, _ = pcall(vim.api.nvim_buf_get_var, ctx.bufnr, key)
      return ok
    end
  end

  return function(ctx)
    local ok, var_value = pcall(vim.api.nvim_buf_get_var, ctx.bufnr, key)
    if not ok then
      return false
    end
    return var_value == value
  end
end

return M
