local M = {}

local function normalize(value)
  if type(value) == "table" then
    return value
  end
  return { value }
end

local function contains(list, value)
  for _, item in ipairs(list) do
    if item == value then
      return true
    end
  end
  return false
end

function M.all(...)
  local predicates = { ... }
  return function(bufnr, ctx)
    for _, predicate in ipairs(predicates) do
      if not predicate(bufnr, ctx) then
        return false
      end
    end
    return true
  end
end

function M.any(...)
  local predicates = { ... }
  return function(bufnr, ctx)
    for _, predicate in ipairs(predicates) do
      if predicate(bufnr, ctx) then
        return true
      end
    end
    return false
  end
end

M["not"] = function(predicate)
  return function(bufnr, ctx)
    return not predicate(bufnr, ctx)
  end
end

function M.buftype(value)
  local values = normalize(value)
  return function(_, ctx)
    return contains(values, ctx.bo.buftype or "")
  end
end

function M.filetype(value)
  local values = normalize(value)
  return function(_, ctx)
    return contains(values, ctx.bo.filetype or "")
  end
end

function M.bufname(pattern)
  return function(_, ctx)
    return (ctx.name or ""):match(pattern) ~= nil
  end
end

function M.buflisted(value)
  return function(_, ctx)
    return ctx.bo.buflisted == value
  end
end

function M.bufhidden(value)
  local values = normalize(value)
  return function(_, ctx)
    return contains(values, ctx.bo.bufhidden or "")
  end
end

function M.modified(value)
  return function(_, ctx)
    return ctx.modified == value
  end
end

function M.modifiable(value)
  return function(_, ctx)
    return ctx.bo.modifiable == value
  end
end

function M.bvar(key, value)
  if value == nil then
    return function(bufnr)
      local ok, _ = pcall(vim.api.nvim_buf_get_var, bufnr, key)
      return ok
    end
  end

  return function(bufnr)
    local ok, var_value = pcall(vim.api.nvim_buf_get_var, bufnr, key)
    if not ok then
      return false
    end
    return var_value == value
  end
end

return M
