require "base"
require "level"
require "entity"

function test()
  local joysticks = love.joystick.getJoysticks()
  if joysticks then joystick = joysticks[1] end

  gridSetup()
  levelDisplayInit()
  start()

end

function start()
  math.randomseed(os.time())
  levelSetup()
  cameraSetup()

  player = applyParams(ableEntity(livingEntityInit(movingEntityInit())),  {
    --display
    shape = nil,
    color = {.4, .6, .2},
    x=10, y=10, z = 0,
    draw = function (self)
      love.graphics.push()
      love.graphics.translate(self.x, self.y)
      love.graphics.rotate(self.angle)
      --shadow display
      love.graphics.setColor(0, 0, 0, 0.1)
      love.graphics.polygon("fill", 2, 0, -3, -2, -3, 2)
      --body display (flickering in case of invicibility frames)
      love.graphics.rotate(-self.angle)
      love.graphics.translate(0, -1-self.z)
      love.graphics.rotate(self.angle)
      love.graphics.scale(1+self.z*0.3)
      if not self.invicibility or (math.floor(self.invicibility.time*20))%2~=1 then
          -- jump calculations
        love.graphics.setColor(self.color)
        love.graphics.polygon("fill", 2, 0, -3, -2, -3, 2)
      end
      --lifebar display
      love.graphics.rotate(-self.angle)
      love.graphics.translate(-15, -15)
      love.graphics.setColor(.1, .1, .2, .3)
      love.graphics.rectangle("fill", 3, 0, 3*10, 5)
      love.graphics.setColor(.1, .8, .2, .7)
      love.graphics.rectangle("fill", 3, 0, 3*self.life, 5)
      for i = 1, self.abilities.dash.maxCharges do
        if self.abilities.dash.charges < i then
          love.graphics.setColor(.1, .1, .2, .3)
        else
          love.graphics.setColor(0, .3, .9)
        end
        love.graphics.circle("fill", 4+10*(i-1), 5, 3)
        if self.abilities.dash.charges == i - 1 then
          love.graphics.setColor(0, .3, .9)
          love.graphics.arc("fill", 4+10*(i-1), 5, 3, -math.pi/2+ 2*math.pi*(1-self.abilities.dash.cooldown/self.abilities.dash.baseCooldown), -math.pi/2)
        end
      end
      --position display
      love.graphics.translate(8, 30)
      love.graphics.scale(.2)
      love.graphics.setColor(0, 0, 0)
      love.graphics.print(math.floor(self.x) .."\t"..math.floor(self.y))
      love.graphics.pop()
    end,
    -- actions
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
          caster.x = caster.x + math.cos(self.angle)*200 * dt
          caster.y = caster.y + math.sin(self.angle)*200 * dt
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
            if entity.team and entity.team > 1 and entity.life and entity.life > 0 then
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
          table.insert(particuleEffects, {x=x, y=y, color = self.hitbox.color, nudge = w/3, size = 3, timeLeft = 1})
          self.hitbox.terminated = true
        end,
        bindCheck = function ()
          return (joystick and joystick:isDown(2)) or love.keyboard.isDown("a")
        end
      })
    },
    --gameplay(?)
    team = 1,
    onHit = function (self)
      cameraShake(20, .5)
      if joystick and joystick:isVibrationSupported() then
        joystick:setVibration(.05, .05, .2 )
      end
    end,
    onDeath = function (self)
      self.update = nil
      self.collide = nil
      self.color = {.7, .1, .1}
      table.insert(particuleEffects, {x=self.x, y=self.y, color = {.6, .2, .2}, nudge = 5, size = 3, timeLeft = 1})
    end
  })
  table.insert(player.updates,
    function (self, dt)
      --temporary acceleration variables
      local ax, ay = 0, 0
      --if gamepad is connected, use left joystick as input
      if joystick then
        a1, a2, a3 = joystick:getAxes()
        --check if joystick is outside of deadzone (TODO later: parameter 0.3 to be extrated and made modifiable once parameter norm in place)
        if math.abs(a1)>0.3 or math.abs(a2)>0.3 then
          ax, ay = self.maxAcceleration*a1*math.abs(a1), self.maxAcceleration*a2*math.abs(a2)
        end
      end
      --keyboard ZQSD binds for player movement
      if love.keyboard.isDown("z") and not love.keyboard.isDown("s") then
        ay = -self.maxAcceleration
      end
      if love.keyboard.isDown("s") and not love.keyboard.isDown("z") then
        ay = self.maxAcceleration
      end
      if love.keyboard.isDown("q") and not love.keyboard.isDown("d") then
        ax = -self.maxAcceleration
      end
      if love.keyboard.isDown("d") and not love.keyboard.isDown("q") then
        ax = self.maxAcceleration
      end
      --speed, position and orientation calculations
      self.speed.x = (self.speed.x + ax*dt)*self.speedDrag
      self.speed.y = (self.speed.y + ay*dt)*self.speedDrag
      if math.abs(self.speed.x)>0 or math.abs(self.speed.y)>0 then
        self.angle = -math.atan2(self.speed.x, self.speed.y)+math.rad(90)
      end

      --camera zoom control
      -- variables set in "cameraSetup()" method
      if (joystick and joystick:isDown(3)) or love.keyboard.isDown("lctrl") then
        camera.scale = math.max(camera.scale - camera.scaleChangeRate*dt, camera.minScale)
      else
        camera.scale = math.min(camera.scale + camera.scaleChangeRate*dt, camera.maxScale)
      end
    end)
  table.insert(entities, player)
  --use in base camera.update()
  camera.mode = {"follow", player}


  --ennemy spawn
  for i = 1, 10 do
    local type = math.random(2)
    local ennemy = applyParams(livingEntityInit(movingEntityInit()),
      {
        color = (type == 1 and  {.1, .2, .9} or {.9, .3, .1}),
        ignoreWalls = type == 1,
        x=math.random(-width/2, width/2), y=math.random(-height/2, height/2),
        draw = function (self)
          --function defined in base for quick display
          basicEntityDraw(self)
          --display current IA task of entity
          love.graphics.rotate(-self.angle)
          love.graphics.translate(3, 0)
          love.graphics.scale(2/camera.scale)
          love.graphics.print(self.IA.task)
        end,
        speedDrag= math.random(0, 8)/10, maxAcceleration = math.random(45, 60)*type,
        maxSpeed = 100,
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
            entity.speed.x = entity.speed.x + entity.maxAcceleration*math.cos(entity.angle)*dt
            entity.speed.y = entity.speed.y + entity.maxAcceleration*math.sin(entity.angle)*dt

            --check if player is close
            if (math.abs(entity.x - player.x) < self.shootDistance and math.abs(entity.y -  player.y) < self.shootDistance) then
              --switch to "slowdown" task
              self.task = "slowdown"
            end
          end,
          slowdown = function (self, entity, dt)
            --math stuff for movement
            entity.speed.x = entity.speed.x * entity.speedDrag
            entity.speed.y = entity.speed.y * entity.speedDrag
            local newPosition = {x = entity.x + entity.speed.x * dt, y= entity.y + entity.speed.y * dt}
            --check if speed is close to 0
            if math.abs(entity.speed.x) < 0.1 and math.abs(entity.speed.y) < 0.1 then
              -- switch to "shoot" task
              self.task = "shoot"
            end
          end,
          shoot = function (self, entity, dt)
            --turn toward player
            entity.angle = -math.atan2(entity.x - player.x, entity.y - player.y)-math.rad(90)
            --spawn projectile entity
            local projectile = {
                shape = "rectangle",
                color = {0, 0, 0},
                x=entity.x + math.cos(entity.angle)*5,
                y=entity.y + math.sin(entity.angle)*5,
                width=3, height=1, angle=entity.angle, speed = 300,
                timer = 0,
                update = function (self, dt)
                  self.timer = self.timer + dt
                  if self.timer > 4 then self.terminated = true return end
                  self.x = self.x + math.cos(self.angle)*dt*self.speed
                  self.y = self.y + math.sin(self.angle)*dt*self.speed
                end,
                team = 2,
                collide = function () end
            }
            table.insert(entities, projectile)
            --init a cooldown timer and switch to reload task
            self.shootCooldownTimer = self.shootCooldown
            self.task = "reload"
          end,
          reload = function (self, entity, dt)
            --cooldown countdown
            self.shootCooldownTimer = self.shootCooldownTimer - dt
            if self.shootCooldownTimer <= 0 then
              --switch to "follow" task if player is far or "shoot" task otherwise
              if (math.abs(entity.x - player.x) > self.followDistance or math.abs(entity.y -  player.y) > self.followDistance) then
                self.task = "follow"
              else
                self.task = "shoot"
              end
            end
          end
        },
        --necessary for base collision detection to consider this entity
        team = 2,
        life = 1,
        onDeath = function (self)
          self.update = nil
          self.IA.task = "dead"
          self.collide = nil
          self.color = {.8, .3, .3}
          table.insert(particuleEffects, {x=self.x, y=self.y, color = {.6, .2, .2}, nudge = 5, size = 3, timeLeft = 1})
        end
      }
    )
    table.insert(ennemy.updates,
      function (self, dt)
        self.IA[self.IA.task](self.IA, self, dt)
      end)
    table.insert(entities, ennemy)
  end
end

--variables used in player update
function cameraSetup()
  camera.scale = 1--4
  camera.maxScale = 1--6
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
  if player.life <= 0 then
    entities = {}
    table.insert(entities, player)
    start()
  end
end

function love.keypressed(key, scancode, isrepeat)
  if key == "escape" then
    love.event.quit()
  end
  if player.life <= 0 then
    entities = {}
    table.insert(entities, player)
    start()
  end
end
