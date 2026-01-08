# qlean.nvim Plugin Design

## Goals

- When `:q`/`:quit` runs and only one keep-designated window remains, and the current window is keep-designated, clean up non-keep windows
- Cleanup runs even when buffers are modified; whether `:q` succeeds is left to Neovim
- Never override Neovim's native behavior
  - Error messages on failure (E37, etc.)

This plugin does not try to "quit smarter." It focuses on:

> Only when closing the last keep-designated window, clean up non-keep windows.

## Core design

### keep predicate (single classification axis)

Each buffer is classified by `keep(bufnr, ctx) -> boolean`.

- `keep == true`

  - Treated as keep at quit time
  - Not auto-closed
- `keep == false`

  - Treated as non-keep at quit time
  - OK to close before quit

This is not about "editable or not," but about:

> Should this buffer remain when quitting?

#### Why `keep`

- terminal/acwrite/prompt, etc.
  - Not edits
  - Often still part of what should be kept

## Safety policy

### Handling modified buffers

- Cleanup runs even when buffers are modified
- Whether `:q` succeeds is left to Neovim

## `rule` module design

### Policy

- `keep` is a single predicate function
- Complex conditions are built by composing predicates
- No DSL or multi-stage rule engine

### Predicate signature

```lua
Predicate = function(bufnr: integer, ctx: Context): boolean
```

- `true` means keep
- `false` means non-keep

### Combinators

```lua
rule.all(p1, p2, ...)
rule.any(p1, p2, ...)
rule.not(p)
```

- Always pass a single predicate into config
- No implicit AND

#### Why combinators

- Easy to read in configuration
- Intuitive for Lua users
- Small and safe implementation

### Typical predicate builders

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

#### Policy

- Covers most cases
- Users can write custom predicates if needed

### User-defined predicate

```lua
local my_keep = function(bufnr, ctx)
  return ctx.bo.buftype == "" and ctx.name:match("/keep/") ~= nil
end
```

#### Why allow it

- With `bufnr`, the Neovim API provides almost anything
- The plugin should not absorb every use case

## Context (ctx) design

### Policy

- Cache ctx once per QuitPre
- Predicates only read ctx

### ctx contents

```lua
ctx = {
  bo = {
    buftype,
    filetype,
    buflisted,
    bufhidden,
    modifiable,
    readonly,
  },
  name = bufname,
  modified = boolean,
}
```

#### Why cache

- The same buffer is checked multiple times during QuitPre
- Simplifies predicate implementations

## QuitPre flow

1. QuitPre fires
2. Build ctx cache
3. Extract close targets

   - Only clean up when there is exactly one keep-designated window
   - All windows except the current one
   - Windows showing buffers with `keep == false`
4. Run `:close` on each (do not use `!`)
5. Return control to the quit command

## Close strategy

- Do not use `:only`
- Close individual windows only

#### Rationale

- `:only` can irreversibly change layout
- It can harm UX when quit fails

## Configuration examples

### Keep normal files and terminal

```lua
local rule = require("qlean.rule")

require("qlean").setup({
  keep = rule.any(
    rule.buftype(""),
    rule.buftype("terminal")
  ),
})
```

### Keep gitcommit

```lua
keep = rule.any(
  rule.buftype(""),
  rule.filetype({ "gitcommit", "gitrebase" })
)
```

### Auto-close neo-tree windows

```lua
keep = rule.all(
  rule.buftype(""),
  rule.not(rule.bufname("^neo%-tree://"))
)
```

## Error handling

- Always run keep predicates with `pcall`
- On error, treat as `true` (safe side)
- Notify only when `debug = true`

## Non-goals

- No force-quit like `:q!`/`:qa!`
- Do not automate saving/discarding modified buffers
- No window-attribute-based cleanup (float, etc.)

## Summary

- The only axis is `keep` (keep or non-keep)
- Cleanup runs only when one keep-designated window remains
- `rule` is a minimal predicate+combinator toolkit
- Preserve Neovim's native failure UX
