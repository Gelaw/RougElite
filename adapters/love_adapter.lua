--------------------------------------------------------------------
-- adapters/love_adapter.lua : the ONLY file that knows the LÖVE API.
-- Implements the engine's adapter interfaces on top of love.*:
--   G            -> love.graphics
--   getTimestamp -> love.timer.getTime
--   random       -> love.math.random
--   loadLevelFile / writeLevelFile -> love.filesystem
--   Mouse / Keyboard / Joystick   -> love.mouse / love.keyboard / ...
-- Also registers the LÖVE callbacks (load/update/draw/input) that
-- drive the engine's registries.
--------------------------------------------------------------------

--------------------------------------------------------------------
-- Interface implementations
--------------------------------------------------------------------
G = love.graphics
getTimestamp = love.timer.getTime
random = love.math.random

function loadLevelFile(name)
  return love.filesystem.load(name)
end

function writeLevelFile(text)
  return love.filesystem.write("level.file", text)
end

-- Input adapter: the engine reads inputs through these tables only.
Mouse = {
  getPosition = function() return love.mouse.getPosition() end,
  isDown = function(...) return love.mouse.isDown(...) end,
}
Keyboard = {
  isDown = function(...) return love.keyboard.isDown(...) end,
}
-- Joystick adapter: static lookup table for the engine
-- (Joystick.getJoysticks), plus refreshJoystick() to (re)bind the
-- shared `joystick` global used by entity/ability input code.
Joystick = {
  getJoysticks = function() return love.joystick.getJoysticks() end,
}

function refreshJoystick()
  local joysticks = love.joystick.getJoysticks()
  joystick = joysticks and joysticks[1] or nil
end

--------------------------------------------------------------------
-- Engine callbacks (LÖVE -> engine)
--------------------------------------------------------------------
function love.load(arg)
  love.window.setMode(0, 0)
  width  = love.graphics.getWidth()
  height = love.graphics.getHeight()
  love.graphics.setFont(love.graphics.newFont(11))
  love.graphics.setBackgroundColor(.4, .4, .4)
  refreshJoystick()
  init()
  projectSetup()
end

function love.update(dt)
  if gameover then return end
  for u, update in pairs(updates) do
    if type(update) ~= "function" then
      love.event.quit()
    end
    update(dt)
  end
  camera:update(dt)
end

function love.draw()
  love.graphics.translate(width/2, height/2)
  camera:apply()
  for l, layer in pairs(draws) do
    for d, draw in pairs(layer) do
      if type(draw) ~= "function" then
        love.event.quit()
      end
      love.graphics.push()
      draw()
      love.graphics.pop()
    end
  end
end

function love.keypressed(key, scancode, isrepeat)
  if key == "escape" then
    if not passiveSkillUI.hidden then
      passiveSkillUI.hidden = true
    else
      love.event.quit()
    end
  end
  if key == "k"  then
    if player and not player.dead then
      player.dead = true
      player:onDeath()
    elseif ghost then
      newCheatPlayer({x=ghost.x, y=ghost.y})
      ghost.terminated = true
      ghost = nil
    end
  end
  if key == "h" then
    showHitboxes = not showHitboxes
  end
  if key == "m" then
    levelSetup()
  end
  if passiveSkillUI and ( key == "tab") then
    passiveSkillUI.hidden = not passiveSkillUI.hidden
  end
  if monsterdexUI and ( key == "p") then
    monsterdexUI.hidden = not monsterdexUI.hidden
  end
end

function love.mousepressed(x, y, button, isTouch)
  gameMousePress(x, y, button)
end

function love.mousereleased(x, y, button, isTouch)
  gameMouseRelease(x, y, button)
end

function love.wheelmoved(x, y)
  -- camera.angle = camera.angle + y*0.1
end

function love.mousemoved(x, y, dx, dy)
end

function love.joystickpressed(joystick, button)
end
