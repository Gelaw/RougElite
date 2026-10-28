# AGENTS.md — Guide for AI coding agents (and fast-onboarding humans)

RougElite is a top-down roguelite written in pure Lua for LÖVE2D 11+.
This document tells you how the codebase is organized and what its
non-obvious invariants are, so you can contribute without breaking it.

## Running the project

```bash
love .            # the game
love levelEditor  # level editor tool (separate main.lua)
love particuleEmiterEditor  # particle emitter editor (hot-reloads editor.lua)
```

There is no build system and no external dependency: only LÖVE2D.

## Module map (load order matters)

`main.lua` requires modules in this order; later modules assume earlier
ones are loaded:

1. `base.lua` — game loop (`love.update`/`love.draw`), 9-layer draw registry,
   update registry, camera (with screen-shake), safe file loading, math and
   geometry helpers. Defines the global `camera` table.
2. `level.lua` — room/wall generation, wall collision (`wallCollision`),
   point location (`locatePoint`).
3. `entity.lua` — `newEntity()` and the mixins `movingEntityInit`,
   `livingEntityInit`, `playerInit`, `newGhost`, composed via `entitySetup`.
4. `bestiary.lua` — `enemiesLibrary`: enemy archetypes (factories).
5. `ia.lua` — state-machine AI (`newIA`, `basicIA`, tasks as tables).
6. `ability.lua` — `abilitiesLibrary` + `newAbility(name)`; cooldowns, costs,
   hitboxes, projectile logic.
7. `game.lua` — `gameSetup`/`gameStart` (called by `projectSetup` in
   `main.lua`), spawning, HUD, UIs, mouse dispatch.
8. `ui.lua` — generic UI widgets and hit-testing.

`editableScript.lua` is user-editable code executed at game start via
`safeLoadAndRun` — treat it as data, not part of the codebase.

## Core architecture: registries and globals

The engine is deliberately stateful and global. The key registries:

- `draws[1..9]` — draw callbacks per layer (1 = bottom, 9 = top, default 5).
  Registered with `addDrawFunction(fn, layer)`.
- `updates` — update callbacks, run in insertion order each frame with `dt`.
  Registered with `addUpdateFunction(fn)`.
- `uis` — UI elements (hit-tested for mouse events), drawn at layer 9.
- `entities` / `particuleEffects` — object pools swept each frame
  (`entity.terminated` removes an entity).

Important shared globals (see `.luacheckrc` for the exhaustive list):
`player`, `ghost`, `camera`, `enemies`, `rooms`, `walls`, `entities`,
`particuleEffects`, `width`, `height`, `joystick`, `closest`,
`invocationCircle`, `abilitiesHUD`, `passiveSkillUI`, `monsterdexUI`,
`passives`, `ennemyPassives`, `StartingNumberEnemies`, `teamColors`,
`mousePressedOnWorld`, `showHitboxes`, `gameover`, `mode`.

### Frame flow

```
love.update(dt)            (base.lua)
 └─ for each update fn in `updates` (insertion order)
     ├─ entity sweep: entity:update(dt), pairwise collide() checks, removal
     ├─ particle effect lifetimes
     ├─ closest-enemy tracking (game.lua)
     └─ camera:update(dt)
love.draw()                (base.lua)
 └─ translate to camera, then for layer = 1..9: run draws[layer] in order
```

Update callbacks registered earlier run first. This ordering is load-bearing:
`level.lua` registers wall display before `game.lua` registers the HUD.

## Style rules (non-obvious ones)

- **Tables of functions, no OOP.** Entities are plain tables with function
  fields (`entity.draw = function(self) ... end`). "Methods" take `self`
  explicitly. Do not introduce metatables/classes for existing code.
- **Mixins over inheritance.** `entitySetup({IAinit, ableEntityInit,
  livingEntityInit, movingEntityInit}, {params})` chains constructor
  functions; each one adds fields/updates to the entity.
- **Entity updates are per-entity**: `entity.updates` is a list of
  `function(self, dt)` run by the base `entity.update`.
- **`applyParams(dst, src)`** copies fields from src into dst — the standard
  way to configure entities/abilities.
- **Scoped locals aggressively.** Globals are reserved for the shared state
  listed above. `luacheck` (run in CI) flags any new global assignment —
  declare intentional globals in `.luacheckrc`.
- Naming: the codebase mixes French and English. `ia` = AI, `fioriture` =
  cosmetic effects, `particule` = particle, `ennemi` = enemy,
  `victoire` = victory. Keep existing names; don't rename French identifiers.

## Known quirks to respect

- `levelEditor/base.lua` and `particuleEmiterEditor/base.lua` are **copies**
  of the root `base.lua` that have diverged. Do not "fix" them to match the
  root; treat each editor as its own app. (Dedup is a known future task.)
- `baselevel.file` / `level.file` are Lua files with another extension,
  loaded via `love.filesystem.load` in `safeLoadAndRun` — errors in them are
  silently swallowed by design.
- The player-ghost-possession loop: on death, `newGhost` spawns a controllable
  ghost; colliding with a dead enemy body triggers `playerInit(collider)`.
- `mode = "IAPlaytesting"` in `gameStart` spawns an AI-controlled entity
  instead of the player — this is a testing mode, not a bug.

## Tooling

- **Lint:** `luacheck .` (config in `.luacheckrc`); runs in CI on every push/PR.
- **Tests:** none yet. Pure-logic modules (ia.lua, ability cooldown math,
  geometry in base.lua) can be tested by loading them with a stubbed `love`
  table (no need for a graphics context).
- CI workflow: `.github/workflows/ci.yml` (Lua 5.1 via luarocks, luacheck only).

## Editing rules of thumb

1. Read the module map and frame flow above before editing.
2. Prefer adding code over restructuring existing modules.
3. Run `luacheck` if available before committing; CI will run it anyway.
4. New global state must be added to `.luacheckrc` with a short comment.
5. Don't touch `levelEditor/` or `particuleEmiterEditor/` unless asked.
