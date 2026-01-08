# qlean.nvim

`qlean` is a Neovim plugin that automatically closes only the windows showing
buffers that are not part of the user's work when you run `:q`/`:quit`.

> If any work-in-progress buffers remain, it does nothing.

## What it does

- When you run `:q` (and only one keep window remains)
  - It removes leftover auxiliary UI windows (file tree/help/quickfix, etc.)
  - It closes windows that display non-kept buffers
- If there is any modified buffer considered part of the user's work, it does nothing
  - Neovim's own error messages and behavior are preserved

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

```lua
local rule = require("qlean.rule")

require("qlean").setup({
  keep = rule.buftype(""),
})
```

- Normal files (`buftype == ''`) are treated as work buffers
- Windows showing other buffers (help/quickfix/tree, etc.) are closed before quit

## What is `keep`

`keep` is a function that decides whether a buffer should be kept at quit time.

- `keep(buf) == true`

  - Treated as a work buffer and not auto-closed
- `keep(buf) == false`

  - Not a work buffer, so the window showing that buffer is closed

## Common examples

### Treat terminal buffers as work buffers

```lua
keep = rule.any(
  rule.buftype(""),
  rule.buftype("terminal")
)
```

### Include gitcommit/gitrebase as work buffers

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
  return ctx.bo.buftype == "" and ctx.name:match("/work/") ~= nil
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

## Options

### Behavior when modified buffers exist

```lua
skip_if_modified_keep = true  -- default
```

- `true` (default)
  - If any `keep` buffer is modified, qlean does nothing
- `false`
  - Non-work buffers are closed, but `:q` may still fail

## Notes

- Does not affect `:q!`/`:qa!`
- Does not automate saving or discarding buffers
