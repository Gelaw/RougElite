
function newEntity()
  local entity = {
    --display
    shape = "rectangle",
    color = {1, .7, .9},
    x=10, y=10, width=5, height=5, angle=0,
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
  entity.speedDrag= 0.9
  entity.maxAcceleration = 3000
  entity.stuck = false
  table.insert(entity.updates, function (self, dt)
    if entity.stuck then
      self.speed.x = 0
      self.speed.y = 0
      return
    end
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
  entity.hit = function (self, quantity)
    local quantity = quantity or 1
    self.life = self.life - quantity
    self.invicibility = {time = .5}
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
      --life deduction
      self:hit()
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

function ableEntity(entity)
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
      elseif ability.charges > 0 and ability:bindCheck() and ability:castConditions(entity) ~= nil then
        ability:activate(entity)
      end
    end
  end)
  return entity
end

function applyParams(table, parameters)
  for p, parameter in pairs(parameters) do
    table[p] = parameter
  end
  return table
end
