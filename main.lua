require "base"

function test()
  local joysticks = love.joystick.getJoysticks()
  joystick = joysticks[1]
  gridSetup()
  camera.scale = 2
  player = {
    --display
    shape = "rectangle",
    color = {.4, .6, .2},
    x=10, y=10, width=50, height=50, angle=0,
    --movement
    speed={x=0, y=0}, speedDrag= 0.9, maxJoystikAcceleration = 300,
    --actions
    dash = nil
  }
  player.update = function (self, dt)
    a1, a2, a3 = joystick:getAxes()

    if math.abs(a1)>0.3 or math.abs(a2)>0.3 then
      self.angle = -math.atan2(a1, a2)+math.rad(90)
      self.speed.x = self.speed.x + self.maxJoystikAcceleration*a1*math.abs(a1)*dt
      self.speed.y = self.speed.y + self.maxJoystikAcceleration*a2*math.abs(a2)*dt
    else
      self.speed.x = self.speed.x * self.speedDrag
      self.speed.y = self.speed.y * self.speedDrag
    end
    self.x = self.x + self.speed.x * dt
    self.y = self.y + self.speed.y * dt

    if self.dash then
      self.dash.timer = self.dash.timer - dt
      if self.dash.timer < 0 then
        self.dash = nil
      else
        self.x = self.x + math.cos(self.dash.angle)*600 * dt
        self.y = self.y + math.sin(self.dash.angle)*600 * dt
      end
    elseif joystick:isDown(6) then
      self.dash = {timer = 1, angle = self.angle}
    end
  end
  table.insert(entities, player)

  camera.mode = {"follow", player}
  addUpdateFunction(
    function (dt)
      if joystick:isDown(7) then
        camera.scale = math.max(camera.scale - .2*dt, .5)
      else
        camera.scale = math.min(camera.scale + .2*dt, 2)
      end
    end
  )
end

function gridSetup()
  --grid
  local canvas = love.graphics.newCanvas(width, height)

  love.graphics.setCanvas(canvas)
  love.graphics.setColor(1,1,1)
  love.graphics.setLineStyle("rough")
  for x = 1, width, 60 do
    love.graphics.line(x, 0, x, height)
  end
  for y = 1, height, 60 do
    love.graphics.line(0, y, width, y)
  end
  love.graphics.setCanvas()
  addDrawFunction(function ()
    love.graphics.setColor(1,1,1)
    love.graphics.draw(canvas, -width/2, -height/2)
  end, 4)
end
function love.joystickpressed(joystick, button)
  -- print(button)
end
