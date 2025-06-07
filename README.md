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
ability.lua             -- ability definitions
base.lua                -- shared utilities and drawing helpers
baselevel.file          -- sample level data
bestiary.lua            -- enemy definitions
editableScript.lua      -- additional runtime script
entity.lua              -- entity system
fioriture.lua           -- particle and visual effects
ia.lua                  -- basic AI routines
level.lua               -- level management
levelEditor/            -- level editing tool
main.lua                -- LÖVE entry point
particuleEmiterEditor/  -- particle emitter editor
ui.lua                  -- UI widgets and menus
```

With LÖVE installed you can run or modify any of these components directly. Enjoy exploring the project!
