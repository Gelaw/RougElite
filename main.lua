require "base"
require "level"
require "entity"
require "bestiary"
require "ia"
require "ability"
require "game"
require "ui"

function projectSetup()
  gameSetup()
  gameStart()
  safeLoadAndRun("editableScript.lua")
end

function love.joystickpressed(joystick, button)
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
    else
      newPlayer({x=ghost.x, y=ghost.y})
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
  if passiveSkillUI and (key == "p" or key == "tab") then
    passiveSkillUI.hidden = not passiveSkillUI.hidden
  end
end

function love.wheelmoved(x, y)
  -- camera.angle = camera.angle + y*0.1
end

function love.mousemoved(x, y, dx, dy)
end

function love.mousepressed(x, y, button, isTouch)
  gameMousePress(x, y, button)
end

function love.mousereleased(x, y, button, isTouch)
  gameMouseRelease(x, y, button)
end
