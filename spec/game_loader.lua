--------------------------------------------------------------------
-- spec/game_loader.lua : loads the engine into the test environment,
-- with the love stub and pure-Lua test doubles for the adapter
-- interfaces (G, Mouse, Keyboard, Joystick, getTimestamp, random).
--
-- core/ and domain/ contain NO love.* references: tests exercise the
-- engine directly. adapters/ are NOT loaded in unit tests (they are
-- LÖVE-specific and covered by the CI smoke test instead).
--------------------------------------------------------------------

require("spec.love_stub")

local loaded = false

local function loadGame()
  if loaded then return _G end
  loaded = true

  -- Test doubles for the adapter interfaces (normally provided by
  -- adapters/love_adapter.lua at runtime).
  _G.G = _G.G or setmetatable({}, {
    __index = function(t, k)
      local fn = function() return nil end
      rawset(t, k, fn)
      return fn
    end
  })
  _G.getTimestamp = _G.getTimestamp or function() return 0 end
  _G.Mouse = _G.Mouse or {
    getPosition = function() return 0, 0 end,
    isDown = function() return false end,
  }
  _G.Keyboard = _G.Keyboard or {
    isDown = function() return false end,
  }
  _G.Joystick = _G.Joystick or {
    getJoysticks = function() return nil end,
  }

  -- Minimal prerequisites normally created by the LÖVE adapter's
  -- love.load (unavailable in tests).
  _G.entities = {}
  _G.particuleEffects = {}
  _G.enemies = {}
  _G.walls = {}
  _G.uis = {}
  _G.width = 800
  _G.height = 600
  -- projectSetup is normally defined by main.lua, which we do not
  -- load (it requires adapters); provide a no-op instead.
  if _G.projectSetup == nil then
    _G.projectSetup = function() end
  end

  -- Lua 5.2+ removed math.atan2; the game (targeting Lua 5.1/LuaJIT)
  -- uses it extensively. Shim it for tests on newer interpreters.
  if not math.atan2 then
    math.atan2 = function(y, x) return math.atan(y, x) end
  end

  -- Engine modules in main.lua's load order. adapters/ui.lua is
  -- included (it works with the love stub); only love_adapter.lua —
  -- which registers LÖVE callbacks — is excluded.
  local modules = {
    "core/base", "core/level", "core/entity", "domain/bestiary",
    "core/ia", "domain/ability", "core/game", "adapters/ui",
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
