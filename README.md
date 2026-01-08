# qlean.nvim

`qlean` is a Neovim plugin that prevents the “only auxiliary UI windows remain”
problem when you close your last keep window.

> It runs only when there is exactly one keep window.

## What it does

- On `:q`, if only one keep window remains and the current window is keep
  - It closes non-keep windows (help/quickfix/tree, etc.)
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

No extra commands are needed.
`qlean` hooks into `QuitPre`.

## Configuration

### Minimal setup (recommended)

If you don't set anything, `buftype == ''` is treated as keep.

```lua
local rule = require("qlean.rule")

require("qlean").setup({
  keep = rule.buftype(""), -- default
})
```

- Normal files (`buftype == ''`) are treated as keep buffers
- Windows showing other buffers (help/quickfix/tree, etc.) are closed before quit

## What is `keep`

`keep` is a function that decides whether a buffer should be kept at quit time.

- `keep(bufnr, ctx) == true`

  - Treated as a keep buffer and not auto-closed
- `keep(bufnr, ctx) == false`

  - Not a keep buffer, so the window showing that buffer is closed

## Common examples

### Treat terminal buffers as keep buffers

```lua
keep = rule.any(
  rule.buftype(""),
  rule.buftype("terminal")
)
```

### Include gitcommit/gitrebase as keep buffers

```lua
keep = rule.any(
  rule.buftype(""),
  rule.filetype({ "gitcommit", "gitrebase" })
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
keep = function(bufnr, ctx)
  -- ctx includes buftype / filetype / name, etc.
  return ctx.bo.buftype == "" and ctx.name:match("/keep/") ~= nil
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
rule.buftype(x)
rule.filetype(x)
rule.bufname(pattern)
rule.buflisted(bool)
rule.bufhidden(x)
rule.modified(bool)
rule.modifiable(bool)
rule.bvar(key, value?)
```

`x` can be a `string` or `string[]`.

## Notes

- Does not affect `:q!`/`:qa!`
- Does not automate saving or discarding buffers
