require "base"


function projectSetup()
  addDrawFunction (function ()
    local pe = particuleEffects[1]
    if not pe then return end
    local font = love.graphics.getFont()
    local timebeforereset = math.floor(pe.timeLeft)
    love.graphics.translate(width/4, height/4)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", 0, 0, font:getWidth(timebeforereset), font:getHeight())
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(timebeforereset)
  end)
  addUpdateFunction(function ()
    if #particuleEffects < 1 then
      safeLoadAndRun("editor.lua")
    end
  end)
end
