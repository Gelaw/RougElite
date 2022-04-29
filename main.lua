require "base"
require "level"
require "entity"

function test()
  local joysticks = love.joystick.getJoysticks()
  if joysticks then joystick = joysticks[1] end

  --player hud
  addDrawFunction(function()
    --lifebar display
    love.graphics.translate(player.x, player.y)
    love.graphics.translate(-15, -15)
    if player.life then
      love.graphics.setColor(.1, .1, .2, .3)
      love.graphics.rectangle("fill", 3, 0, 3*10, 5)
      love.graphics.setColor(.1, .8, .2, .7)
      love.graphics.rectangle("fill", 3, 0, 3*player.life, 5)
    end
    --dash charges display
    if player.abilities and player.abilities.dash then
      for i = 1, player.abilities.dash.maxCharges do
        if player.abilities.dash.charges < i then
          love.graphics.setColor(.1, .1, .2, .3)
        else
          love.graphics.setColor(0, .3, .9)
        end
        love.graphics.circle("fill", 4+10*(i-1), 5, 3)
        if player.abilities.dash.charges == i - 1 then
          love.graphics.setColor(0, .3, .9)
          love.graphics.arc("fill", 4+10*(i-1), 5, 3, -math.pi/2+ 2*math.pi*(1-player.abilities.dash.cooldown/player.abilities.dash.baseCooldown), -math.pi/2)
        end
      end
    end
    --position display
    love.graphics.translate(8, 30)
    love.graphics.scale(.2)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(math.floor(player.x) .."\t"..math.floor(player.y))
  end, 8)
  --abilities hud
  addDrawFunction( function ()
    if not player.abilities then return end
    love.graphics.origin()
    love.graphics.translate(20, height - 150)
    for a, ability in pairs(player.abilities) do
      if ability.displayOnUI then
        ability:displayOnUI()
        love.graphics.translate(150, 0)
      end
    end
  end , 8)
  --hitbox debug display
  addDrawFunction(function ()
    if showHitboxes then
      local c = 0
      for e, entity in pairs(entities) do
        local points = getPointsGlobalCoor(entity)
        local pts = {}
        for p, point in pairs(points) do
          table.insert(pts, point.x)
          table.insert(pts, point.y)
        end
        if #pts>6 then
          c=c+1
          love.graphics.setColor(1, 1, 1, .2)
          love.graphics.polygon("fill", pts)
          love.graphics.setColor(1, 1, 1)
          love.graphics.polygon("line", pts)
        end
      end
    end
  end, 9)

  gridSetup()
  levelDisplayInit()
  start()


  addUpdateFunction(function (dt)
    if collectibles < 10 and math.random()>.99 then
      collectibles = collectibles + 1
      table.insert(entities, {
        shape = "rectangle",
        x = (math.random()-.5)*width, y = (math.random()-.5)*height,
        width = 5, height = 5, color = {.2, .8, .4},
        collide = function (self, collider)
          if collider == player then
            collectibles = collectibles - 1
            player.life = math.min(player.maxLife, player.life + 1)
            table.insert(particuleEffects, {
              x=self.x, y=self.y, color = {1, .2, .2}, nudge = 5, size = 3, timeLeft = 1.5,
              pluslygon = {-1,-1,  -1,-3,  1,-3,  1,-1,  3,-1,  3,1,  1,1,  1,3,  -1,3,  -1,1,  -3,1,  -3,-1},
              draw = function (self)
                love.graphics.translate(self.x, self.y)
                love.graphics.scale(.5)
                love.graphics.setColor(self.color)
                local t = love.timer.getTime() % 3600
                for i = 1, 4 do
                  love.graphics.push()
                  love.graphics.translate(math.cos(10*t+i*39)*5, math.cos(12*t+i*22)*5)
                  love.graphics.polygon("fill", self.pluslygon)
                  love.graphics.pop()
                end
              end
            })
            self.terminated = true
          end
        end
      })
    end
  end)

  --torch/candle (cosmetic only)
  table.insert(entities, {
    x = 0, y=0, radius=100,angle=0, color = {.7, .7, 0, 0.2}, shear = {x=0, y=0},
    polygon = { 0,0,  -2,-1,  -3,-3,  -2,-5,  0,-10,  2,-5,  3,-3,  2,-1,},
    draw=function (self)
      love.graphics.translate(self.x, self.y)
      love.graphics.setColor(.8, .8, .8, .8)
      love.graphics.rectangle("fill", -2, 0, 4, 5)
      love.graphics.setColor(.5, .5, .5, .5)
      love.graphics.rectangle("fill", -1, 0, 2, -2)
      love.graphics.shear(self.shear.x, self.shear.y)
      love.graphics.polygon("line",self.polygon)
      love.graphics.setColor(self.color)
      love.graphics.polygon("fill",self.polygon)
      love.graphics.push()
      love.graphics.setColor(self.color)
      love.graphics.translate(0, -3)
      love.graphics.scale(.5)
      love.graphics.polygon("fill", self.polygon)
      love.graphics.translate(0, 4)
      love.graphics.setColor({1, 0, .5, .3})
      love.graphics.polygon("fill", self.polygon)
      love.graphics.pop()
      love.graphics.rotate(self.angle)
      love.graphics.setColor(self.color)
      love.graphics.circle("fill", 0, 0, self.radius)
    end,
    update = function (self, dt)
      self.color[1], self.color[2], self.color[4] = self.color[1]+(math.random()-.5)*.01, self.color[2]+(math.random()-.5)*.01, self.color[4]+(math.random()-.5)*.01
      self.radius = self.radius +(math.random()-.49)*.1
      self.angle = self.angle + math.random()*.01
      self.shear = {x=self.shear.x+.01*(math.random()-.5), y=self.shear.y+.01*(math.random()-.5)}
    end
  })
end

function start()
  math.randomseed(os.time())
  levelSetup()
  cameraSetup()
  collectibles = 0
  player = applyParams(playerInit(ableEntityInit(livingEntityInit(movingEntityInit()))),  {
    --display
    color = {.4, .6, .2},
    x=10, y=10,
    abilities = {
      dash = applyParams(newAbility(), {
        baseCooldown = 1,
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
        end,
        bindCheck = function ()
          return (joystick and joystick:isDown(6)) or love.keyboard.isDown("lshift")
        end
      }),
      jump = applyParams(newAbility(), {
        baseCooldown = 0.001,
        activationDuration = 1,
        maxZ = 8,
        activeUpdate = function (self, dt, caster)
          self.activeTimer = self.activeTimer - dt
          caster.z = self.maxZ * (self.activeTimer>.5*self.activationDuration and (1-self.activeTimer/self.activationDuration) or (self.activeTimer/self.activationDuration))
        end,
        bindCheck = function ()
          return (joystick and joystick:isDown(1)) or love.keyboard.isDown("space")
        end
      }),
      fracasMeutrier = applyParams(newAbility(), {
        baseCooldown = 5,
        activationDuration = 3,
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
              if not outside then entity:hit() end
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
            angle = caster.angle, width = 3, height = 40, durability = 3, team = 1,
            draw = function (self)
              love.graphics.push()
              love.graphics.setColor(self.color)
              love.graphics.translate(self.x, self.y)
              love.graphics.rotate(self.angle)
              love.graphics.rectangle("fill", -self.width/2, -self.height/2, self.width, self.height)
              love.graphics.pop()
            end,
            collide = function (self, collider)
              if collider.team and collider.team <= 1 then return end
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
        displayOnUI = function (self)
          love.graphics.setColor(.2, .2, .2)
          love.graphics.rectangle("fill", 0, 0, 130, 130)
          love.graphics.setColor(1, 1, 1, .1)
          love.graphics.rectangle("fill", 0, 0, 130, 130 * (1-self.cooldown/self.baseCooldown))
        end,
        activationDuration = 10,
        hitbox = nil,
        activate = function (self, caster)
          self.activeTimer = self.activationDuration
          self.active = true
          self.keyReleased = false
          caster.stuck = true
          self.hitbox = applyParams(newEntity(),{
            color = {.5, .5, 1, .1}, radius = 70,
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
          caster.stuck = false
          for e, entity in pairs(entities) do
            if entity.team and entity.team ~= caster.team and entity.life and entity.life > 0 then
              if math.dist(self.hitbox.x, self.hitbox.y, entity.x, entity.y) <= self.hitbox.radius then
                entity:hit()
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
  })

  table.insert(entities, player)

  --use in base camera.update()
  camera.mode = {"follow", player}



  --ennemy spawn
  for i = 1, 10 do
    local type = math.random(2)
    local ennemy = applyParams(ableEntityInit(livingEntityInit(movingEntityInit())),
      {
        color = (type == 1 and  {.1, .2, .9} or {.9, .3, .1}),
        ignoreWalls = type == 1,
        x=math.random(-width/2, width/2), y=math.random(-height/2, height/2),
        height = (type == 1 and 5 or 10), contactDamage = (type==1 and nil or 1),
        draw = function (self)
          --function defined in base for quick display
          basicEntityDraw(self)
          --display current IA task of entity
          love.graphics.rotate(-self.angle)
          love.graphics.translate(3, 0)
          love.graphics.scale(2/camera.scale)
          love.graphics.print(self.IA.task)
        end,
        maxAcceleration = math.random(1200, 1500)*type,
        maxSpeed = 100,
        abilities = {
          shoot = applyParams(newAbility(), {
            baseCooldown = math.random(1, 9),
            displayOnUI = function (self)
              love.graphics.setColor(.2, .2, .2)
              love.graphics.rectangle("fill", 0, 0, 130, 130)
              love.graphics.setColor(1, 1, 1, .1)
              love.graphics.rectangle("fill", 0, 0, 130, 130 * (1-self.cooldown/self.baseCooldown))
            end,
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
            end,
            bindCheck = function ()
              return (joystick and joystick:isDown(4)) or love.keyboard.isDown("e")
            end
          })
        },
        --behavior
        IA = {
          --default task
          task = "follow",
          shootCooldownTimer = 0, shootCooldown = math.random(1, 9),
          followDistance = math.random(30, 120), shootDistance = math.random(30, 90),
          follow = function (self, entity, dt)
            --turn toward player
            entity.angle = -math.atan2(entity.x - player.x, entity.y - player.y)-math.rad(90)
            --math stuff for movement
            entity.acceleration = {x=entity.maxAcceleration*math.cos(entity.angle), y=entity.maxAcceleration*math.sin(entity.angle)}

            --check if player is close
            if (math.abs(entity.x - player.x) < self.shootDistance and math.abs(entity.y -  player.y) < self.shootDistance) then
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
              self.task = "shoot"
            end
          end,
          shoot = function (self, entity, dt)
            --turn toward player
            entity.angle = -math.atan2(entity.x - player.x, entity.y - player.y)-math.rad(90)
            --init a cooldown timer and switch to reload task
            if entity.abilities.shoot.cooldown > 0 then
              self.task = "reload"
            end
          end,
          reload = function (self, entity, dt)
            if entity.abilities.shoot.cooldown > 0 then return end
            if (math.abs(entity.x - player.x) > self.followDistance or math.abs(entity.y -  player.y) > self.followDistance) then
              self.task = "follow"
            else
              self.task = "shoot"
            end
          end
        },
        --necessary for base collision detection to consider this entity
        team = 2,
        life = 1,
        onDeath = function (self)
          self.IA.task = "dead"
          self.contactDamage = nil
          self.speed = {x=0,y=0}
          self.color = {.3, .3, .3}
          table.insert(particuleEffects, {x=self.x, y=self.y, color = {.6, .2, .2}, nudge = 5, size = 3, timeLeft = 1})
        end
      }
    )
    table.insert(ennemy.updates,
      function (self, dt)
        if self.IA and self.IA[self.IA.task] then
          self.IA[self.IA.task](self.IA, self, dt)
        end
      end)
    table.insert(entities, ennemy)
  end

  safeLoadAndRun("editableScript.lua")
end

--variables used in player update
function cameraSetup()
  camera.scale = 4
  camera.maxScale = 4
  camera.minScale = 3
  camera.scaleChangeRate = 2
end
-- run once at launch to create basic background grid for ease of localisation
function gridSetup()
  local canvas = love.graphics.newCanvas(width, height)

  love.graphics.setCanvas(canvas)
  canvas:setFilter("nearest")
  love.graphics.setColor(1,1,1)
  love.graphics.setLineStyle("rough")
  for x = 1, width, 30 do
    love.graphics.line(x, 0, x, height)
  end
  for y = 1, height, 30 do
    love.graphics.line(0, y, width, y)
  end

  love.graphics.setCanvas()
  addDrawFunction(function ()
    love.graphics.setColor(1,1,1, .2)
    love.graphics.draw(canvas, -width/2, -height/2)
  end, 4)
end

function wallCollision(start, destination)
  for w, wall in pairs(walls) do
    if checkIntersect(wall[1], wall[2], start, destination) then return true end
  end
  return false
end

function love.joystickpressed(joystick, button)
end

function love.keypressed(key, scancode, isrepeat)
  if key == "escape" then
    love.event.quit()
  end
  if key == "k" then
    entities = {}
    start()
  end
  if key == "h" then
    showHitboxes = not showHitboxes
  end
end
