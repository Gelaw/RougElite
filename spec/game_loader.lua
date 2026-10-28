--------------------------------------------------------------------
-- spec/game_loader.lua : loads the game modules in main.lua order
-- into the current (test) environment, with the love stub injected.
--
-- Call loadGame() from a spec file; it loads all root modules exactly
-- once per busted process and returns the environment table (_G).
--
-- Modules define globals (documented in .luacheckrc); tests read
-- them from _G after loading.
--------------------------------------------------------------------

require("spec.love_stub")

local loaded = false

local function loadGame()
  if loaded then return _G end
  loaded = true

  -- Minimal prerequisites normally created by base.lua's init()
  -- (which runs in love.load, unavailable in tests).
  _G.entities = {}
  _G.particuleEffects = {}
  _G.walls = {}
  _G.uis = {}
  _G.enemies = {} -- normally created by gameSetup()
  _G.width = 800
  _G.height = 600
  -- projectSetup is normally defined by main.lua, which we do not
  -- load (it registers LÖVE callbacks); provide a no-op so base.lua's
  -- love.load can be skipped entirely.
  if _G.projectSetup == nil then
    _G.projectSetup = function() end
  end

  -- Lua 5.2+ removed math.atan2; the game (targeting Lua 5.1/LuaJIT)
  -- uses it extensively. Shim it for tests on newer interpreters.
  if not math.atan2 then
    math.atan2 = function(y, x) return math.atan(y, x) end
  end

  local modules = {
    "base", "level", "entity", "bestiary",
    "ia", "ability", "game", "ui",
  }
  for _, m in ipairs(modules) do
    local chunk = assert(loadfile(m .. ".lua"), "cannot load " .. m .. ".lua")
    chunk()
  end
  return _G
end

-- resetWorld(): clear mutable shared state between tests. busted runs
-- all specs in one process; entity/particle/enemy pools accumulate
-- otherwise. Call at the top of a describe block (or in beforeEach).
local function resetWorld()
  _G.entities = {}
  _G.particuleEffects = {}
  _G.enemies = {}
  _G.walls = {}
  _G.uis = {}
  _G.player = nil
  _G.ghost = nil
  _G.closest = nil
  _G.pressed = nil
end

return { loadGame = loadGame, resetWorld = resetWorld }
