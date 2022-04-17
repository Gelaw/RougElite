
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

function applyParams(entity, parameters)
  for p, parameter in pairs(parameters) do
    entity[p] = parameter
  end
  return entity
end
