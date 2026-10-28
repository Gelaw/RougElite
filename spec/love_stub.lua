--------------------------------------------------------------------
-- spec/love_stub.lua : fake LÖVE2D API so game modules can be loaded
-- in unit tests without a graphics context.
--
-- Usage: require this BEFORE loading game modules; it injects a
-- permissive `love` global into the test environment.
-- Every love.* field access returns either a table (for nested
-- fields like love.graphics) or a no-op function.
--------------------------------------------------------------------

local function makeNode()
  return setmetatable({}, {
    __index = function(t, k)
      -- nested table by default, function-ized on call
      local child = makeNode()
      rawset(t, k, child)
      return child
    end,
    __call = function()
      return nil
    end
  })
end

love = makeNode()

-- love.filesystem.load must behave like Lua's loadfile/load: return a
-- chunk (or nil + error) instead of a table.
love.filesystem.load = function(name)
  if name and type(name) == "string" and name:match("%.lua$") then
    return loadfile(name)
  end
  return nil, "not a lua file: " .. tostring(name)
end

-- love.timer.getTime: deterministic counter for tests that need
-- reproducible "time" (advance manually if needed).
local stubTime = 0
love.timer.getTime = function()
  return stubTime
end

-- love.timer.step also used by some modules
love.timer.step = function()
  return 0.016
end

-- Common defaults some modules read at load or during tests.
love.graphics.getWidth = function() return 800 end
love.graphics.getHeight = function() return 600 end
love.mouse.getPosition = function() return 0, 0 end
love.mouse.isDown = function() return false end
love.keyboard.isDown = function() return false end
love.joystick.getJoysticks = function() return nil end

return love
