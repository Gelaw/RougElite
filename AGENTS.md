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

## Module map (core / adapter / domain split)

The codebase follows a ports-and-adapters layout. **core/ and domain/
contain NO `love.*` references**: they talk to adapter interfaces only.
This keeps the engine testable without LÖVE and portable to other
frameworks (a port = one new adapters/ directory).

```
main.lua          wiring only: requires modules in order
core/             engine (pure logic + injected rendering interface)
  base.lua        registries (9 draw layers, updates), camera, entity
                  manager, math/geometry, adapter injection points
  level.lua       room/wall generation, wallCollision, locatePoint,
                  level serialization (writeLevelFile hook)
  entity.lua      newEntity + mixins (moving/living/player/ghost)
  ia.lua          state-machine AI (tasks), IAtargetingUpdate
  game.lua        gameSetup/gameStart, spawning, HUD, invocation circle
domain/           game content (pure logic + injected interfaces)
  ability.lua     abilitiesLibrary + newAbility: cooldowns, hitboxes
  bestiary.lua    enemiesLibrary: enemy archetypes
adapters/         the ONLY files that touch the LÖVE API
  love_adapter.lua  implements G=getTimestamp/random/loadLevelFile/
                    Mouse/Keyboard/Joystick + LÖVE callbacks (load/
                    update/draw/keypressed/mousepressed...)
  ui.lua            UI widget tree + hit-testing (draws via love.graphics)
```

Adapter interfaces (globals, defaulted in core/base.lua, implemented in
adapters/love_adapter.lua, doubled in spec/game_loader.lua):

- `G` — rendering (love.graphics surface: translate, setColor, rectangle, ...)
- `getTimestamp()` — wall clock (love.timer.getTime)
- `random([a[, b]])` — RNG (love.math.random)
- `loadLevelFile(name)` / `writeLevelFile(text)` — level IO
- `Mouse` / `Keyboard` / `Joystick` — input
- `refreshJoystick()` — rebind the shared `joystick` global
- shared `joystick` global — first gamepad object (its methods are
  provided by LÖVE; tests leave it nil)

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

- **Lint:** `luacheck *.lua` (config in `.luacheckrc`); runs in CI on every push/PR.
  Only the root game files are linted (editors and spec/ are excluded).
- **Tests:** busted suite in `spec/` — run `busted` from the repo root.
  - `spec/love_stub.lua` injects a permissive fake `love` table so game
    modules load without a graphics context.
  - `spec/game_loader.lua` loads all root modules in main.lua order
    (call `loader.loadGame()` once per spec file) and offers
    `loader.resetWorld()` to clear the shared entity/particle pools
    between tests (specs run in ONE process: always reset mutable globals).
  - One spec file per domain: base math/geometry/camera, entity mixins,
    abilities/hitInHitbox, AI state machine, UI press/release, level
    generation/serialization, spawn/passives/invocation circle.
- CI workflow: `.github/workflows/ci.yml`: luacheck + busted (Lua 5.1
  via luarocks) + a headless LÖVE boot smoke test (xvfb + software GL).

## Editing rules of thumb

1. Read the module map and frame flow above before editing.
2. Prefer adding code over restructuring existing modules.
3. Run `luacheck` if available before committing; CI will run it anyway.
4. New global state must be added to `.luacheckrc` with a short comment.
5. Don't touch `levelEditor/` or `particuleEmiterEditor/` unless asked.
