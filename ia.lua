function newTask()
  return {
    start = function () end,
    update = function () end,
    finish = function () end
  }
end

function newIA()
  return {
    task = nil,
    switchToTask = function (self, newTask, entity)
      self[self.task]:finish(self, entity)
      self.task = newTask
      self[self.task]:start(self, entity)
    end
  }
end

function basicIA()
  return applyParams(newIA(), {
    task = "idle", aggroRange = 300,
    idle = applyParams(newTask(), {
      update = function (self, ia, entity)
        if not player or not player.life or player.dead then return end
        if math.dist(entity.x, entity.y, player.x, player.y) < ia.aggroRange then
          --turn toward player
          entity.angle = math.angle(entity.x, entity.y, player.x, player.y)
          ia:switchToTask("decision")
        end
      end
    }),
    decision = applyParams(newTask(), {
      update = function (self, ia, entity)
        local distance = math.dist(entity.x, entity.y, player.x, player.y)
        if not player or not player.life or player.dead or distance > ia.aggroRange then
          ia:switchToTask("idle")
          return
        end
        local choice = nil, nil
        for a, ability in pairs(entity.abilities) do
          if ability.charges > 0 then
            if not choice or (entity.abilities[choice].range < ability.range and (not ability.rangeMin or ability.rangeMin < distance)) then
              choice = a
            end
          end
        end
        if choice then
          ia.choice = choice
          ia:switchToTask("attack", entity)
        else
          ia:switchToTask("run", entity)
        end
      end
    }),
    attack = applyParams(newTask(), {
      start = function (self, ia, entity)
        entity.angle = math.angle(entity.x, entity.y, player.x, player.y)
      end,
      update = function (self, ia, entity)
        if entity.abilities[ia.choice].cooldown > 0 then
          ia:switchToTask("decision")
          return
        end
        entity.angle = math.angle(entity.x, entity.y, player.x, player.y)
        local distance = math.dist(entity.x, entity.y, player.x, player.y)
        if distance > entity.abilities[ia.choice].range then
          entity.acceleration = {x=entity.maxAcceleration*math.cos(entity.angle), y=entity.maxAcceleration*math.sin(entity.angle)}
        else
          entity.acceleration = {x=0,y=0}
          ia.cast = ia.choice
        end
      end,
      finish = function (self, ia)
        ia.choice = nil
        ia.cast = nil
      end
    }),
    run = applyParams(newTask(), {
      start = function (self, ia, entity)
        entity.angle = math.random()*2*math.pi
        local accQ = math.random()
        entity.acceleration = {x=accQ*entity.maxAcceleration*math.cos(entity.angle), y=accQ*entity.maxAcceleration*math.sin(entity.angle)}
        self.timer = .3
      end,
      update = function (self, ia, entity, dt)
        self.timer = self.timer - dt
        if self.timer < 0 then
          ia:switchToTask("decision")
        end
      end
    })
  })
end


function IAinit(entity)
  entity = entity or newEntity()

  table.insert(entity.updates,
    function (self, dt)
      local ia = self.IA
      if ia and ia[ia.task] then
        local task = ia[ia.task]
        task.update(task, ia, self, dt)
      end
    end)
  return entity
end
