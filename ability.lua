abilitiesLibrary = {
  decimatingSmash = {
    baseCooldown = 5,
    activationDuration = .5,
    minDamage= 10,
    maxDamage= 50,
    damage = 1,
    name = "decimating smash",
    joystickBind = 2,
    keyboardBind = "a",
    range= 80,
    hitbox = nil,
    activate = function (self, caster)
      self.activeTimer = self.activationDuration
      self.active = true
      self:deductCosts(caster)
      self.keyReleased = false
      caster.stuck = true
      self.hitbox = {
        color = {1, .3, .3, .2},
        x=caster.x+ .5*self.range*math.cos(caster.angle), y=caster.y + .5*self.range*math.sin(caster.angle),
        angle = caster.angle, w = self.range, h = self.range,
        fill = 0,
        draw = function (self)
          love.graphics.push()
          love.graphics.setColor(self.color)
          love.graphics.translate(self.x, self.y)
          love.graphics.rotate(self.angle)
          love.graphics.rectangle("fill", -self.w/2, -self.h/2, self.w, self.h)
          love.graphics.rectangle("fill", -self.w/2, -(1-self.fill)*self.h/2, self.w*(1-self.fill), (1-self.fill)*self.h)
          love.graphics.setColor(teamColors[caster.team])
          love.graphics.rectangle("line", -self.w*.5*1.01, -self.h*.5*1.01, self.w*1.01, self.h*1.01)
          love.graphics.pop()
        end
      }
      table.insert(entities, self.hitbox)
    end,
    activeUpdate = function (self, dt, caster)
      self.activeTimer = self.activeTimer - dt
      applyParams(self.hitbox, {
        x=caster.x+ 40*math.cos(caster.angle), y=caster.y + 40*math.sin(caster.angle),fill = self.activeTimer / self.activationDuration
      })
      self.hitbox.angle = caster.angle
      if not self:bindCheck() then self.keyReleased = true end
      if self:bindCheck() and self.keyReleased then self:deactivate(caster) end
    end,
    deactivate = function (self, caster)
      self:onCooldownStart()
      self.active = false
      local damage = math.floor(self.minDamage + (self.maxDamage-self.minDamage)*(1-self.hitbox.fill)) * self.damage
      caster.stuck = false
      hitInHitbox(self.hitbox, caster, damage)
      self.hitbox.color[4] = 1
      table.insert(particuleEffects, {x=self.hitbox.x, y=self.hitbox.y, color = self.hitbox.color, nudge = self.hitbox.w, size = 2, timeLeft = 1})
      self.hitbox.terminated = true
    end
  },
  unbreakable = {
    baseCooldown = 5,
    range = 60,
    distanceToCaster = 15,
    activationDuration = 10,
    joystickBind = 4,
    keyboardBind = "e",
    name = "unbreakable",
    hitbox = nil,
    activate = function (self, caster)
      self:deductCosts(caster)
      self.activeTimer = self.activationDuration
      self.active = true
      local x, y = caster.x+ self.distanceToCaster*math.cos(caster.angle), caster.y + self.distanceToCaster*math.sin(caster.angle)
      local wall = {{x=0, y=0}, {x=0, y=0}}
      table.insert(walls, wall)
      self.hitbox = applyParams(newEntity(),{
        color = {.2, .2, 1, 1},
        x=x, y=y,
        angle = caster.angle, w = 3, h = 40, durability = 3, team = caster.team,
        wall = wall,
        draw = function (self)
          love.graphics.push()
          love.graphics.setColor(self.color)
          love.graphics.translate(self.x, self.y)
          love.graphics.rotate(self.angle)
          love.graphics.rectangle("fill", -self.w/2, -self.h/2, self.w, self.h)
          love.graphics.setColor(teamColors[caster.team])
          love.graphics.rectangle("line", -self.w*.5*1.01, -self.h*.5*1.01, self.w*1.01, self.h*1.01)
          love.graphics.pop()
        end,
        collide = function (self, collider)
          if collider.team and collider.team == self.team then return end
          if not collider.contactDamage then return end
          self.durability = self.durability - 1
          if self.durability <= 0 then
            table.insert(particuleEffects, {x=self.x, y=self.y, nudge=30, size=1, timeLeft=.5, color=self.color})
            self.terminated = true
          end
        end
      })
      table.insert(entities, self.hitbox)
    end,
    activeUpdate = function (self, dt, caster)
      self.activeTimer = self.activeTimer - dt
      if self.hitbox.terminated then
        self:deactivate(caster)
        return
      end
      applyParams(self.hitbox, {
        x=caster.x+ self.distanceToCaster*math.cos(self.hitbox.angle), y=caster.y + self.distanceToCaster*math.sin(self.hitbox.angle)
      })
      self.hitbox.wall[1] = {x=self.hitbox.x - .5*self.hitbox.h*math.cos(self.hitbox.angle+.5*math.pi), y=self.hitbox.y - .5*self.hitbox.h*math.sin(self.hitbox.angle+.5*math.pi)}
      self.hitbox.wall[2] = {x=self.hitbox.x + .5*self.hitbox.h*math.cos(self.hitbox.angle+.5*math.pi), y=self.hitbox.y + .5*self.hitbox.h*math.sin(self.hitbox.angle+.5*math.pi)}
    end,
    deactivate = function (self)
      self.active = false
      self:onCooldownStart()
      self.hitbox.terminated = true
      local hitWall = self.hitbox.wall
      for w, wall in pairs(walls) do
        if wall == hitWall then
          table.remove(walls, w)
          return
        end
      end
    end,
    bindCheck = function ()
      return (joystick and joystick:isDown(4)) or love.keyboard.isDown("e")
    end
  },
  absoluteZero = {
    baseCooldown = 30,
    minDamage= 20,
    maxDamage= 100,
    damage = 1,
    name = "absolute zero",
    joystickBind = 8,
    keyboardBind = "r",
    activationDuration = 1,
    range = 100,
    hitbox = nil,
    activate = function (self, caster)
      self:deductCosts(caster)
      self.activeTimer = self.activationDuration
      self.active = true
      self.keyReleased = false
      caster.stuck = true
      self.hitbox = {
        color = {.5, .5, 1, .1}, radius = self.range,
        x=caster.x, y=caster.y, fill = self.activeTimer / self.activationDuration,
        draw = function (self)
          love.graphics.push()
          love.graphics.setColor(self.color)
          love.graphics.translate(self.x, self.y)
          love.graphics.circle("fill", 0, 0, self.radius)
          love.graphics.circle("fill", 0, 0, self.radius*self.fill)
          love.graphics.setColor(teamColors[caster.team])
          love.graphics.circle("line", 0, 0, self.radius*1.01)
          love.graphics.pop()
        end
      }
      table.insert(entities, self.hitbox)
    end,
    activeUpdate = function (self, dt, caster)
      self.activeTimer = self.activeTimer - dt
      self.hitbox.fill = self.activeTimer / self.activationDuration
      if not self:bindCheck() then self.keyReleased = true end
      if self:bindCheck() and self.keyReleased then self:deactivate(caster) end
    end,
    deactivate = function (self, caster)
      self.active = false
      self:onCooldownStart()
      local damage = math.floor(self.minDamage + (self.maxDamage-self.minDamage)*(1-self.hitbox.fill)) *self.damage
      caster.stuck = false
      hitInHitbox(self.hitbox, caster, damage)
      self.hitbox.terminated = true
    end
  },
  meleeAutoHit = {
    baseCooldown = 1,
    damage= 10,
    range = 30,
    name = "autoattack",
    joystickBind = 1,
    keyboardBind = "e",
    angleDelta = math.rad(180),
    activate = function (self, caster)
      local angle = 0
      local distance = 0
      for e, entity in pairs(entities) do
        if entity.team and entity.team ~= caster.team and entity.life and not entity.dead then
          angle = math.angle(caster.x, caster.y, entity.x, entity.y)
          distance = math.dist(caster.x, caster.y, entity.x, entity.y)
          deltaAngle = math.pi - math.abs(math.abs(angle - caster.angle) - math.pi);
          if distance <= self.range and deltaAngle < self.angleDelta then
            if not wallCollision(caster, entity) then
              entity:hit(self.damage)
              self:onCooldownStart()

              self:deductCosts(caster)
              caster.angle = angle
              caster.speed = {x=0,y=0}
              caster.acceleration = {x=0,y=0}
              table.insert(entities, {
                x=caster.x, y=caster.y,
                startx = caster.x, starty = caster.y,
                angle = caster.angle,
                dest=entity, timeLeft=.1, travelTime = .1,
                color={.1,.1,.1,.4},
                draw = function (self)
                  love.graphics.setColor(self.color)
                  love.graphics.translate(self.x, self.y)
                  love.graphics.rotate(self.angle)
                  love.graphics.rectangle("fill", -self.w*.5, -self.h*.5, self.w, self.h)
                  love.graphics.setColor(teamColors[caster.team])
                  love.graphics.rectangle("line", -self.w*.5*1.01, -self.h*.5*1.01, self.w*1.01, self.h*1.01)
                end,
                w = 5, h = 5,
                update  = function (self, dt)
                  self.timeLeft = self.timeLeft - dt
                  self.x = self.dest.x + (self.timeLeft/self.travelTime)*(self.startx-self.dest.x)
                  self.y = self.dest.y + (self.timeLeft/self.travelTime)*(self.starty-self.dest.y)
                  if self.timeLeft <=0 then self.terminated = true end
                end
              })
              return
            end
          end
        end
      end
    end
  },
  dash = {
    joystickBind = 6,
    keyboardBind = "lshift",
    baseCooldown = .5,
    name = "dash",
    range=300,
    rangeMin = 100,
    activationDuration = .3,
    charges = 2, maxCharges = 4, chargeCooldown = 0, baseChargeCooldown = 5,
    activate = function (self, caster)
      self:deductCosts(caster)
      self.angle = caster.angle
      self.activeTimer = self.activationDuration
      self.active = true
    end,
    activeUpdate = function (self, dt, caster)
      self.activeTimer = self.activeTimer - dt
      local distance = 600
      local maxIncrement = 5
      for i = 1, maxIncrement do
        local dx, dy = dt*distance * math.cos(self.angle), dt*distance * math.sin(self.angle)
        local collidedWalls = caster:tryMovingTo({x=caster.x + dx, y=caster.y + dy})
        distance = distance / 2
        if not collidedWalls or distance > 10 then break end
      end
    end,
    deactivate = function (self, caster)
      self.active = false
      self.charges = self.charges - 1
      self:onCooldownStart()
    end
  },
  jump = {
    name = "jump",
    joystickBind = 5,
    keyboardBind = "space",
    baseCooldown = 0,
    activationDuration = 1,
    maxZ = 8,
    activeUpdate = function (self, dt, caster)
      self.activeTimer = self.activeTimer - dt
      caster.z = self.maxZ * (self.activeTimer>.5*self.activationDuration and (1-self.activeTimer/self.activationDuration) or (self.activeTimer/self.activationDuration))
    end
  },
  shoot = {
    name = "shoot",
    joystickBind = 3,
    keyboardBind = "e",
    baseCooldown = 3,
    damage = 20,
    range = 150,
    activate = function (self, caster)
      self:deductCosts(caster)
      --spawn projectile entity
      local projectile = applyParams(movingEntityInit(), {
        color = {0, 0, 0},
        x=caster.x + math.cos(caster.angle)*5,
        y=caster.y + math.sin(caster.angle)*5,
        speedDrag = 1,
        w=5, h=1, angle=caster.angle, speed = {x=300*math.cos(caster.angle), y=300*math.sin(caster.angle)},
        timer = 0,
        draw = function (self)
          love.graphics.setColor(self.color)
          love.graphics.translate(self.x, self.y)
          love.graphics.rotate(self.angle)
          love.graphics.rectangle("fill", -self.w*.5, -self.h*.5, self.w, self.h)
          love.graphics.setColor(teamColors[caster.team])
          love.graphics.rectangle("line", -self.w*.5*1.01, -self.h*.5*1.01, self.w*1.01, self.h*1.01)
        end,
        contactDamage = self.damage,
        team = caster.team,
        collide = function (self, collider)
          if self.team and collider.team and collider.team ~= self.team then
            self.terminated = true
          end
        end,
        onWallCollision = function (self, wall)
          self.terminated = true
              table.insert(particuleEffects, {
                x = self.x, y =self.y,
                timeLeft = .4,
                draw = function (self)
                  love.graphics.translate(self.x, self.y)
                  love.graphics.setColor(1, 1, 1, .4)
                  for i = 1, 6 do
                    love.graphics.push()
                    love.graphics.rotate(i*math.pi/3)
                    love.graphics.rectangle("fill", (1-self.timeLeft/.4)*5, 0, 5, 2)
                    love.graphics.pop()
                  end
                end
              })
        end
      })
      table.insert(projectile.updates, function (self, dt)
        self.timer = self.timer + dt
        if self.timer > 4 then self.terminated = true return end
      end)
      table.insert(entities, projectile)
      self:onCooldownStart()
    end
  },
  thunderCall = {
    name = "thunderCall",
    joystickBind = 3,
    keyboardBind = "e",
    baseCooldown = 1,
    numberOfHits = 15,
    range = 120,
    interHitTimer = 0,
    damage = 10,
    activate = function (self, caster)
      self:deductCosts(caster)
      self.hitsLeft = self.numberOfHits
      self.active = true
      self.interHitTimer = 0
      self.hitbox = {x=caster.x, y=caster.y, angle = caster.angle, radius = self.range}
      if caster== player then
        self.hitbox.draw = function ( self)
          love.graphics.translate(self.x, self.y)
          love.graphics.setColor(1, 1, 1, .05)
          love.graphics.arc("line", "open", 0, 0,    self.radius, self.angle-.25*math.pi, self.angle+.25*math.pi)
          love.graphics.arc("line", "open", 0, 0, self.radius*.3, self.angle-.25*math.pi, self.angle+.25*math.pi)
          love.graphics.line(self.radius*math.cos(self.angle-.25*math.pi), self.radius*math.sin(self.angle-.25*math.pi), .3*self.radius*math.cos(self.angle-.25*math.pi), .3*self.radius*math.sin(self.angle-.25*math.pi))
          love.graphics.line(self.radius*math.cos(self.angle+.25*math.pi), self.radius*math.sin(self.angle+.25*math.pi), .3*self.radius*math.cos(self.angle+.25*math.pi), .3*self.radius*math.sin(self.angle+.25*math.pi))
        end
        table.insert(entities, self.hitbox)
      end
    end,
    activeUpdate = function (self, dt, caster)
      self.hitbox.x, self.hitbox.y, self.hitbox.angle = caster.x, caster.y, caster.angle
      if caster.dead then self:deactivate(caster) end
      if self.hitsLeft > 0 then
        self.interHitTimer = self.interHitTimer - dt
        if self.interHitTimer <= 0 then
          self.interHitTimer = .1
          local hits = math.random()*.25*self.hitsLeft + 1
          for i = 1, hits do
            self.hitsLeft = self.hitsLeft - 1
            local angle = caster.angle + (math.random()-.5)* .25*math.pi
            local distance = (.7*math.random()^1.15+.3)*self.range
            local hitbox = {
              color = {.2, .2, 1, .1},
              caster = caster,
              x=caster.x + distance*math.cos(angle), y=caster.y + distance*math.sin(angle),
              fill = 0, timerTillStrike = 1, damage= self.damage,
              radius = 15, team = caster.team,
              draw = function (self)
                love.graphics.push()
                love.graphics.setColor(self.color)
                love.graphics.translate(self.x, self.y)
                love.graphics.circle("fill", 0, 0, self.radius)
                love.graphics.setColor(1, 1, 1, (self.fill-.2)/10)
                love.graphics.circle("fill", 0, 0, self.radius*self.fill)
                love.graphics.setColor(teamColors[caster.team])
                love.graphics.circle("line", 0, 0, self.radius*1.01)
                love.graphics.pop()
              end,
              update = function (self, dt)
                self.timerTillStrike = self.timerTillStrike - dt
                self.fill = 1 - self.timerTillStrike
                if self.timerTillStrike <= 0 then
                  local hits = hitInHitbox(self, caster, self.damage)
                  if #hits > 0 and self.caster and self.caster.ressources.mana then
                    self.caster.ressources.mana.current = math.min(self.caster.ressources.mana.max, self.caster.ressources.mana.current + 3)
                  end
                  self.terminated = true
                end
              end
            }
            table.insert(entities, hitbox)
          end
        end
      else
        self:deactivate(caster)
      end
    end,
    deactivate = function (self)
      self.active = false
      self.hitbox.terminated = true
      self:onCooldownStart()
    end
  },
  valkyrie = {
    name = "valkyrie",
    joystickBind = 5,
    keyboardBind = "space",
    baseCooldown = 10,
    activationDuration = .5,
    maxZ = 8,
    hitboxSize = 30,
    hitboxRef = nil,
    range = 100,
    damage = .1,
    activate = function (self, caster)
      self:deductCosts(caster)
      self.active = true
      self.activeTimer = self.activationDuration
      self.angle = caster.angle
      self.hitboxRef = {x=caster.x, y=caster.y}
    end,
    activeUpdate = function (self, dt, caster)
      self.activeTimer = self.activeTimer - dt
      caster.z = self.maxZ * (self.activeTimer>.5*self.activationDuration and (1-self.activeTimer/self.activationDuration) or (self.activeTimer/self.activationDuration))
      local collision = caster:tryMovingTo({x=caster.x + math.cos(self.angle)*300* dt, y=caster.y + math.sin(self.angle)*300*dt})
      if collision then
        self:deactivate(caster)
      else
        caster.speed = {x=0, y=0}
        caster.acceleration = {x=0, y=0}
        if math.dist(self.hitboxRef.x, self.hitboxRef.y, caster.x, caster.y) > self.hitboxSize then
          table.insert(entities, {
            x = self.hitboxRef.x + self.hitboxSize*math.cos(self.angle), y = self.hitboxRef.y + self.hitboxSize*math.sin(self.angle),
            damage = self.damage,
            draw = function (self)
              love.graphics.setColor(self.color)
              love.graphics.translate(self.x, self.y)
              love.graphics.rotate(self.angle)
              love.graphics.rectangle("fill", -self.w*.5, -self.h*.5, self.w, self.h)
              love.graphics.setColor(teamColors[caster.team])
              love.graphics.rectangle("line", -self.w*.5*1.01, -self.h*.5*1.01, self.w*1.01, self.h*1.01)
            end,
            angle = self.angle, w = self.hitboxSize, h = self.hitboxSize,
            color = {.7, .5, .5, .5},
            timeLeft = 5, team = caster.team,
            update = function (self, dt)
              self.timeLeft = self.timeLeft - dt
              if self.timeLeft <= 0 then self.terminated = true end
              hitInHitbox(self, caster, self.damage)
            end
          })
          self.hitboxRef = {x = self.hitboxRef.x + self.hitboxSize*math.cos(self.angle), y = self.hitboxRef.y + self.hitboxSize*math.sin(self.angle)}
        end
      end
    end,
    deactivate = function (self, caster)
      self.active = false
      self:onCooldownStart()
      caster.z = 0
    end
  },
  cupcakeTrap = {
    name = "cupcakeTrap",
    joystickBind = 1,
    keyboardBind = "e",
    baseCooldown = 10,
    activationDuration = .5,
    hitboxSize = 5,
    trapDuration = 30,
    range = 80,
    hitboxes = {},
    activate = function (self, caster)
      self:deductCosts(caster)
      self.active = true
      self.activeTimer = self.activationDuration
      caster.stuck = true
      self.angle = caster.angle
      local trap = applyParams(newEntity(), {
        x=caster.x, y=caster.y,
        w = self.hitboxSize, h = self.hitboxSize,
        timeLeft = self.trapDuration, trapDuration= self.trapDuration,
        angle = caster.angle, color = {1, 0, 0, .5}, caster = caster, activated = false, victim = nil,
        draw = function (self)
          love.graphics.setColor(.7, .7, .7)
          love.graphics.translate(self.x, self.y)
          love.graphics.arc("line","open", 0, 0, self.w*1.5, -.5*math.pi,- 2*math.pi*(self.timeLeft/self.trapDuration)-.5*math.pi)
          love.graphics.setColor(self.color)
          love.graphics.rectangle("fill", -.5*self.w, -.5*self.h, self.w, self.h)
          love.graphics.setColor(teamColors[caster.team])
          love.graphics.rectangle("line", -self.w*.5*1.01, -self.h*.5*1.01, self.w*1.01, self.h*1.01)
        end,
        update = function (self, dt)
          self.timeLeft = self.timeLeft - dt
          if self.timeLeft <= 0 then
            if self.activated and self.victim then
              self.victim.stuck = false
            end
            self.terminated = true
          end
        end,
        collide = function (self, collider)
          --collision dismissed if both are in the same team (default team value 0, player and allies 1, ennemies 2 or more)
          if self.caster.team and collider.team and self.caster.team ~= collider.team then
            self.activated = true
            self.timeLeft = 3
            self.trapDuration = 3
            self.collide = nil
            self.victim = collider
            self.victim.stuck = true
          end
        end
      })
      table.insert(entities, trap)
      for i = #self.hitboxes, 1, -1 do
        if self.hitboxes[i].terminated then
          table.remove(self.hitboxes, i)
        end
      end
      table.insert(self.hitboxes, trap)
      if #self.hitboxes > 3 then
        table.remove(self.hitboxes, 1).terminated = true
      end
    end,
    deactivate = function (self, caster)
      caster.stuck = false
      self:onCooldownStart()
      self.active = false
    end
  },
  arc = {
    name = "arc",
    joystickBind = 1,
    keyboardBind = "r",
    baseCooldown = 3,
    activationDuration = .1,
    chainLenght = 120,
    chainNumber = 7,
    costs = {mana = 30},
    damage= 10,
    range = 240,
    activate = function (self, caster)
      local distance = 0
      local firstHit = nil
      local hits = {}
      local start = {x = caster.x, y = caster.y}
      local range = self.range
      local chainCount = 0
      local lastHit = nil
      repeat
        lastHit = nil
        for e, entity in pairs(entities) do
          if entity.team and entity.team ~= caster.team and entity.life and not entity.dead then
            local alreadyHit = false
            for h, hit in pairs(hits) do
              if hit == entity then
                alreadyHit = true
                break
              end
            end
            if not alreadyHit then
              distance = math.dist(start.x, start.y, entity.x, entity.y)
              if distance <= range then
                if not wallCollision(start, entity) then
                  table.insert(hits, entity)
                  firstHit = firstHit or entity
                  lastHit = entity
                  entity:hit(self.damage)
                  table.insert(particuleEffects, {
                    x=caster.x, y=caster.y,
                    p1 = start, p2 = entity, timeLeft=.1,
                    color={1,1,0, 1},
                    draw = function (self)
                      love.graphics.setColor(self.color)
                      love.graphics.line(self.p1.x, self.p1.y, self.p2.x, self.p2.y)
                    end
                  })
                  start = {x=entity.x, y = entity.y}
                  range = self.chainLenght
                  chainCount = chainCount + 1
                  if chainCount >= self.chainNumber then
                    break
                  end
                end
              end
            end
          end
        end
      until chainCount >= self.chainNumber or lastHit == nil
      if firstHit then
        self:deductCosts(caster)
        self:onCooldownStart()
        caster.angle = math.angle(caster.x, caster.y, firstHit.x, firstHit.y)
        caster.speed = {x=0,y=0}
        caster.acceleration = {x=0,y=0}
      end
    end
  },
  boeingboeingboeing = {
    name = "boeingboeingboeing",
    baseCooldown = 3,
    keyboardBind = "a",
    joystickBind = 2,
    range = 270,
    bounces = 3,
    maxZ = 3,
    explosionRadius = 30,
    damage = 30,
    activationDuration = .5,
    activate = function (self, caster)
      self:deductCosts(caster)
      projectile = applyParams(movingEntityInit(),{
        x = caster.x, y = caster.y, z = 0, maxZ = self.maxZ,
        w = 5, h = 5,
        team = caster.team,
        basesSpeed = 200,
        damage = self.damage,
        speedDrag = 1,
        speed = {x= math.cos(caster.angle)*200, y= math.sin(caster.angle)*200},
        angle = caster.angle,
        range = self.range,
        bounces = self.bounces,
        bouncesLeft = self.bounces,
        explosionRadius = self.explosionRadius,
        d = 0,
        onWallCollision = function (self, wall)
          angleWall = math.angle(wall[1].x, wall[1].y, wall[2].x, wall[2].y)
          self.angle = -self.angle + 2*angleWall
          self.speed = {x=self.basesSpeed*math.cos(self.angle), y=self.basesSpeed*math.sin(self.angle)}
        end
      })
      table.insert(projectile.updates, function (self, dt)
        local delta = self.basesSpeed * dt
        self.d = self.d + delta
        if self.d > self.range/self.bounces then
          self.bouncesLeft = self.bouncesLeft - 1
          self.d = 0
          local hitbox = {
            x = self.x, y=self.y, radius = self.explosionRadius, color = teamColors[self.team], timeLeft = .5,
            draw = function (self)
              love.graphics.translate(self.x, self.y)
              love.graphics.setColor(self.color)
              love.graphics.circle("line", 0, 0, self.radius)
            end
          }
          table.insert(particuleEffects, hitbox)
          hitInHitbox(hitbox, caster, self.damage)
          if self.bouncesLeft <= 0 then
            self.terminated = true
          end
        end
        self.z = self.maxZ*math.sin(math.pi*self.d/self.range)
      end)
      table.insert(entities, projectile)
      self.active = true
    end,
  }
}
function hitInHitbox(hitbox, caster, damage)
  damage = damage or 1
  hits = {}
  if hitbox.w and hitbox.h then
    local x, y, a, w, h = hitbox.x, hitbox.y, hitbox.angle, hitbox.w/2, hitbox.h/2
    local corners = {
      {x=x + math.cos(a)*(w) - math.sin(a)*(h),y= y + math.sin(a)*(w) + math.cos(a)*(h)},
      {x=x + math.cos(a)*(-w) - math.sin(a)*(h),y= y + math.sin(a)*(-w) + math.cos(a)*(h)},
      {x=x + math.cos(a)*(-w) - math.sin(a)*(-h),y= y + math.sin(a)*(-w) + math.cos(a)*(-h)},
      {x=x + math.cos(a)*(w) - math.sin(a)*(-h),y= y + math.sin(a)*(w) + math.cos(a)*(-h)},
    }
    for e, entity in pairs(entities) do
      if entity.team and entity.team ~= caster.team and entity.life and entity.life > 0 then
        local outside = false
        for i = 1, 4 do
          if checkIntersect(corners[i], corners[(i%4)+1], entity, {x=x, y=y}) then
            outside = true
            break
          end
        end
        if not outside then entity:hit(damage) end
      end
    end
  elseif hitbox.radius then
    for e, entity in pairs(entities) do
      if entity.team and entity.team ~= caster.team and entity.life and entity.life > 0 then
        if math.dist(hitbox.x, hitbox.y, entity.x, entity.y) <= hitbox.radius then
          entity:hit(damage)
          table.insert(hits, entity)
        end
      end
    end
  end
  return hits
end

function newAbility(libraryIndex)
  local ability = {
    update = function (self, dt, caster) end,
    active = false,
    name = "defaultName",
    range = math.huge,
    activeTimer = 0,
    displayOnUI = function (self)
      love.graphics.setColor(.2, .2, .2)
      love.graphics.rectangle("fill", 0, 0, 130, 130)
      if self.baseCooldown > 0 then
        love.graphics.setColor(1, 1, 1, .1)
        love.graphics.rectangle("fill", 0, 0, 130, 130 * (1-self.cooldown/self.baseCooldown))
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(math.floor(self.cooldown*10)/10, .5*130, .75*130)
      else
        love.graphics.setColor(1, 1, 1, .1)
        love.graphics.rectangle("fill", 0, 0, 130, 130)
      end
      love.graphics.setColor(1, 1, 1)
      love.graphics.print(self.name, .5*130-.5*love.graphics.getFont():getWidth(self.name), .5*130)
      love.graphics.print(joystickButtons[self.joystickBind])
      love.graphics.print(self.keyboardBind, 0, 115)
      if (self.charges and self.maxCharges ~= 1) then
        love.graphics.arc("line", "open", 115, 15, 15, 0-.5*math.pi,-.5*math.pi+ 2*math.pi*self.chargeCooldown/self.baseChargeCooldown)
        love.graphics.print(self.charges.."/"..self.maxCharges, 105, 8)
      end
    end,
    activationDuration = 0,
    baseCooldown = 99,
    cooldown = 0,
    keyboardBind = "a",
    joystickBind = 2,
    castConditions = function () return true end,
    bindCheck = function (self)
      return (self.joystickBind and joystick and joystick:isDown(self.joystickBind)) or(self.keyboardBind and love.keyboard.isDown(self.keyboardBind))
    end,
    activate = function (self, caster)
      if self.costs then
        self:deductCosts(caster)
      end
      self.activeTimer = self.activationDuration
      self.active = true
    end,
    activeUpdate = function (self, dt)
      self.activeTimer = self.activeTimer - dt
    end,
    deactivate = function (self)
      self.active = false
      if self.charges then
        self.charges = self.charges - 1
      else
        self:onCooldownStart()
      end
    end,
    onCooldownStart = function (self)
      self.cooldown = self.baseCooldown
    end,
    cooldownUpdate = function (self, dt, caster)
      self.cooldown = math.max(self.cooldown - dt, 0)
    end,
    onCooldownEnd = function (self)

    end,
    checkCostsAvailability = function (self, caster)
      local costsAvailable = true
      for c, cost in pairs(self.costs) do
        if not ((caster.ressources and caster.ressources[c] and caster.ressources[c].current >= cost) or (caster[c] and caster[c] >= cost)) then
          return false
        end
      end
      return true
    end,
    deductCosts = function (self, caster)
      if not self.costs then
        return
      end
      for c, cost in pairs(self.costs) do
        if (caster.ressources and caster.ressources[c] and caster.ressources[c].current >= cost) then
          caster.ressources[c].current = caster.ressources[c].current - cost
        elseif (caster[c] and caster[c] >= cost) then
          caster[c] = caster[c] - cost
        else
          error("ressource ".. c .." not found to cast" .. self.name .." of " .. caster.name.."!")
        end
      end
    end
  }
  if libraryIndex and abilitiesLibrary[libraryIndex] then
    return applyParams( ability, abilitiesLibrary[libraryIndex])
  end
  return ability
end

function ableEntityInit(entity)
  local entity = entity or newEntity()

  entity.abilities = {}
  table.insert(entity.updates, function (self, dt)
    for a, ability in pairs(self.abilities) do
      ability:update(dt, entity)
      if ability.cooldown > 0 or ability.baseCooldown <= 0 then
        ability:cooldownUpdate(dt, entity)
        if ability.cooldown <= 0 or ability.baseCooldown <= 0 then
          ability:onCooldownEnd(entity)
        end
      end
      if ability.charges then
        if ability.chargeCooldown <= 0 and ability.charges < ability.maxCharges then
          ability.chargeCooldown = ability.baseChargeCooldown
        else
          ability.chargeCooldown = ability.chargeCooldown - dt
          if ability.chargeCooldown <= 0 then
            ability.chargeCooldown = 0
            ability.charges = math.min(ability.charges + 1, ability.maxCharges)
          end
        end
      end
      if ability.active then
        ability:activeUpdate(dt, entity)
        if ability.activationDuration and ability.activationDuration > 0 and ability.activeTimer <= 0 then
          ability:deactivate(entity)
        end
      elseif ((ability.charges == nil or ability.charges > 0) and (ability.cooldown and ability.cooldown <= 0)) and ability:castConditions(entity) ~= nil then
        if (player == entity and ability:bindCheck()) or (entity.IA and a==entity.IA.cast) then
          if ability.costs then
            print("checkCostsAvailability", ability:checkCostsAvailability(entity))
            if ability:checkCostsAvailability(entity) then
              ability:activate(entity)
            end
          else
            ability:activate(entity)
          end
        end
      end
    end
  end)
  return entity
end
