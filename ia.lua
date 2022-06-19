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
    difficultyCoef = 1,
    task = "unstarted", aggroRange = 1300,
    target = nil,
    unstarted = applyParams(newTask(), {
      update = function (self, ia, entity)
        if ia.target and not ia.target.dead then
          ia:switchToTask("idle")
          return
        end
      end
    }),
    idle = applyParams(newTask(), {
      update = function (self, ia, entity)
        if not ia.target or ia.target.dead then
          ia:switchToTask("unstarted")
          return
        end
        if math.dist(entity.x, entity.y, ia.target.x, ia.target.y) < ia.aggroRange and math.random()*ia.difficultyCoef > .99 then
          --turn toward ia.target
          entity.targetAngle = math.angle(entity.x, entity.y, ia.target.x, ia.target.y)
          ia:switchToTask("decision")
        end
      end
    }),
    decision = applyParams(newTask(), {
      update = function (self, ia, entity)
        if not ia.target then
          ia:switchToTask("idle")
          return
        end
        local distance = math.dist(entity.x, entity.y, ia.target.x, ia.target.y)
        if not ia.target.life or ia.target.dead or distance > ia.aggroRange or math.random()*ia.difficultyCoef > .5 then
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
      update = function (self, ia, entity)
        if not ia.target then
          ia:switchToTask("idle")
          return
        end
        if entity.abilities[ia.choice].cooldown > 0 then
          ia:switchToTask("decision")
          return
        end
        entity.targetAngle = math.angle(entity.x, entity.y, ia.target.x, ia.target.y)
        local distance = math.dist(entity.x, entity.y, ia.target.x, ia.target.y)
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
        entity.targetAngle = math.random()*2*math.pi
        local accQ = math.min(math.random() * ia.difficultyCoef, 1)
        entity.acceleration = {x=accQ*entity.maxAcceleration*math.cos(entity.angle), y=accQ*entity.maxAcceleration*math.sin(entity.angle)}
        self.timer = .3 * math.min(ia.difficultyCoef, 1)
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

interIATUtick = 3
local IATUtimer = 0
function IAtargetingUpdate(dt)
  IATUtimer = IATUtimer - dt
  if IATUtimer < 0 then
    IATUtimer = interIATUtick
    for e, entity in pairs(entities) do
      if entity.IA then
        entity.IA.target = nil
        if not entity.dead then
          for e2, entity2 in pairs(entities) do
            local distance = math.dist(entity.x, entity.y, entity2.x, entity2.y)
            if entity2.team and entity.team ~= entity2.team and entity2.life and entity2.life > 0 then
              if not entity.IA.target or entity.IA.distTotarget>distance then
                entity.IA.target = entity2
                entity.IA.distTotarget = distance
              end
            end
          end
        end
      end
    end
  end
end
addUpdateFunction(IAtargetingUpdate)
addDrawFunction(function ()
  love.graphics.origin()
  love.graphics.setColor(0, 0, 0)
  love.graphics.arc("line", "open", 45, 45, 30, -.5*math.pi, math.pi*(2*IATUtimer/interIATUtick-.5))
end, 8)
