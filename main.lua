--------------------------------------------------------------------
-- main.lua : LÖVE entry point — wiring only.
--
-- Load order (later modules assume earlier ones):
--   1. core/*      engine: registries, camera, entities, IA, level, game
--   2. domain/*    game content: abilities, bestiary
--   3. adapters/*  LÖVE implementation of the engine interfaces + UI
--
-- core/ and domain/ contain NO love.* references: they talk to the
-- adapter interfaces (G, getTimestamp, random, loadLevelFile, Mouse,
-- Keyboard, Joystick...). See AGENTS.md for the full map.
--------------------------------------------------------------------

require "core.base"
require "core.level"
require "core.entity"
require "domain.bestiary"
require "core.ia"
require "domain.ability"
require "core.game"
require "adapters.ui"
require "adapters.love_adapter"

function projectSetup()
  gameSetup()
  gameStart()
  safeLoadAndRun("editableScript.lua")
end
