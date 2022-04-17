
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
  table.insert(entity.updates,
    function (self, dt)
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
    end
  )
  return entity
end

function livingEntityInit(entity)
  local entity = entity or newEntity()

  entity.life = 10
  entity.team = 0
  entity.invicibility = nil
  entity.collide = function (self, collider)
    --collision dismissed in case of invicibility or jump
    if self.intangible then return end
    --collision dismissed if both are in the same team (default team value 0, player and allies 1, ennemies 2 or more)
    if self.team == collider.team then return end
    --life deduction
    self.life = self.life - 1
    self.invicibility = {time = .5}
    self.intangible = true
    if self.onHit then self:onHit() end
    --death check
    if self.life <= 0 and self.onDeath then self:onDeath() end
  end
  table.insert(entity.updates,
    function (self, dt)
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

function applyParams(entity, parameters)
  for p, parameter in pairs(parameters) do
    entity[p] = parameter
  end
  return entity
end
