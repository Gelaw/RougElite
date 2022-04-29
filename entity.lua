
function newEntity()
  local entity = {
    --display
    shape = "rectangle",
    color = {1, .7, .9},
    x=10, y=10, z=0, width=5, height=5, angle=0,
    updates = {},
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
  table.insert(entity.updates, function (self, dt)
    if entity.stuck then
      self.acceleration = {x=0, y=0}
      self.speed = {x = 0, y=0}
      return
    end
    self.speed.x = (self.speed.x + self.acceleration.x*dt)*entity.speedDrag
    self.speed.y = (self.speed.y + self.acceleration.y*dt)*entity.speedDrag
    if self.maxSpeed then
      self.speed.x = math.max(-self.maxSpeed, math.min(self.speed.x, self.maxSpeed))
      self.speed.y = math.max(-self.maxSpeed, math.min(self.speed.y, self.maxSpeed))
    end
    local newPosition = {x = self.x + self.speed.x * dt, y= self.y + self.speed.y * dt}
    if wallCollision(self, newPosition) and not self.ignoreWalls then
      self.speed.x = 0
      self.speed.y = 0
    else
      self.x = newPosition.x
      self.y = newPosition.y
    end
  end)
  return entity
end

function livingEntityInit(entity)
  local entity = entity or newEntity()

  entity.life = 10
  entity.maxLife = 10
  entity.team = 0
  entity.invicibility = nil
  entity.invicibilityTimeAfterHit = .5
  entity.hit = function (self, quantity)
    local quantity = quantity or 1
    self.life = self.life - quantity
    self.invicibility = {time = self.invicibilityTimeAfterHit}
    self.intangible = true
    if self.onHit then self:onHit() end
    --death check
    if self.life <= 0 and self.onDeath then self:onDeath() end
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
  end)
  return entity
end

function newAbility()
  return {
    update = function (self, dt, caster) end,
    active = false,
    activeTimer = 0,
    activationDuration = 0,
    baseCooldown = 99,
    cooldown = 0,
    charges = 1,
    maxCharges = 1,
    castConditions = function () return true end,
    bindCheck = function () end,
    activate = function (self)
      self.activeTimer = self.activationDuration
      self.active = true
    end,
    activeUpdate = function (self, dt)
      self.activeTimer = self.activeTimer - dt
    end,
    deactivate = function (self)
      self.active = false
      self.charges = self.charges - 1
    end,
    onCooldownStart = function (self)
      self.cooldown = self.baseCooldown
    end,
    cooldownUpdate = function (self, dt, caster)
      self.cooldown = math.max(self.cooldown - dt, 0)
    end,
    onCooldownEnd = function (self)
      self.charges = self.charges + 1
    end,
  }
end

function ableEntityInit(entity)
  local entity = entity or newEntity()

  entity.abilities = {}
  table.insert(entity.updates, function (self, dt)
    for a, ability in pairs(self.abilities) do
      ability:update(dt, entity)
      if ability.cooldown > 0 then
        ability:cooldownUpdate(dt, entity)
        if ability.cooldown <= 0 then
          ability:onCooldownEnd(entity)
        end
      elseif ability.charges < ability.maxCharges then
        ability:onCooldownStart()
      end
      if ability.active then
        ability:activeUpdate(dt, entity)
        if ability.activeTimer <= 0 then
          ability:deactivate(entity)
        end
      elseif ability.charges > 0  and ability:castConditions(entity) ~= nil then
        if (player == entity and ability:bindCheck()) or (entity.IA and a==entity.IA.task) then
          ability:activate(entity)
        end
      end
    end
  end)
  return entity
end

function playerInit(entity)
  local entity = entity or newEntity()

  applyParams(entity, {
    draw = function (self)
      love.graphics.translate(self.x, self.y)
      love.graphics.rotate(self.angle)
      --shadow display
      love.graphics.setColor(0, 0, 0, 0.1)
      love.graphics.rectangle("fill", -self.width/2, -self.height/2, self.width, self.height)
      --body display (flickering in case of invicibility frames)
      love.graphics.rotate(-self.angle)
      love.graphics.translate(0, -1-self.z)
      love.graphics.rotate(self.angle)
      love.graphics.scale(1+self.z*0.3)
      if not self.invicibility or (math.floor(self.invicibility.time*20))%2~=1 then
          -- jump calculations
        love.graphics.setColor(self.color)
        love.graphics.rectangle("fill", -self.width/2, -self.height/2, self.width, self.height)
        love.graphics.setColor(0, .5, .8, .5)
        love.graphics.polygon("fill", 2, 0, -3, -2, -3, 2)
      end
    end,
    life = 10,
    team = 1,
    onHit = function (self)
      cameraShake(20, .5)
      if joystick and joystick:isVibrationSupported() then
        joystick:setVibration(.05, .05, .2 )
      end
    end,
    IA = nil,
    onDeath = function (self)
      self.update = nil
      self.collide = nil
      self.color = {.7, .1, .1}
      table.insert(particuleEffects, {x=self.x, y=self.y, color = {.6, .2, .2}, nudge = 5, size = 3, timeLeft = 1})
      --ghost out the shell
      player = {
        shape = "rectangle",
        x=self.x, y=self.y,
        width = 10, height = 10,
        color = {.3, .3, 1},
        speed={x=0, y=0},
        speedDrag= 0.9,
        maxAcceleration = 3000,
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
          --speed, position and orientation calculations
          self.speed.x = (self.speed.x + ax*dt)*self.speedDrag
          self.speed.y = (self.speed.y + ay*dt)*self.speedDrag
          if math.abs(self.speed.x)>0 or math.abs(self.speed.y)>0 then
            self.angle = -math.atan2(self.speed.x, self.speed.y)+math.rad(90)
          end
          local newPosition = {x = self.x + self.speed.x * dt, y= self.y + self.speed.y * dt}
          self.x = newPosition.x
          self.y = newPosition.y
          camera.x = (camera.x + self.x)/2
          camera.y = (camera.y + self.y)/2
        end,
        collide = function (self, collider)
          if collider.abilities and collider.life and collider.life <= 0 then
            --kill the ghost
            player.terminated = true
            --take control of the enemy
            player = playerInit(collider)
            camera.mode = {"follow", player}
          end
        end
      }
      camera.mode = {"follow", player}
      table.insert(entities, player)
    end
  })
  table.insert(entity.updates,
    function (self, dt)
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
      --acceleration and orientation calculations
      self.acceleration = {x=ax, y=ay}
      if math.abs(self.speed.x)>0 or math.abs(self.speed.y)>0 then
        self.angle = -math.atan2(self.speed.x, self.speed.y)+math.rad(90)
      end

      --camera zoom control
      -- variables set in "cameraSetup()" method
      if (joystick and joystick:isDown(3)) or love.keyboard.isDown("lctrl") then
        camera.scale = math.max(camera.scale - camera.scaleChangeRate*dt, camera.minScale)
      else
        camera.scale = math.min(camera.scale + camera.scaleChangeRate*dt, camera.maxScale)
      end
    end
  )
  return entity
end

function applyParams(table, parameters)
  for p, parameter in pairs(parameters) do
    table[p] = parameter
  end
  return table
end
