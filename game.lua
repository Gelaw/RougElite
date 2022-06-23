
function gameSetup()
  local joysticks = love.joystick.getJoysticks()
  if joysticks then joystick = joysticks[1] end
  lifebarWidth = 30
  mousePressedOnWorld = false
  teamColors = {
    {0, 0, 1, .2},
    {1, 0, 0, .2},
    {0, 1, 0, .2}
  }


  normalfont = love.graphics.newFont(12)
  bigassfont = love.graphics.newFont(48)

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
  table.insert(uis, {
    x = 0, y = 0,
    draw = function ()
      if StartingNumberEnemies > 0 then
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
          love.graphics.setFont(bigassfont)
          love.graphics.print(text, -.5*bigassfont:getWidth(text),-.5*bigassfont:getHeight())
          love.graphics.setFont(normalfont)
          love.graphics.pop()
          return
        end
        love.graphics.origin()
        love.graphics.setFont(bigassfont)
        local text = "Enemy forces:"
        local marge = 30 + bigassfont:getWidth(text)
        love.graphics.rectangle("fill", marge, 30, width - 2*marge, bigassfont:getHeight())
        love.graphics.setColor(.5, .1, .1)
        love.graphics.print(text, 30, 30)
        love.graphics.rectangle("fill", marge, 30, (width - 2*marge)*#enemies/StartingNumberEnemies, bigassfont:getHeight())
        love.graphics.setFont(normalfont)
      end
    end
  })
  --player hud
  addDrawFunction(function()
    if player then
      --lifebar display
      love.graphics.push()
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
      love.graphics.pop()
    end
    if ghost then
      love.graphics.translate(ghost.x, ghost.y)
      love.graphics.setColor(1, 1, 1, .2)
      for e, entity in pairs(entities) do
        if entity.team and entity.team > 1 and entity.dead and entity.collide then
          local angle = math.angle(ghost.x, ghost.y, entity.x, entity.y)
          local distance = math.dist(ghost.x, ghost.y, entity.x, entity.y)
          love.graphics.push()
          if entity.archetypeName then
            love.graphics.print(entity.archetypeName, entity.x-camera.x-.5*normalfont:getWidth(entity.archetypeName), entity.y-camera.y-15)
          end
          love.graphics.rotate(angle)
          love.graphics.arc("line", "open", distance, 0, 20, math.rad(15), 2*math.pi/3 - math.rad(15))
          love.graphics.arc("line", "open", distance, 0, 20, 2*math.pi/3 + math.rad(15), 4*math.pi/3 - math.rad(15))
          love.graphics.arc("line", "open", distance, 0, 20, 4*math.pi/3 + math.rad(15), 2*math.pi - math.rad(15))

          love.graphics.translate((math.min(distance/100, .9)+.1)*50, 0)
          love.graphics.polygon("fill", 0, 0, -10, 3, -10, -3)
          love.graphics.pop()
        end
      end
    end
  end, 8)
  --abilities hud
  abilitiesHUD = {
    x = 0, y = height - 150,
    width = width, height = 150,
    hidden = false,
    load = function (self)
      self.children = {}
      if not player or not player.abilities then return end
      local x = 10
      for a, ability in pairs(player.abilities) do
        if ability.displayOnUI then
          table.insert(self.children, {x=x, y=10, width = 130, height = 130, ability = ability,
          draw = function (self)
            self.ability:displayOnUI()
          end,
          onClick = function (self)
            print(self.ability.name, "clicked" )
          end})
          x = x + 150
        end
      end
    end,
    draw = function (self)
      love.graphics.setColor(.1, .1, .1, .1)
      love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    end
  }
  table.insert(uis, abilitiesHUD)
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

  --minimap
  -- table.insert(uis, {draw=  function ()
  --     love.graphics.origin()
  --     love.graphics.translate(width-300, height-200)
  --     love.graphics.scale(.1)
  --     love.graphics.translate(.5*width+100, .5*height+100)
  --     love.graphics.setColor(.2,.2,.2)
  --     love.graphics.rectangle("fill", -.5*width-100, -.5*height-100, width+200, height+200)
  --     love.graphics.translate(-camera.x, -camera.y)
  --     for r, room in pairs(rooms) do
  --       love.graphics.setColor(room.roomcolor)
  --       love.graphics.rectangle("fill", room.x-room.w/2, room.y-room.h/2, room.w, room.h)
  --     end
  --     love.graphics.scale(10)
  --     love.graphics.setColor(0, 0, 0)
  --     for w, wall in pairs(walls) do
  --       love.graphics.line(wall[1].x/10, wall[1].y/10, wall[2].x/10, wall[2].y/10)
  --     end
  --     if player then
  --       love.graphics.scale(.1)
  --       love.graphics.setColor(player.color)
  --       love.graphics.rectangle("fill", player.x, player.y, math.max(player.w, 30), math.max(player.h, 30))
  --     end
  --     if ghost then
  --       love.graphics.scale(.1)
  --       love.graphics.setColor(ghost.color)
  --       love.graphics.rectangle("fill", ghost.x, ghost.y, math.max(ghost.w, 30), math.max(ghost.h, 30))
  --     end
  --   end})
  --
  --
  --
  --       --collectibles spawn
  --       -- addUpdateFunction(function (dt)
  --       --   if collectibles < 10 and math.random()>.99 then
  --       --     collectibles = collectibles + 1
  --       --     table.insert(entities, {
  --       --       shape = "rectangle",
  --       --       x = (math.random()-.5)*w, y = (math.random()-.5)*height,
  --       --       w = 5, h = 5, color = {.2, .8, .4},
  --       --       collide = function (self, collider)
  --       --         if collider == player then
  --       --           collectibles = collectibles - 1
  --       --           player.life = math.min(player.maxLife, player.life + 1)
  --       --           table.insert(particuleEffects, {
  --       --             x=self.x, y=self.y, color = {1, .2, .2}, nudge = 5, size = 3, timeLeft = 1.5,
  --       --             pluslygon = {-1,-1,  -1,-3,  1,-3,  1,-1,  3,-1,  3,1,  1,1,  1,3,  -1,3,  -1,1,  -3,1,  -3,-1},
  --       --             draw = function (self)
  --       --               love.graphics.translate(self.x, self.y)
  --       --               love.graphics.scale(.5)
  --       --               love.graphics.setColor(self.color)
  --       --               local t = love.timer.getTime() % 3600
  --       --               for i = 1, 4 do
  --       --                 love.graphics.push()
  --       --                 love.graphics.translate(math.cos(10*t+i*39)*5, math.cos(12*t+i*22)*5)
  --       --                 love.graphics.polygon("fill", self.pluslygon)
  --       --                 love.graphics.pop()
  --       --               end
  --       --             end
  --       --           })
  --       --           self.terminated = true
  --       --         end
  --       --       end
  --       --     })
  --       --   end
  --       -- end)

  levelDisplayInit()

  passives = {maxLife = 1, maxSpeed = 1, w = 1, h = 1, damage = 1, range = 1, maxCharges = 1, }

  passiveSkillUI = {
    x = 30, y = 30, width = width - 60, height = height - 60,
    hidden = true, backgroundColor = {.5, teamColors[1][2]*.5, teamColors[1][3]*.5},
    children = {},
    draw = function (self)
      love.graphics.setColor(self.backgroundColor)
      love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    end
  }
  local x = 10
  for p, passive in pairs(passives) do
    child = {
      x = x, y= 10, width = 120, height = 120,
      color={math.random(),math.random(),math.random()},
      passive = p,
      onClick = function (self)  end, onPress = function (self)  passives[self.passive] = passives[self.passive] + 1 end,
      draw = function (self)
        love.graphics.setColor(self.color)
        love.graphics.rectangle("fill", 0, 0, self.width, self.height)
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(self.passive ..": +".. passives[self.passive]*100-100 .."%")
      end
    }
    table.insert(passiveSkillUI.children, child)
    x = x + child.width + 10
  end
  table.insert(uis, passiveSkillUI)
end

function gameStart()
  levelSetup()
  cameraSetup()
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
      if r > 2 then break end
      for i = 1, 3 do
        local enemyArchetype = enemiesLibrary[enemyLibKeys[math.random(#enemyLibKeys)]]
        spawn(enemyArchetype, {x= room.x + (math.random()-.5)*room.w, y=room.y + (math.random()-.5)*room.h, team = 2})
      end
    end
  end
  StartingNumberEnemies = #enemies
end


function spawn(enemyArchetype, params)
  local entity = applyParams(enemyArchetype(), params)
  table.insert(entities, entity)
  if entity.dead then
    entity:onDeath()
  elseif entity.team and entity.team > 1 then
    table.insert(enemies, entity)
  end
  return entity
end

function newPlayer(params)
  local entity = entitySetup({ableEntityInit,livingEntityInit,movingEntityInit},  {
    --display
    color = {.4, .6, .2},
    maxLife = 1000,
    life = 1000,
    x=0, y=0,
    abilities = {
      shoot = newAbility("shoot"),
      boeingboeingboeing = newAbility("boeingboeingboeing"),
    },
  })
  if params then
    applyParams(entity, params)
  end
  playerInit(entity)
  table.insert(entities, entity)
end


--variables used in player update
function cameraSetup()
  camera.scale = 1
  camera.maxScale = 2
  camera.minScale = 1
  camera.scaleChangeRate = 2
end

function gameMousePress(x, y, button)
  local uiClick = UIMousePress(x, y , button)
  if not uiClick then
    mousePressedOnWorld = true
  end
end

function gameMouseRelease(x, y, button)
  mousePressedOnWorld = false
end
