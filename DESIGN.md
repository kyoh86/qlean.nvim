# qlean.nvim Plugin Design

## Goals

- When `:q`/`:quit` runs, automatically close buffers that are not part of the current work
- If any buffer considered "work" is modified, do nothing
- Never override Neovim's native behavior
  - Modified-buffer protection
  - Error messages on failure (E37, etc.)

This plugin does not try to "quit smarter." It focuses on:

> Only when quitting is possible, clean up non-work buffers.

## Core design

### keep predicate (single classification axis)

Each buffer is classified by `keep(buf) -> boolean`.

- `keep == true`

  - Treated as in-progress at quit time
  - Not auto-closed
- `keep == false`

  - Treated as completed/UI-only
  - OK to close before quit

This is not about "editable or not," but about:

> Should this buffer remain when quitting?

#### Why `keep`

- terminal/acwrite/prompt, etc.
  - Not edits
  - Often still part of ongoing work

## Safety policy (gate)

### Modified-buffer protection

```lua
skip_if_modified_keep = true  -- default
```

- If any `keep == true` buffer is modified

  - Do not clean up UI at all
  - Fully defer to Neovim's behavior

#### Rationale

- Prevent UI changes when quit will fail
- Respect the native Neovim failure UX

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
  return ctx.bo.buftype == "" and ctx.name:match("/work/") ~= nil
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
3. Gate check

   - If any modified keep buffer exists, return
4. Extract close targets

   - Only clean up when there is exactly one keep window
   - All windows except the current one
   - Windows showing buffers with `keep == false`
5. Run `:close` on each (do not use `!`)
6. Return control to the quit command

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

- The only axis is `keep` (in-progress or not)
- Gate is presence of modified keep buffers
- `rule` is a minimal predicate+combinator toolkit
- Preserve Neovim's native failure UX
