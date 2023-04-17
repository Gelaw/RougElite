
function newEntity()
  local entity = {
    --display
    name = "entity",
    shape = "rectangle",
    color = {1, .7, .9},
    x=10, y=10, z=0, w=5, h=5, angle=0,
    updates = {},
    draw = function (self)
      love.graphics.translate(self.x, self.y)
      love.graphics.rotate(self.angle)
      --shadow display
      love.graphics.push()
      love.graphics.rotate(-self.angle-camera.angle)
      love.graphics.translate(0, 3+self.z)
      love.graphics.rotate(self.angle+camera.angle)
      love.graphics.setColor(0, 0, 0, 0.1)
      love.graphics.rectangle("fill", -self.w/2, -self.h/2, self.w, self.h)
      love.graphics.pop()
      --body display (flickering in case of invicibility frames)

      love.graphics.scale(1+self.z*0.3)
      if not self.invicibility or (math.floor(self.invicibility.time*20))%2~=1 then
        -- jump calculations
        love.graphics.setColor(self.color)
        love.graphics.rectangle("fill", -self.w/2, -self.h/2, self.w, self.h)
        if self == player then
          love.graphics.setColor(0, .5, .8, .8)
          love.graphics.polygon("fill", 2, 0, -3, -2, -3, 2)
        end
      end
      love.graphics.rotate(-(self.angle+camera.angle))
      if self.speed then
        love.graphics.setColor(0, 1, 0, .5)
        love.graphics.line(0, 0, 200*self.speed.x/1000, 200*self.speed.y/1000)
      end
      if self.acceleration then
        love.graphics.setColor(0, 0, 1, .5)
        love.graphics.line(0, 0, 200*self.acceleration.x/self.maxAcceleration, 200*self.acceleration.y/self.maxAcceleration)
      end
      if self.IA then
        if self.IA.target then
          local angle = math.angle(self.x, self.y, self.IA.target.x, self.IA.target.y)
          love.graphics.line(0, 0, 5*math.cos(angle), 5*math.sin(angle))
        end
        love.graphics.setColor( 0, 0, 0)
        love.graphics.print(self.team.."\t"..self.IA.task)
      end
      if self.team == 1 and self.life then
        love.graphics.print(self.life.." /"..self.maxLife, 0, 15)
      end
      if self.room then

      end
    end,
    update = function (self, dt)
      for u, updateFunction in pairs(self.updates) do
        updateFunction(self, dt)
      end
    end
  }
  return entity
end

function movingEntityInit(entity)
  local entity = entity or newEntity()

  entity.speed={x=0, y=0}
  entity.acceleration = {x=0, y=0}
  entity.speedDrag= 0.9
  entity.maxAcceleration = 3000
  entity.stuck = false
  entity.tryMovingTo = function (self, dest)
    dest.angle = dest.angle or self.angle
    local points = getPointsGlobalCoor(self)
    local newPosition = {x = dest.x, y= dest.y, w = self.w, h = self.h, angle = dest.angle}
    local newPoints = getPointsGlobalCoor(newPosition)
    local blocked = false
    local collidedWalls = {}
    local blockingWall = nil
    check, blockingWall = wallCollision(self, dest)
    if check then
      blocked = true
    else
      for p = 1, #points do
        check, blockingWall = wallCollision(newPoints[p], newPoints[p%#points+1])
        if check then
          blocked = true
          break
        end
      end
    end
    if blocked then
      if self.onWallCollision then
        self:onWallCollision(blockingWall)
      end
      table.insert(collidedWalls, blockingWall)
    end
    if #collidedWalls > 0 then return collidedWalls end
    self.x = newPosition.x
    self.y = newPosition.y
    self.angle = newPosition.angle
  end
  entity.onWallCollision = function (self, wall)
    self.speed = {x=0, y=0}
  end
  table.insert(entity.updates, function (self, dt)
    if entity.stuck then
      self.acceleration = {x=0, y=0}
      self.speed = {x=0, y=0}
      return
    end
    self.speed.x = (self.speed.x + self.acceleration.x*dt)*entity.speedDrag
    self.speed.y = (self.speed.y + self.acceleration.y*dt)*entity.speedDrag
    if self.maxSpeed then
      self.speed.x = math.max(-self.maxSpeed, math.min(self.speed.x, self.maxSpeed))
      self.speed.y = math.max(-self.maxSpeed, math.min(self.speed.y, self.maxSpeed))
    end
    if math.abs(self.speed.x * dt) > 0 or math.abs(self.speed.y * dt)>0 then
      self:tryMovingTo({x=self.x + self.speed.x * dt, y=self.y + self.speed.y * dt, angle = self.targetAngle})
    end
  end)
  return entity
end

function livingEntityInit(entity)
  local entity = entity or newEntity()

  entity.dead = false
  entity.life = 10
  entity.maxLife = 10
  entity.team = 0
  entity.invicibility = nil
  entity.invicibilityTimeAfterHit = .5
  entity.ressources = {}
  entity.ressourceGenerationTimer = 0
  entity.onDeath = function (self)
    if self.IA then
      self.IA.task = "dead"
      self.IA.cast = nil
      self.IA.choice = nil
    end
    if self.team > 1 then
      for e, enemy in pairs(enemies) do
        if enemy == self then
          table.remove(enemies, e)
          break
        end
      end
    end
    self.contactDamage = nil
    self.speed = {x=0,y=0}
    self.acceleration = {x=0,y=0}
    self.color = {.3, .3, .3}
    table.insert(particuleEffects, {x=self.x, y=self.y, color = {.6, .2, .2}, nudge = 5, size = 3, timeLeft = 1})
  end
  entity.hit = function (self, quantity)
    if self.dead then return end
    local quantity = quantity or 1
    self.life = self.life - quantity
    if quantity > 1 then
      table.insert(particuleEffects, {
        x=self.x, y=self.y, timeLeft=1,
        draw = function (self)
          love.graphics.translate(self.x, self.y)
          love.graphics.translate(5*(1-self.timeLeft), -10*(1-self.timeLeft))
          love.graphics.scale(.5)
          love.graphics.setColor(.8, .6, .5)
          love.graphics.print(quantity)
        end
      })
    end
    self.invicibility = {time = self.invicibilityTimeAfterHit}
    self.intangible = true
    if self.onHit then self:onHit(quantity) end
    --death check
    if self.life <= 0 then
      self.dead = true
      if self.onDeath then self:onDeath() end
    end
  end
  entity.collide = function (self, collider)
    --collision dismissed in case of invicibility or jump
    if self.intangible then return end
    --collision dismissed if both are in the same team (default team value 0, player and allies 1, ennemies 2 or more)
    if self.team and collider.team and self.team ~= collider.team then
      if collider.contactDamage then
        --life deduction
        self:hit(collider.contactDamage)
      end
    end
  end
  table.insert(entity.updates, function (self, dt)
    if self.dead then return end
    -- invicibility
    -- simple timer, with collide and display effects
    if self.invicibility then
      --timer countdown
      self.invicibility.time = self.invicibility.time - dt
      if self.invicibility.time <= 0 then
        --invicibility end
        self.invicibility = nil
        self.intangible = false
      end
    end
    self.ressourceGenerationTimer = self.ressourceGenerationTimer + dt
    if self.ressourceGenerationTimer > .25 then
      self.ressourceGenerationTimer = self.ressourceGenerationTimer - .25
      for r, ressource in pairs(self.ressources) do
        if ressource.regenPerSec then
          ressource.current = math.min(ressource.max, ressource.current + ressource.regenPerSec/4)
        end
      end
    end
  end)
  return entity
end

function playerInit(entity)
  player = entity or movingEntityInit()

  if passives then
    for s, stat in pairs(passives) do
      if player[s] then
        player[s] = player[s] * stat
      else
        for a, ability in pairs(player.abilities) do
          if ability[s] then
            ability[s] = ability[s] * stat
          end
        end
      end
    end
  end
  player.name = "player"
  for e, enemy in pairs(enemies) do
    if enemy == player then
      table.remove(enemies, e)
      break
    end
  end
  --used in base camera.update()
  camera.mode = {"follow", player}
  applyParams(player, {
    dead = false,
    life = entity.maxLife,
    team = 1,
    hits = {},
    healthCutoff = 0,
    healthCutoffDuration = 1.5,
    onHit = function (self, quantity)
      table.insert(self.hits, {math.min(quantity, self.life), love.timer.getTime()})
      self.healthCutoff = self.healthCutoff + math.min(quantity, self.life)
      local perceivedIntensity = (quantity/self.maxLife)^2
      cameraShake(200*perceivedIntensity, .5 )
      if joystick and joystick:isVibrationSupported() then
        joystick:setVibration(perceivedIntensity, perceivedIntensity, .2 )
      end
    end,
    onDeath = function (self)
      self.update = nil
      self.collide = nil
      self.color = {.7, .1, .1}
      table.insert(particuleEffects, {x=self.x, y=self.y, color = {.6, .2, .2}, nudge = 5, size = 3, timeLeft = 1})
      --ghost out the shell
      ghost = newGhost({x=self.x, y=self.y})
      table.insert(entities, ghost)
      camera.mode = {"follow", ghost}
    end
  })
  player.IA = nil
  table.insert(player.updates,
  function (self, dt)
    local mx, my = love.mouse.getPosition()
    local angle = math.angle(.5*width+self.x-camera.x, .5*height+self.y-camera.y, mx, my)
    local distance = math.dist(.5*width+self.x-camera.x, .5*height+self.y-camera.y, mx, my)
    if love.mouse.isDown(1) and mousePressedOnWorld then
      q = math.min(1, distance/100)
      self.acceleration ={x=q*self.maxAcceleration * math.cos(angle),y=q*self.maxAcceleration * math.sin(angle)}
    else
      self.acceleration = {x=0, y=0}
    end

    self.targetAngle = angle
    --camera zoom control
    -- variables set in "cameraSetup()" method
    if love.keyboard.isDown("lctrl") then
      camera.scale = math.max(camera.scale - camera.scaleChangeRate*dt, camera.minScale)
    else
      camera.scale = math.min(camera.scale + camera.scaleChangeRate*dt, camera.maxScale)
    end
  end)
  table.insert(player.updates,
  function (self, dt)
    local time = love.timer.getTime()
    local hit
    for h = #self.hits, 1, -1 do
      hit = self.hits[h]
      if time - hit[2] > self.healthCutoffDuration then
        self.healthCutoff = self.healthCutoff - hit[1]
        table.remove(self.hits, h)
      end
    end
  end)

  abilitiesHUD:load()

  return player
end

function newGhost(params)
  ghost = {
    shape = "rectangle",
    x=0, y=0,
    w= 10, h = 10,
    color = {.3, .3, 1},
    speed={x=0, y=0},
    speedDrag= 0.9,
    maxAcceleration = 2000,
    update = function (self,  dt)
      --temporary acceleration variables
      local ax, ay = 0, 0
      --if gamepad is connected, use left joystick as input
      if joystick then
        a1, a2, a3 = joystick:getAxes()
        --check if joystick is outside of deadzone (TODO later: parameter 0.3 to be extrated and made modifiable once parameter norm in place)
        if math.abs(a1)>0.3 or math.abs(a2)>0.3 then
          ax, ay = self.maxAcceleration*a1*math.abs(a1), self.maxAcceleration*a2*math.abs(a2)
        end
      end
      --keyboard ZQSD binds for player movement
      if love.keyboard.isDown("z") and not love.keyboard.isDown("s") then
        ay = -self.maxAcceleration
      end
      if love.keyboard.isDown("s") and not love.keyboard.isDown("z") then
        ay = self.maxAcceleration
      end
      if love.keyboard.isDown("q") and not love.keyboard.isDown("d") then
        ax = -self.maxAcceleration
      end
      if love.keyboard.isDown("d") and not love.keyboard.isDown("q") then
        ax = self.maxAcceleration
      end
      if love.mouse.isDown(1) and mousePressedOnWorld then
        mx, my = love.mouse.getPosition()
        angle = math.angle(.5*width+self.x-camera.x, .5*height+self.y-camera.y, mx, my)
        q = math.min(1, math.dist(.5*width+self.x-camera.x, .5*height+self.y-camera.y, mx, my)/100)
        ax, ay = q*self.maxAcceleration * math.cos(angle), q*self.maxAcceleration * math.sin(angle)
      end
      --speed, position and orientation calculations
      local a = camera.angle
      self.acceleration = {x=ax*math.cos(a)+ay*math.sin(a), y=ay*math.cos(a)-ax*math.sin(a)}
      self.speed.x = (self.speed.x + self.acceleration.x*dt)*self.speedDrag
      self.speed.y = (self.speed.y + self.acceleration.y*dt)*self.speedDrag
      if math.abs(self.speed.x)>0 or math.abs(self.speed.y)>0 then
        self.angle = -math.atan2(self.speed.x, self.speed.y)+math.rad(90)
      end
      local newPosition = {x = self.x + self.speed.x * dt, y= self.y + self.speed.y * dt}
      self.x = newPosition.x
      self.y = newPosition.y
    end,
    collide = function (self, collider)
      if collider.team and collider.team > 1 and collider.dead then
        if invocationCircle then invocationCircle:moveTo(collider.x, collider.y) end
        --kill the ghost
        self.terminated = true
        self.collide = nil
        --take control of the enemy
        playerInit(collider)
        ghost = nil
        camera.mode = {"follow", player}
      end
    end
  }
  if params then
    applyParams(ghost, params)
  end
  camera.mode = {"follow", ghost}
  table.insert(entities, ghost)
  return ghost
end

function entitySetup(initFunctions, extraParams)
  local entity = nil
  for f, func in pairs(initFunctions) do
    entity = func(entity)
  end

  if entity.maxLife then
    entity.life = entity.maxLife
  end
  if extraParams.maxLife then
    entity.life = extraParams.maxLife
  end
  return applyParams(entity, extraParams)
end
