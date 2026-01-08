# qlean.nvim

`qlean` is a Neovim plugin that prevents the “only auxiliary UI windows remain”
problem when you close your last keep-designated window.

> It runs only when there is exactly one keep-designated window.

## What it does

- On `:q`, if only one keep-designated window remains and the current window is
  keep-designated
  - It closes non-keep-designated windows (help/quickfix/tree, etc.)
- It still performs cleanup even if buffers are modified
  - Whether `:q` succeeds is left to Neovim

`qlean` does not force quitting.

## Installation

### lazy.nvim

```lua
{
  "kyoh86/qlean.nvim",
}
```

(For other plugin managers, use the same placement.)

## Basic usage

No extra commands are needed. `qlean` hooks into `QuitPre`.

## Configuration

### Minimal setup (recommended)

If you don't set anything, `buftype == ''` is treated as keep.

```lua
local rule = require("qlean.rule")

require("qlean").setup({})
```

- Normal files (`buftype == ''`) are treated as keep-designated buffers
- Windows showing other buffers (help/quickfix/tree, etc.) are closed before
  quit

## What is `keep`

`keep` is a function that decides whether a buffer should be kept at quit time.

- `keep(ctx) == true`
  - Treated as a keep-designated buffer and not auto-closed
- `keep(ctx) == false`
  - Not a keep-designated buffer, so the window showing that buffer is closed

## Common examples

### Treat terminal buffers as keep-designated buffers

```lua
keep = rule.any(
  rule.buftype(""),
  rule.buftype("terminal")
)
```

### Include gitcommit/gitrebase as keep-designated buffers

```lua
keep = rule.any(
  rule.buftype(""),
  rule.filetype("gitcommit", "gitrebase")
)
```

### Always close file trees (neo-tree, etc.)

```lua
keep = rule.all(
  rule.buftype(""),
  rule.not(rule.bufname("^neo%-tree://"))
)
```

### Write your own predicate

```lua
keep = function(ctx)
  -- ctx includes bufnr / buftype / filetype / bufname, etc.
  -- See the lua/qlean/type.lua for details.
  return ctx.bo.buftype == "" and ctx.bufname:match("/keep/") ~= nil
end
```

## `rule` module

`qlean.rule` provides utilities to build predicates for `keep`.

### Composition

```lua
rule.all(p1, p2, ...)
rule.any(p1, p2, ...)
rule.not(p)
```

### Predicate builders

```lua
rule.buftype(value, ...)
rule.filetype(value, ...)
rule.bufname(pattern)
rule.buflisted(bool)
rule.bufhidden(value, ...)
rule.modified(bool)
rule.modifiable(bool)
rule.bvar(key, value?)
```

`x` can be a `string`. Pass multiple strings as varargs.

## Notes

- Does not affect `:q!`/`:qa!`
- Does not automate saving or discarding buffers
