
meleeTank = function ()
  return applyParams(IAinit(ableEntityInit(livingEntityInit(movingEntityInit()))), {
    maxSpeed= 40,
    color = {.5, .4, .8},
    life = 10,
    contactDamage = 1,
    abilities = {
      fracasMeutrier = applyParams(newAbility(), {
        baseCooldown = 5,
        activationDuration = .5,
        minDamage= 1,
        maxDamage= 5,
        displayOnUI = function (self)
          love.graphics.setColor(.2, .2, .2)
          love.graphics.rectangle("fill", 0, 0, 130, 130)
          love.graphics.setColor(1, 1, 1, .1)
          love.graphics.rectangle("fill", 0, 0, 130, 130 * (1-self.cooldown/self.baseCooldown))
        end,
        hitbox = nil,
        activate = function (self, caster)
          self.activeTimer = self.activationDuration
          self.active = true
          self.keyReleased = false
          caster.stuck = true
          self.hitbox = applyParams(newEntity(),{
            color = {1, .3, .3, .2},
            x=caster.x+ 40*math.cos(caster.angle), y=caster.y + 40*math.sin(caster.angle),
            angle = caster.angle, width = 80, height = 80,
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
        end,
        bindCheck = function ()
          return (joystick and joystick:isDown(2)) or love.keyboard.isDown("a")
        end
      }),
      unbreakable = applyParams(newAbility(), {
        baseCooldown = 5,
        displayOnUI = function (self)
          love.graphics.setColor(.2, .2, .2)
          love.graphics.rectangle("fill", 0, 0, 130, 130)
          if self.active then
            local t = love.timer.getTime()
            love.graphics.setColor(0, math.cos(t), math.sin(t), .9)
            love.graphics.rectangle("fill", 0, 0, 130, 130)
          elseif self.cooldown and self.cooldown > 0 then
            love.graphics.setColor(1, 1, 1, .1)
            love.graphics.rectangle("fill", 0, 0, 130, 130 * (1-self.cooldown/self.baseCooldown))
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(math.floor(self.cooldown*10)/10, 130/2, 130/2)
          end
        end,
        distanceToCaster = 10,
        activationDuration = 10,
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
      }),
      absoluteZero = applyParams(newAbility(), {
        baseCooldown = 30,
        minDamage= 2,
        maxDamage= 10,
        displayOnUI = function (self)
          love.graphics.setColor(.2, .2, .2)
          love.graphics.rectangle("fill", 0, 0, 130, 130)
          love.graphics.setColor(1, 1, 1, .1)
          love.graphics.rectangle("fill", 0, 0, 130, 130 * (1-self.cooldown/self.baseCooldown))
        end,
        activationDuration = 1,
        radius = 100,
        hitbox = nil,
        activate = function (self, caster)
          self.activeTimer = self.activationDuration
          self.active = true
          self.keyReleased = false
          caster.stuck = true
          self.hitbox = applyParams(newEntity(),{
            color = {.5, .5, 1, .1}, radius = self.radius,
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
              if math.dist(self.hitbox.x, self.hitbox.y, entity.x, entity.y) <= self.hitbox.radius then
                entity:hit(damage)
              end
            end
          end
          self.hitbox.terminated = true
        end,
        bindCheck = function ()
          return (joystick and joystick:isDown(8)) or love.keyboard.isDown("r")
        end
      })
    },
    IA = {
      task = "idle", aggroRange = 200, effectiveCombatRange = 30,
      idle = function (self, entity, dt)
        if not player or not player.life or player.life <= 0 then return end
        if math.dist(entity.x, entity.y, player.x, player.y) < self.aggroRange then
          --turn toward player
          entity.angle = -math.atan2(entity.x - player.x, entity.y - player.y)-math.rad(90)
          self.task = "unbreakable"
        end
      end,
      unbreakable = function (self, entity, dt)
        local distanceToPlayer = math.dist(entity.x, entity.y, player.x, player.y)
        if distanceToPlayer > self.aggroRange then
          self.task = "idle"
        end
        --turn toward player
        entity.angle = -math.atan2(entity.x - player.x, entity.y - player.y)-math.rad(90)
        --math stuff for movement
        entity.acceleration = {x=entity.maxAcceleration*math.cos(entity.angle), y=entity.maxAcceleration*math.sin(entity.angle)}

        --check if player is close
        if distanceToPlayer < self.effectiveCombatRange then
          --switch to "slowdown" task
          self.task = "slowdown"
        end
      end,
      slowdown = function (self, entity, dt)
        entity.acceleration = {x=0, y=0}
        --check if speed is close to 0
        if math.abs(entity.speed.x) < 0.1 and math.abs(entity.speed.y) < 0.1 then
          --turn toward player
          entity.angle = -math.atan2(entity.x - player.x, entity.y - player.y)-math.rad(90)
          -- switch to "shoot" task
          self.task = "attack"
        elseif math.dist(entity.x, entity.y, player.x, player.y) > self.effectiveCombatRange then
          --switch to "unbreakable" task
          self.task = "unbreakable"
        end
      end,
      attack = function (self, entity, dt)
        if entity.abilities.fracasMeutrier.cooldown <= 0 then
          self.task = "fracasMeutrier"
          return
        end
        if entity.abilities.absoluteZero.cooldown <= 0 then
          self.task = "absoluteZero"
          return
        end
        self.task = "unbreakable"
      end,
      fracasMeutrier = function (self, entity, dt)
        --turn toward player
        entity.angle = -math.atan2(entity.x - player.x, entity.y - player.y)-math.rad(90)
        if entity.abilities.fracasMeutrier.cooldown > 0 then
          self.task = "unbreakable"
          return
        end
      end,
      absoluteZero = function (self, entity, dt)
        if entity.abilities.absoluteZero.cooldown > 0 then
          self.task = "unbreakable"
          return
        end
      end
    }
  })
end
