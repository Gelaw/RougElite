require "base"
require "level"
require "entity"
require "bestiary"
require "ia"
require "ability"

function test()
  local joysticks = love.joystick.getJoysticks()
  if joysticks then joystick = joysticks[1] end

  lifebarWidth = 30

  --player hud
  addDrawFunction(function()
    if not player then return end
    --lifebar display
    love.graphics.translate(player.x, player.y)
    love.graphics.translate(-15, -15)
    if player.life then
      love.graphics.setColor(.1, .1, .2, .3)
      love.graphics.rectangle("fill", 3, 0, lifebarWidth, 5)
      if player.life > 0 then
        love.graphics.setColor(.1, .8, .2, .7)
      else
        love.graphics.setColor(.8, .2, .1, .2)
      end
      love.graphics.rectangle("fill", 3, 0, lifebarWidth*math.max(player.life, 0)/player.maxLife, 5)
      love.graphics.setColor(.8, .2, .1, .9)
      love.graphics.rectangle("fill", 3+lifebarWidth*math.max(player.life, 0)/player.maxLife, 0, lifebarWidth*player.healthCutoff/player.maxLife, 5)
    end
    --dash charges display
    if player.abilities and player.abilities.dash then
      for i = 1, player.abilities.dash.maxCharges do
        if player.abilities.dash.charges < i then
          love.graphics.setColor(.1, .1, .2, .3)
        else
          love.graphics.setColor(0, .3, .9)
        end
        love.graphics.circle("fill", 4+10*(i-1), 5, 3)
        if player.abilities.dash.charges == i - 1 then
          love.graphics.setColor(0, .3, .9)
          love.graphics.arc("fill", 4+10*(i-1), 5, 3, -math.pi/2+ 2*math.pi*(1-player.abilities.dash.cooldown/player.abilities.dash.baseCooldown), -math.pi/2)
        end
      end
    end
    --position display
    love.graphics.translate(8, 30)
    love.graphics.scale(.2)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(math.floor(player.x) .."\t"..math.floor(player.y))
  end, 8)
  --abilities hud
  addDrawFunction( function ()
    if not player or not player.abilities then return end
    love.graphics.origin()
    love.graphics.translate(20, height - 150)
    for a, ability in pairs(player.abilities) do
      if ability.displayOnUI then
        ability:displayOnUI()
        love.graphics.translate(150, 0)
      end
    end
  end , 8)
  --hitbox debug display
  addDrawFunction(function ()
    if showHitboxes then
      local c = 0
      for e, entity in pairs(entities) do
        local points = getPointsGlobalCoor(entity)
        local pts = {}
        for p, point in pairs(points) do
          table.insert(pts, point.x)
          table.insert(pts, point.y)
        end
        if #pts>6 then
          c=c+1
          love.graphics.setColor(1, 1, 1, .2)
          love.graphics.polygon("fill", pts)
          love.graphics.setColor(1, 1, 1)
          love.graphics.polygon("line", pts)
        end
      end
    end
  end, 9)

  levelDisplayInit()
  start()

  teamColors = {
    {0, 0, 1, .2},
    {1, 0, 0, .2}
  }
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

  --torch/candle (cosmetic only)
  table.insert(entities, {
    x = 0, y=0, radius=100,angle=0, color = {.7, .7, 0, 0.2}, shear = {x=0, y=0},
    polygon = { 0,0,  -2,-1,  -3,-3,  -2,-5,  0,-10,  2,-5,  3,-3,  2,-1,},
    draw=function (self)
      love.graphics.translate(self.x, self.y)
      love.graphics.setColor(.8, .8, .8, .8)
      love.graphics.rectangle("fill", -2, 0, 4, 5)
      love.graphics.setColor(.5, .5, .5, .5)
      love.graphics.rectangle("fill", -1, 0, 2, -2)
      love.graphics.shear(self.shear.x, self.shear.y)
      love.graphics.polygon("line",self.polygon)
      love.graphics.setColor(self.color)
      love.graphics.polygon("fill",self.polygon)
      love.graphics.push()
      love.graphics.setColor(self.color)
      love.graphics.translate(0, -3)
      love.graphics.scale(.5)
      love.graphics.polygon("fill", self.polygon)
      love.graphics.translate(0, 4)
      love.graphics.setColor({1, 0, .5, .3})
      love.graphics.polygon("fill", self.polygon)
      love.graphics.pop()
      love.graphics.rotate(self.angle)
      love.graphics.setColor(self.color)
      love.graphics.circle("fill", 0, 0, self.radius)
    end,
    update = function (self, dt)
      self.color[1], self.color[2], self.color[4] = self.color[1]+(math.random()-.5)*.01, self.color[2]+(math.random()-.5)*.01, self.color[4]+(math.random()-.5)*.01
      self.radius = self.radius +(math.random()-.49)*.1
      self.angle = self.angle + math.random()*.01
      self.shear = {x=self.shear.x+.01*(math.random()-.5), y=self.shear.y+.01*(math.random()-.5)}
    end
  })
end

function start()
  math.randomseed(os.time())

  cameraSetup()



  difficultyCoef = 1
  enemies = {}
  updateTimerClosestEnemy = .2
  addUpdateFunction(function (dt)
    if not player or #enemies==0 then return end
    updateTimerClosestEnemy = updateTimerClosestEnemy - dt
    if updateTimerClosestEnemy <= 0 then
      updateTimerClosestEnemy = 3
      closest, dist = enemies[1], math.dist(player.x, player.y,enemies[1].x, enemies[1].y)
      for e = #enemies, 1, -1 do
        enemy = enemies[e]
        if enemy.dead or enemy.terminated then
          table.remove(enemies, e)
        else
          enemy.IA.difficultyCoef = difficultyCoef
          if math.dist(player.x, player.y,enemy.x, enemy.y) < dist then
            closest, dist = enemy, math.dist(player.x, player.y,enemy.x, enemy.y)
          end
        end
      end
      closest.IA.difficultyCoef = 10
    end
  end)
  addDrawFunction(function ()
    if #enemies == 0 then
      love.graphics.push()
      love.graphics.origin()
      love.graphics.translate(.5*width, .5*height)
      victoire = victoire or {s=30}
      love.graphics.setColor(.73, .5, .4)
      love.graphics.polygon("fill",
         victoire.s,  victoire.s,
        -victoire.s,  victoire.s,
        -1.5*victoire.s, 0,
        -victoire.s, -victoire.s,
         victoire.s, -victoire.s,
         1.5*victoire.s, 0)
      victoire.s = math.min(victoire.s + 1, 120)
      love.graphics.setColor(.2, .8, .4)
      local text = "Victoire"
      local normalfont = love.graphics.getFont()
      bigassfont = bigassfont or love.graphics.newFont(48)
      love.graphics.setFont(bigassfont)
      love.graphics.print(text, -.5*bigassfont:getWidth(text),-.5*bigassfont:getHeight())
      love.graphics.setFont(normalfont)
      love.graphics.pop()
      return
    end
    if not closest then return end
    love.graphics.setColor(1, 1, 1)
    love.graphics.translate(closest.x, closest.y)
    love.graphics.line(-20, -20, -15, -20)
    love.graphics.line(-20, -20, -20, -15)
    love.graphics.line(20, 20, 15, 20)
    love.graphics.line(20, 20, 20, 15)
    love.graphics.line(20, -20, 15, -20)
    love.graphics.line(20, -20, 20, -15)
    love.graphics.line(-20, 20, -15, 20)
    love.graphics.line(-20, 20, -20, 15)
  end ,9)

  levelSetup()


  newGhost({x=rooms[1].x, y=rooms[1].y})


  enemyLibKeys = {}
  for e, enemy in pairs(enemiesLibrary) do
    table.insert(enemyLibKeys, e)
  end
  math.randomseed(love.timer.getTime())
  for r, room in pairs(rooms) do
    if r == 1 then
      for i = 1, 3 do
        local type = enemiesLibrary[enemyLibKeys[math.random(#enemyLibKeys)]]
        local ent = applyParams(type(), {x= room.x + (math.random()-.5)*room.w, y=room.y + (math.random()-.5)*room.h, team = 2, dead = true, team = 2})
        print(ent.maxLife)
        ent.maxLife = ent.maxLife * 2
        ent:onDeath()
        table.insert(entities, ent)
      end
    else
      local type = enemiesLibrary[enemyLibKeys[math.random(#enemyLibKeys)]]
      for i = 1, math.random(3) do
        local enemy = applyParams(type(), {x= room.x + (math.random()-.5)*room.w, y=room.y + (math.random()-.5)*room.h, team = 2, maxLife = 5, life = 5})
        table.insert(entities, enemy)
        table.insert(enemies, enemy)
      end
    end
  end
  safeLoadAndRun("editableScript.lua")
end

function newPlayer(params)

  player = entitySetup({ableEntityInit,livingEntityInit,movingEntityInit,playerInit},  {
    --display
    color = {.4, .6, .2},
    x=0, y=0,
    abilities = {
      cupcakeTrap = newAbility("cupcakeTrap")
    },
  })
  if params then
    applyParams(player, params)
  end
  table.insert(entities, player)
end

--variables used in player update
function cameraSetup()
  camera.scale = 2
  camera.maxScale = 4
  camera.minScale = 2
  camera.scaleChangeRate = 2
end
-- run once at launch to create basic background grid for ease of localisation
function gridSetup()
  local canvas = love.graphics.newCanvas(width, height)

  love.graphics.setCanvas(canvas)
  canvas:setFilter("nearest")
  love.graphics.setColor(1,1,1)
  love.graphics.setLineStyle("rough")
  for x = 1, width, 30 do
    love.graphics.line(x, 0, x, height)
  end
  for y = 1, height, 30 do
    love.graphics.line(0, y, width, y)
  end

  love.graphics.setCanvas()
  addDrawFunction(function ()
    love.graphics.setColor(1,1,1, .2)
    love.graphics.draw(canvas, -width/2, -height/2)
  end, 4)
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
  camera.angle = camera.angle + y*0.1
end
