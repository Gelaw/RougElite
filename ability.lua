abilitiesLibrary = {
  decimatingSmash = {
    baseCooldown = 5,
    activationDuration = .5,
    minDamage= 10,
    maxDamage= 50,
    name = "decimating smash",
    joystickBind = 2,
    keyboardBind = "a",
    range= 80,
    hitbox = nil,
    activate = function (self, caster)
      self.activeTimer = self.activationDuration
      self.active = true
      self.keyReleased = false
      caster.stuck = true
      self.hitbox = {
        color = {1, .3, .3, .2},
        x=caster.x+ .5*self.range*math.cos(caster.angle), y=caster.y + .5*self.range*math.sin(caster.angle),
        angle = caster.angle, width = self.range, height = self.range,
        fill = 0,
        draw = function (self)
          love.graphics.push()
          love.graphics.setColor(self.color)
          love.graphics.translate(self.x, self.y)
          love.graphics.rotate(self.angle)
          love.graphics.rectangle("fill", -self.width/2, -self.height/2, self.width, self.height)
          love.graphics.rectangle("fill", -self.width/2, -(1-self.fill)*self.height/2, self.width*(1-self.fill), (1-self.fill)*self.height)
          love.graphics.setColor(teamColors[caster.team])
          love.graphics.rectangle("line", -self.width*.5*1.01, -self.height*.5*1.01, self.width*1.01, self.height*1.01)
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
      self.active = false
      self.charges = self.charges - 1
      local damage = math.floor(self.minDamage + (self.maxDamage-self.minDamage)*(1-self.hitbox.fill))
      caster.stuck = false
      hitInHitbox(self.hitbox, caster, damage)
      self.hitbox.color[4] = 1
      table.insert(particuleEffects, {x=self.hitbox.x, y=self.hitbox.y, color = self.hitbox.color, nudge = self.hitbox.width, size = 2, timeLeft = 1})
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
      self.activeTimer = self.activationDuration
      self.active = true
      local x, y = caster.x+ self.distanceToCaster*math.cos(caster.angle), caster.y + self.distanceToCaster*math.sin(caster.angle)
      local wall = {{x=0, y=0}, {x=0, y=0}}
      table.insert(walls, wall)
      self.hitbox = applyParams(newEntity(),{
        color = {.2, .2, 1, 1},
        x=x, y=y,
        angle = caster.angle, width = 3, height = 40, durability = 3, team = caster.team,
        wall = wall,
        draw = function (self)
          love.graphics.push()
          love.graphics.setColor(self.color)
          love.graphics.translate(self.x, self.y)
          love.graphics.rotate(self.angle)
          love.graphics.rectangle("fill", -self.width/2, -self.height/2, self.width, self.height)
          love.graphics.setColor(teamColors[caster.team])
          love.graphics.rectangle("line", -self.width*.5*1.01, -self.height*.5*1.01, self.width*1.01, self.height*1.01)
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
      self.hitbox.wall[1] = {x=self.hitbox.x - .5*self.hitbox.height*math.cos(self.hitbox.angle+.5*math.pi), y=self.hitbox.y - .5*self.hitbox.height*math.sin(self.hitbox.angle+.5*math.pi)}
      self.hitbox.wall[2] = {x=self.hitbox.x + .5*self.hitbox.height*math.cos(self.hitbox.angle+.5*math.pi), y=self.hitbox.y + .5*self.hitbox.height*math.sin(self.hitbox.angle+.5*math.pi)}
    end,
    deactivate = function (self)
      self.active = false
      self.charges = self.charges - 1
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
    name = "absolute zero",
    joystickBind = 8,
    keyboardBind = "r";
    activationDuration = 1,
    range = 100,
    hitbox = nil,
    activate = function (self, caster)
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
      self.charges = self.charges - 1
      local damage = math.floor(self.minDamage + (self.maxDamage-self.minDamage)*(1-self.hitbox.fill))
      caster.stuck = false
      hitInHitbox(self.hitbox, caster, damage)
      self.hitbox.terminated = true
    end
  },
  meleeAutoHit = {
    baseCooldown = 1,
    damage= 10,
    range=30,
    name = "autoattack",
    joystickBind = 1,
    keyboardBind = "x",
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
              self.charges = self.charges - 1
              entity:hit(self.damage)
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
                  love.graphics.rectangle("fill", -self.width*.5, -self.height*.5, self.width, self.height)
                  love.graphics.setColor(teamColors[caster.team])
                  love.graphics.rectangle("line", -self.width*.5*1.01, -self.height*.5*1.01, self.width*1.01, self.height*1.01)
                end,
                width = 5, height = 5,
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
    baseCooldown = 3,
    name = "dash",
    range=300,
    rangeMin = 100,
    activationDuration = .3,
    charges = 2, maxCharges = 2,
    activate = function (self, caster)
      self.angle = caster.angle
      self.activeTimer = self.activationDuration
      self.active = true
    end,
    activeUpdate = function (self, dt, caster)
      self.activeTimer = self.activeTimer - dt
      local dx, dy = dt*200 * math.cos(self.angle), dt*200 * math.sin(self.angle)
      local points = getPointsGlobalCoor(caster)
      local newPosition = {x = caster.x + dx, y= caster.y + dy}
      if caster.ignoreWalls then
        caster.x = newPosition.x
        caster.y = newPosition.y
      else
        local blocked = false
        local check, blockingWall
        for p, point in pairs(points) do
          check, blockingWall = wallCollision(point, {x=point.x+dx, y=point.y+dy})
          if check then
            blocked = true
            caster.speed.x = 0
            caster.speed.y = 0
          end
        end
        if not blocked then
          caster.x = newPosition.x
          caster.y = newPosition.y
        end
      end
      for w, wall in pairs(walls) do
        local blockedInWall = false
        for p2 = 1, 4 do
          if checkIntersect(wall[1], wall[2], points[p2], points[p2%4+1]) then
            blockedInWall = true
          end
        end
        if blockedInWall then
          p = get_closest_point(wall[1].x, wall[2].y, wall[2].x, wall[2].y, caster.x, caster.y)
          local angle = math.angle(p[1], p[2], caster.x, caster.y)
          caster.x = caster.x + 3*math.cos(angle)
          caster.y = caster.y + 3*math.sin(angle)
        end
      end
    end,
    deactivate = function (self, caster)
      self.active = false
      self.charges = self.charges - 1
      caster.ignoreWalls = false
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
    baseCooldown = 1,
    damage = 20,
    activate = function (self, caster)
      --spawn projectile entity
      local projectile = {
        color = {0, 0, 0},
        x=caster.x + math.cos(caster.angle)*5,
        y=caster.y + math.sin(caster.angle)*5,
        width=5, height=1, angle=caster.angle, speed = 300,
        timer = 0,
        draw = function (self)
          love.graphics.setColor(self.color)
          love.graphics.translate(self.x, self.y)
          love.graphics.rotate(self.angle)
          love.graphics.rectangle("fill", -self.width*.5, -self.height*.5, self.width, self.height)
          love.graphics.setColor(teamColors[caster.team])
          love.graphics.rectangle("line", -self.width*.5*1.01, -self.height*.5*1.01, self.width*1.01, self.height*1.01)
        end,
        update = function (self, dt)
          self.timer = self.timer + dt
          if self.timer > 4 then self.terminated = true return end
          local newPosition = {x=self.x + math.cos(self.angle)*dt*self.speed, y=self.y + math.sin(self.angle)*dt*self.speed}
          if wallCollision(self, newPosition) then
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
              end,

            })
          else
            self.x = self.x + math.cos(self.angle)*dt*self.speed
            self.y = self.y + math.sin(self.angle)*dt*self.speed
          end
        end,
        contactDamage = self.damage,
        team = caster.team,
        collide = function (self, collider)
          if self.team and collider.team and collider.team ~= self.team then
            self.terminated = true
          end
        end
      }
      table.insert(entities, projectile)
      self.charges = self.charges - 1
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
      self.hitsLeft = self.numberOfHits
      self.active = true
      self.interHitTimer = 0
    end,
    activeUpdate = function (self, dt, caster)
      if caster.dead then self:deactivate(caster) end
      if self.hitsLeft > 0 then
        self.interHitTimer = self.interHitTimer - dt
        if self.interHitTimer <= 0 then
          self.interHitTimer = .1
          local hits = math.random()*.25*self.hitsLeft + 1
          for i = 1, hits do
            self.hitsLeft = self.hitsLeft - 1
            local angle = caster.angle + (math.random()-.5)* .5*math.pi
            local distance = (.7*math.random()^1.15+.3)*self.range
            local hitbox = {
              color = {.2, .2, 1, .1},
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
                  hitInHitbox(self, caster, self.damage)
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
      self.active = true
      self.activeTimer = self.activationDuration
      self.angle = caster.angle
      self.hitboxRef = {x=caster.x, y=caster.y}
    end,
    activeUpdate = function (self, dt, caster)
      self.activeTimer = self.activeTimer - dt
      caster.z = self.maxZ * (self.activeTimer>.5*self.activationDuration and (1-self.activeTimer/self.activationDuration) or (self.activeTimer/self.activationDuration))
      local newPosition = {x = caster.x + math.cos(self.angle)*300* dt, y= caster.y + math.sin(self.angle)*300*dt}
      if wallCollision(caster, newPosition) and not self.ignoreWalls then
        self:deactivate(caster)
      else
        caster.x = newPosition.x
        caster.y = newPosition.y
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
              love.graphics.rectangle("fill", -self.width*.5, -self.height*.5, self.width, self.height)
              love.graphics.setColor(teamColors[caster.team])
              love.graphics.rectangle("line", -self.width*.5*1.01, -self.height*.5*1.01, self.width*1.01, self.height*1.01)
            end,
            angle = self.angle, width = self.hitboxSize, height = self.hitboxSize,
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
      self.charges = self.charges - 1
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
      self.active = true
      self.activeTimer = self.activationDuration
      caster.stuck = true
      self.angle = caster.angle
      local trap = applyParams(newEntity(), {
        x=caster.x, y=caster.y,
        width = self.hitboxSize, height = self.hitboxSize,
        timeLeft = self.trapDuration, trapDuration= self.trapDuration,
        angle = caster.angle, color = {1, 0, 0, .5}, caster = caster, activated = false, victim = nil,
        draw = function (self)
          love.graphics.setColor(.7, .7, .7)
          love.graphics.translate(self.x, self.y)
          love.graphics.arc("line","open", 0, 0, self.width*1.5, -.5*math.pi,- 2*math.pi*(self.timeLeft/self.trapDuration)-.5*math.pi)
          love.graphics.setColor(self.color)
          love.graphics.rectangle("fill", -.5*self.width, -.5*self.height, self.width, self.height)
          love.graphics.setColor(teamColors[caster.team])
          love.graphics.rectangle("line", -self.width*.5*1.01, -self.height*.5*1.01, self.width*1.01, self.height*1.01)
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
      self.charges = self.charges - 1
      self.active = false
    end
  }
}

function hitInHitbox(hitbox, caster, damage)
  damage = damage or 1
  hits = {}
  if hitbox.width and hitbox.height then
    local x, y, a, w, h = hitbox.x, hitbox.y, hitbox.angle, hitbox.width/2, hitbox.height/2
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
      if self.maxCharges ~= 1 then
        love.graphics.print(self.charges.."/"..self.maxCharges, 115, 0)
      end
    end,
    activationDuration = 0,
    baseCooldown = 99,
    cooldown = 0,
    charges = 1,
    maxCharges = 1,
    keyboardBind = 2,
    joystickBind = "a",
    castConditions = function () return true end,
    bindCheck = function (self)
      return (self.joystickBind and joystick and joystick:isDown(self.joystickBind)) or(self.keyboardBind and love.keyboard.isDown(self.keyboardBind))
    end,
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
      elseif ability.charges < ability.maxCharges then
        ability:onCooldownStart()
      end
      if ability.active then
        ability:activeUpdate(dt, entity)
        if ability.activationDuration and ability.activationDuration > 0 and ability.activeTimer <= 0 then
          ability:deactivate(entity)
        end
      elseif ability.charges > 0  and ability:castConditions(entity) ~= nil then
        if (player == entity and ability:bindCheck()) or (entity.IA and a==entity.IA.cast) then
          ability:activate(entity)
        end
      end
    end
  end)
  return entity
end
