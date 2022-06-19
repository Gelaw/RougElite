require "base"
require "level"
require "entity"
require "bestiary"
require "ia"
require "ability"
require "game"

function start()
  gameSetup()

  --collectibles spawn
  -- addUpdateFunction(function (dt)
  --   if collectibles < 10 and math.random()>.99 then
  --     collectibles = collectibles + 1
  --     table.insert(entities, {
  --       shape = "rectangle",
  --       x = (math.random()-.5)*width, y = (math.random()-.5)*height,
  --       width = 5, height = 5, color = {.2, .8, .4},
  --       collide = function (self, collider)
  --         if collider == player then
  --           collectibles = collectibles - 1
  --           player.life = math.min(player.maxLife, player.life + 1)
  --           table.insert(particuleEffects, {
  --             x=self.x, y=self.y, color = {1, .2, .2}, nudge = 5, size = 3, timeLeft = 1.5,
  --             pluslygon = {-1,-1,  -1,-3,  1,-3,  1,-1,  3,-1,  3,1,  1,1,  1,3,  -1,3,  -1,1,  -3,1,  -3,-1},
  --             draw = function (self)
  --               love.graphics.translate(self.x, self.y)
  --               love.graphics.scale(.5)
  --               love.graphics.setColor(self.color)
  --               local t = love.timer.getTime() % 3600
  --               for i = 1, 4 do
  --                 love.graphics.push()
  --                 love.graphics.translate(math.cos(10*t+i*39)*5, math.cos(12*t+i*22)*5)
  --                 love.graphics.polygon("fill", self.pluslygon)
  --                 love.graphics.pop()
  --               end
  --             end
  --           })
  --           self.terminated = true
  --         end
  --       end
  --     })
  --   end
  -- end)

  -- --torch/candle (cosmetic only)
  -- table.insert(entities, {
  --   x = 0, y=0, radius=100,angle=0, color = {.7, .7, 0, 0.2}, shear = {x=0, y=0},
  --   polygon = { 0,0,  -2,-1,  -3,-3,  -2,-5,  0,-10,  2,-5,  3,-3,  2,-1,},
  --   draw=function (self)
  --     love.graphics.translate(self.x, self.y)
  --     love.graphics.setColor(.8, .8, .8, .8)
  --     love.graphics.rectangle("fill", -2, 0, 4, 5)
  --     love.graphics.setColor(.5, .5, .5, .5)
  --     love.graphics.rectangle("fill", -1, 0, 2, -2)
  --     love.graphics.shear(self.shear.x, self.shear.y)
  --     love.graphics.polygon("line",self.polygon)
  --     love.graphics.setColor(self.color)
  --     love.graphics.polygon("fill",self.polygon)
  --     love.graphics.push()
  --     love.graphics.setColor(self.color)
  --     love.graphics.translate(0, -3)
  --     love.graphics.scale(.5)
  --     love.graphics.polygon("fill", self.polygon)
  --     love.graphics.translate(0, 4)
  --     love.graphics.setColor({1, 0, .5, .3})
  --     love.graphics.polygon("fill", self.polygon)
  --     love.graphics.pop()
  --     love.graphics.rotate(self.angle)
  --     love.graphics.setColor(self.color)
  --     love.graphics.circle("fill", 0, 0, self.radius)
  --   end,
  --   update = function (self, dt)
  --     self.color[1], self.color[2], self.color[4] = self.color[1]+(math.random()-.5)*.01, self.color[2]+(math.random()-.5)*.01, self.color[4]+(math.random()-.5)*.01
  --     self.radius = self.radius +(math.random()-.49)*.1
  --     self.angle = self.angle + math.random()*.01
  --     self.shear = {x=self.shear.x+.01*(math.random()-.5), y=self.shear.y+.01*(math.random()-.5)}
  --   end
  -- })
  invocationCircle = {
    x= 0, y = 0,
    outerRadius = 15,
    innerRadius = 15,
    angleCuts = 5,
    shapeAngle = math.random()*2*math.pi,
    a = 0,
    color = {0, .5, .8, 1},
    hidden = true,
    draw = function (self)
      if self.hidden then return end
      love.graphics.translate(self.x, self.y)
      local pi = math.pi
      love.graphics.rotate(-.5*pi+self.shapeAngle)
      love.graphics.setColor(self.color)
      love.graphics.arc("line", "open", 0, 0, self.outerRadius, 0, self.a)
      love.graphics.arc("line", "open", 0, 0,  self.innerRadius, 0, self.a)
      for i = 1, self.angleCuts do
        angle1 = (i-1)*(2*pi)/self.angleCuts
        angle2 = i*(2*pi)/self.angleCuts
        if self.a > angle1 then
          p1 = {self.outerRadius*math.cos(angle1), self.outerRadius*math.sin(angle1)}
          p2 = {self.outerRadius*math.cos(math.pi*4/self.angleCuts+angle2), self.outerRadius*math.sin(math.pi*4/self.angleCuts+angle2)}
          ratio = math.min(1, (self.a - angle1)/(angle2 - angle1))
          dist = math.dist(p1[1], p1[2], p2[1], p2[2])*ratio
          angle = math.angle(p1[1], p1[2], p2[1], p2[2])
          love.graphics.line(p1[1], p1[2], p1[1]+dist*math.cos(angle), p1[2]+dist*math.sin(angle))
          -- love.graphics.line(p1[1], p1[2], p2[1], p2[2])
        end
      end
    end,
    update = function (self, dt)
      dt = 3*dt
      if self.a < 2*math.pi then
        self.a = self.a + 6*dt
        self.outerRadius= self.outerRadius - dt
      else
        self.outerRadius = self.outerRadius + 5*dt
        r = (math.random()-.5)*.1
        self.color[1], self.color[2], self.color[3] = self.color[1] + r, self.color[2]+ r, self.color[3]+ r
        self.color[4] = self.color[4] - dt
        if self.color[4] <= 0 then self.hidden = true end
      end
    end,
    moveTo = function (self, x, y)
      self.x = x
      self.y = y
      -- self.angleCuts = 0
      self.outerRadius = self.innerRadius
      self.shapeAngle = math.random()*2*math.pi
      self.a = 0
      self.color = {0, .5, .8, 1}
      self.hidden = false
    end
  }
  table.insert(entities, invocationCircle)
  math.randomseed(os.time())



  newGhost({x=rooms[1].x, y=rooms[1].y})


  enemyLibKeys = {}
  for e, enemy in pairs(enemiesLibrary) do
    table.insert(enemyLibKeys, e)
  end

  math.randomseed(love.timer.getTime())
  for r, room in pairs(rooms) do
    if r == 1 then
      for i = 1, 3 do
        local enemyArchetype = enemiesLibrary[enemyLibKeys[math.random(#enemyLibKeys)]]
        spawn(enemyArchetype, {x= room.x + (math.random()-.5)*room.w, y=room.y + (math.random()-.5)*room.h, team = 2, dead = true})
      end
    else
      for i = 1, 3 do
        local enemyArchetype = enemiesLibrary[enemyLibKeys[math.random(#enemyLibKeys)]]
        spawn(enemyArchetype, {x= room.x + (math.random()-.5)*room.w, y=room.y + (math.random()-.5)*room.h, team = 2})
      end
    end
  end
  StartingNumberEnemies = #enemies
  safeLoadAndRun("editableScript.lua")
end

function love.joystickpressed(joystick, button)
end

function love.keypressed(key, scancode, isrepeat)
  if key == "escape" then
    love.event.quit()
  end
  if key == "k"  then
    if player and not player.dead then
      player.dead = true
      player:onDeath()
    else
      newPlayer({x=ghost.x, y=ghost.y})
      ghost.terminated = true
    end
  end
  if key == "h" then
    showHitboxes = not showHitboxes
  end
  if key == "m" then
    levelSetup()
  end
end

function love.wheelmoved(x, y)
  -- camera.angle = camera.angle + y*0.1
end

function love.mousemoved(x, y, dx, dy)
  controlledEntity = ghost or player
  if controlledEntity then
    controlledEntity.angle = math.angle(.5*width, .5*height, x, y)
  end
end
