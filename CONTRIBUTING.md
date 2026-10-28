# Contributing to RougElite

Thanks for contributing! RougElite is a small experimental roguelite in Lua
for LÖVE2D 11+. There is no build system — just LÖVE and the Lua files.

## Getting started

Requirements: [LÖVE2D 11+](https://love2d.org/) and (optionally, for linting)
[LuaRocks](https://luarocks.org/).

```bash
# run the game
love .
# run the editors (standalone apps)
love levelEditor
love particuleEmiterEditor

# lint + unit tests (recommended before committing)
luarocks install luacheck busted
luacheck *.lua
busted
```

## Project layout & architecture

Read **AGENTS.md** first — it contains the module map, the frame flow diagram
and the style rules that apply to every contribution (human or AI).

Key points:

- **Registries drive the engine**: `addDrawFunction(fn, layer)` for drawing
  (9 layers), `addUpdateFunction(fn)` for per-frame logic, `uis` for
  interactive widgets.
- **Entities are plain tables** composed via mixins:
  `entitySetup({movingEntityInit, livingEntityInit}, {params})`.
- **Shared state is global** (`player`, `camera`, `enemies`, ...) and is
  exhaustively declared in `.luacheckrc`. Any new global must be added there.

## Coding style

- Match the existing style of the file you are editing. No reformatting of
  untouched code.
- Tables of functions with explicit `self`; no classes or metatables.
- `local` by default; globals only for shared game state (declare them in
  `.luacheckrc`).
- Keep the French/English mixed naming as-is (`ia`, `fioriture`, `particule`,
  `victoire`); don't rename identifiers as part of an unrelated change.
- `levelEditor/` and `particuleEmiterEditor/` are standalone apps with their
  own (diverged) copies of `base.lua`. Don't sync them with the root copy
  unless explicitly asked.

## Before submitting

1. Run `luacheck .` — CI runs it on every push and PR, and a failure blocks
   the merge.
2. Run the game (`love .`) if your change touches gameplay, rendering, input
   or level logic. The key `H` toggles hitbox debug display; `M` regenerates
   the level; `K` triggers the death/possession flow (cheat respawn);
   `Tab`/`P` toggle the skill and monsterdex UIs.
3. Commit with a focused message describing what changed and why.

## Reporting issues

When reporting a bug, include: what you did (keys/mouse), what happened,
what you expected, and whether `luacheck` reports anything. Screenshots or
a short clip help a lot for rendering issues.

## Testing

Unit tests live in `spec/` (busted). To add tests for a module:

1. Create or extend a `spec/<domain>_spec.lua` file.
2. `require("spec.game_loader")` and call `loader.loadGame()` once.
3. Call `loader.resetWorld()` before mutating shared globals
   (entities, particuleEffects, enemies, walls, uis...) — specs run in a
   single process and these pools leak between tests otherwise.
4. Write the test against the CURRENT behavior; if you find a bug,
   fix the game code (not just the test) in the same commit, or
   document the quirk in a comment if you choose to keep it.

The `love` API is stubbed (`spec/love_stub.lua`) so no graphics context is
needed: CI runs the suite on plain Lua 5.1.
