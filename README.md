# RougElite

RougElite is a small experimental roguelite written in [LÖVE2D](https://love2d.org/). It contains a minimal game engine along with two auxiliary editors for levels and particle emitters.

## Goals
* Experiment with roguelite mechanics and top‑down gameplay
* Provide an easily editable level format
* Allow creation of particle effects via a dedicated editor

## Building & Running
1. Install **LÖVE2D** (version 11 or later).
2. Run the game by pointing LÖVE at this directory:
   ```
   love .
   ```
   Alternatively you can package the contents of this repository as a `.love` archive and run it with the `love` command.

### Editors
Two editor tools are included and can be launched in the same way:

* **levelEditor/** – create and test level layouts. See `levelEditor/readme` for details.
* **particuleEmiterEditor/** – tweak particle emitter settings. See `particuleEmiterEditor/readme` for usage.

Start either editor with:
```bash
love levelEditor
love particuleEmiterEditor
```

## Directory Overview
```
main.lua                -- entry point: module wiring only
core/                   -- engine (no LÖVE references)
  base.lua              -- registries, camera, entity manager, math helpers
  level.lua             -- level generation and collision
  entity.lua            -- entity system (mixins)
  ia.lua                -- basic AI routines
  game.lua              -- game setup, spawning, HUD
domain/                 -- game content (no LÖVE references)
  ability.lua           -- ability definitions
  bestiary.lua          -- enemy definitions
adapters/               -- LÖVE2D implementation of the engine interfaces
  love_adapter.lua      -- graphics/input/time/filesystem + LÖVE callbacks
  ui.lua                -- UI widgets and menus
baselevel.file          -- sample level data
editableScript.lua      -- additional runtime script
fioriture.lua           -- particle and visual effects (mostly commented)
spec/                   -- busted unit tests (see CONTRIBUTING.md)
levelEditor/            -- level editing tool (standalone)
particuleEmiterEditor/  -- particle emitter editor (standalone)
```

With LÖVE installed you can run or modify any of these components directly. Enjoy exploring the project!
