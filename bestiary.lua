abilitiesLibrary = {
  decimatingSmash = {
    baseCooldown = 5,
    activationDuration = .5,
    minDamage= 1,
    maxDamage= 5,
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
      self.hitbox = applyParams(newEntity(),{
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
          love.graphics.setColor(0, 0, 0)
          love.graphics.rotate(-self.angle)
          love.graphics.print(math.floor(self.fill*10)/10)
          love.graphics.pop()
        end
      })
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
      local x, y, a, w, h = self.hitbox.x, self.hitbox.y, self.hitbox.angle, self.hitbox.width/2, self.hitbox.height/2
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
      self.hitbox.color[4] = 1
      table.insert(particuleEffects, {x=x, y=y, color = self.hitbox.color, nudge = w, size = 2, timeLeft = 1})
      self.hitbox.terminated = true
    end
  },
  unbreakable = {
    baseCooldown = 5,
    range = 30,
    distanceToCaster = 10,
    activationDuration = 10,
    joystickBind = 4,
    keyboardBind = "e",
    name = "unbreakable",
    hitbox = nil,
    activate = function (self, caster)
      self.activeTimer = self.activationDuration
      self.active = true
      self.hitbox = applyParams(newEntity(),{
        color = {.2, .2, 1, 1},
        x=caster.x+ self.distanceToCaster*math.cos(caster.angle), y=caster.y + self.distanceToCaster*math.sin(caster.angle),
        angle = caster.angle, width = 3, height = 40, durability = 3, team = caster.team,
        draw = function (self)
          love.graphics.push()
          love.graphics.setColor(self.color)
          love.graphics.translate(self.x, self.y)
          love.graphics.rotate(self.angle)
          love.graphics.rectangle("fill", -self.width/2, -self.height/2, self.width, self.height)
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
    end,
    deactivate = function (self)
      self.active = false
      self.charges = self.charges - 1
      self.hitbox.terminated = true
    end,
    bindCheck = function ()
      return (joystick and joystick:isDown(4)) or love.keyboard.isDown("e")
    end
  },
  absoluteZero = {
    baseCooldown = 30,
    minDamage= 2,
    maxDamage= 10,
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
      self.hitbox = applyParams(newEntity(),{
        color = {.5, .5, 1, .1}, radius = self.range,
        x=caster.x, y=caster.y, fill = self.activeTimer / self.activationDuration,
        draw = function (self)
          love.graphics.push()
          love.graphics.setColor(self.color)
          love.graphics.translate(self.x, self.y)
          love.graphics.circle("fill", 0, 0, self.radius)
          love.graphics.circle("fill", 0, 0, self.radius*self.fill)
          love.graphics.pop()
        end,
      })
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
      for e, entity in pairs(entities) do
        if entity.team and entity.team ~= caster.team and entity.life and entity.life > 0 then
          if math.dist(self.hitbox.x, self.hitbox.y, entity.x, entity.y) <= self.range then
            entity:hit(damage)
          end
        end
      end
      self.hitbox.terminated = true
    end
  },
  meleeAutoHit = {
    baseCooldown = .5,
    damage= 1,
    range=30,
    name = "autoattack",
    joystickBind = 1,
    keyboardBind = "x",
    angleDelta = math.rad(90),
    activate = function (self, caster)
      local angle = 0
      local distance = 0
      for e, entity in pairs(entities) do
        if entity.team and entity.team ~= caster.team and entity.life and not entity.dead then
          angle = math.angle(caster.x, caster.y, entity.x, entity.y)
          distance = math.dist(caster.x, caster.y, entity.x, entity.y)
          deltaAngle = math.pi - math.abs(math.abs(angle - caster.angle) - math.pi);
          if distance <= self.range and deltaAngle < self.angleDelta then
            self.active=true
            entity:hit(self.damage)
            caster.angle = angle
            caster.speed = {x=0,y=0}
            caster.acceleration = {x=0,y=0}
            table.insert(particuleEffects, {x=entity.x, y=entity.y, timeLeft=.1, color={.1,.1,.1,.4}, nudge=5, size=5})
            return
          end
        end
      end
    end
  },
  dash = {
    joystickBind = 6,
    keyboardBind = "lshift",
    baseCooldown = 1,
    name = "dash",
    activationDuration = .3,
    charges = 3, maxCharges = 3,
    activate = function (self, caster)
      self.angle = caster.angle
      self.activeTimer = self.activationDuration
      self.active = true
    end,
    activeUpdate = function (self, dt, caster)
      self.activeTimer = self.activeTimer - dt
      local newPosition = {x = caster.x + math.cos(self.angle)*200 * dt, y= caster.y + math.sin(self.angle)*200 * dt}
      if wallCollision(caster, newPosition) and not self.ignoreWalls then
        self:deactivate(caster)
      else
        caster.x = newPosition.x
        caster.y = newPosition.y
      end
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
    activate = function (self, caster)

      --spawn projectile entity
      local projectile = {
          shape = "rectangle",
          color = {0, 0, 0},
          x=caster.x + math.cos(caster.angle)*5,
          y=caster.y + math.sin(caster.angle)*5,
          width=5, height=1, angle=caster.angle, speed = 300,
          timer = 0,
          update = function (self, dt)
            self.timer = self.timer + dt
            if self.timer > 4 then self.terminated = true return end
            self.x = self.x + math.cos(self.angle)*dt*self.speed
            self.y = self.y + math.sin(self.angle)*dt*self.speed
          end,
          contactDamage = 2,
          team = caster.team,
          collide = function (self, collider)
            if self.team and collider.team and collider.team ~= self.team then
              self.terminated = true
            end
          end
      }

      table.insert(entities, projectile)
      self.active = true
    end
  }
}

meleeTank = function ()
  return applyParams(IAinit(ableEntityInit(livingEntityInit(movingEntityInit()))), {
    maxSpeed= 40,
    color = {.5, .4, .8},
    life = 10,
    contactDamage = 1,
    abilities = {
      decimatingSmash = applyParams(newAbility(), abilitiesLibrary.decimatingSmash),
      unbreakable = applyParams(newAbility(), abilitiesLibrary.unbreakable),
      absoluteZero = applyParams(newAbility(), abilitiesLibrary.absoluteZero)
    },
    IA = basicIA()
  })
end

meleeDps = function ()
  return applyParams(IAinit(ableEntityInit(livingEntityInit(movingEntityInit()))), {
    maxSpeed= 120,
    color = {.8, .4, .2},
    life = 6,
    maxLife=6,
    abilities = {
      autohit = applyParams(newAbility(), abilitiesLibrary.meleeAutoHit),
      dash = applyParams(newAbility(), abilitiesLibrary.dash)
    },
    IA = basicIA()
  })
end
