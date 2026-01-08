# Repository Guidelines

## Project Structure & Module Organization

- Root docs describe the plugin behavior and design: `README.md`,
  `README.ja.md`, and `DESIGN.ja.md`.
- There is no source tree yet in this repository. If you add code, use the
  standard Neovim plugin layout (for example, `lua/qlean/` for Lua modules and
  `plugin/` for entrypoints) and keep docs in the root.

## Build, Test, and Development Commands

- No build or test commands are defined in this repository.
- For local development, use Neovim with a plugin manager (example from
  `README.ja.md`):
  - `:lazy` or your manager’s sync/install command after adding
    `"kyoh86/qlean.nvim"`.

## Coding Style & Naming Conventions

- Current content is Markdown; keep it concise and consistent with existing
  docs.
- Use ASCII by default.
- If adding Lua code, keep modules named after the plugin (`qlean.*`) as
  referenced in the docs, and prefer clear, lowercase, dot-separated names (for
  example, `qlean.rule`).

## Testing Guidelines

- No automated tests or test framework are present.
- If you introduce tests, document how to run them here and keep test names
  aligned with the module they cover (for example, `rule_spec.lua` for
  `qlean.rule`).

## Commit & Pull Request Guidelines

- Commit history is minimal and uses short, topic-style messages (examples:
  `doc.ja`, `Initial commit`). Keep messages short and focused on one change.
- PRs should include: a brief description, any user-facing behavior changes, and
  updated docs if behavior changes.

## Notes for Contributors

- The design doc (`DESIGN.ja.md`) is the source of truth for intent and
  constraints; keep changes aligned with its safety and behavior guarantees.
- In chat, respond in Japanese only.
