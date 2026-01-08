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
---@field bufnr integer
---@field winId integer

---@alias qlean.Predicate fun(ctx: qlean.Context): boolean
---@alias qlean.ContextStore fun(winId: integer, bufnr: integer): qlean.Context

---@class qlean.Config
---@field keep? qlean.Predicate|nil
---@field debug? boolean
