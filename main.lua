require "base"

function test()
  local joysticks = love.joystick.getJoysticks()
  if joysticks then joystick = joysticks[1] end
  gridSetup()
  cameraSetup()

  player = {
    --display
    shape = "rectangle",
    color = {.4, .6, .2},
    x=10, y=10, width=5, height=5, angle=0, elevation = 0,
    draw = function (self)
      love.graphics.push()
      love.graphics.translate(self.x, self.y)
      love.graphics.rotate(self.angle)
      love.graphics.setColor(0, 0, 0, 0.1)
      love.graphics.polygon("fill", 2, 0, -3, -2, -3, 2)
      if not player.invicibility or (math.floor(player.invicibility.time*20))%2~=1 then
        love.graphics.rotate(-self.angle)
        love.graphics.translate(0, -1-player.elevation)
        love.graphics.rotate(self.angle)
        love.graphics.scale(1+player.elevation*0.3)
        love.graphics.setColor(player.color)
        love.graphics.polygon("fill", 2, 0, -3, -2, -3, 2)
      end
      love.graphics.pop()
    end,
    --movement
    speed={x=0, y=0}, speedDrag= 0.9, maxJoystikAcceleration = 300,
    --actions
    dash = nil
  }
  player.update = function (self, dt)
    local ax, ay = 0, 0
    if joystick then
      a1, a2, a3 = joystick:getAxes()
      if math.abs(a1)>0.3 or math.abs(a2)>0.3 then
        ax, ay = self.maxJoystikAcceleration*a1*math.abs(a1), self.maxJoystikAcceleration*a2*math.abs(a2)
      end
    end
    if love.keyboard.isDown("z") and not love.keyboard.isDown("s") then
      ay = -self.maxJoystikAcceleration
    end
    if love.keyboard.isDown("s") and not love.keyboard.isDown("z") then
      ay = self.maxJoystikAcceleration
    end
    if love.keyboard.isDown("q") and not love.keyboard.isDown("d") then
      ax = -self.maxJoystikAcceleration
    end
    if love.keyboard.isDown("d") and not love.keyboard.isDown("q") then
      ax = self.maxJoystikAcceleration
    end
    if ax == 0 and ay == 0 then
      self.speed.x = self.speed.x * self.speedDrag
      self.speed.y = self.speed.y * self.speedDrag
    end
    self.speed.x = self.speed.x + ax*dt
    self.speed.y = self.speed.y + ay*dt
    self.angle = -math.atan2(self.speed.x, self.speed.y)+math.rad(90)
    self.x = self.x + self.speed.x * dt
    self.y = self.y + self.speed.y * dt

    if self.dash then
      self.dash.timer = self.dash.timer - dt
      if self.dash.timer < 0 then
        self.dash = nil
      else
        self.x = self.x + math.cos(self.dash.angle)*600 * dt
        self.y = self.y + math.sin(self.dash.angle)*600 * dt
      end
    elseif (joystick and joystick:isDown(6)) or love.keyboard.isDown("lshift") then
      self.dash = {timer = 1, angle = self.angle}
    end
    if self.jump then
      self.jump.timer = self.jump.timer + dt
      if self.jump.timer < self.jump.maxTime then
        self.elevation = self.jump.maxElevation * (self.jump.timer>.5*self.jump.maxTime and (1-self.jump.timer/self.jump.maxTime) or (self.jump.timer/self.jump.maxTime))
      else
        self.jump = nil
      end
    elseif (joystick and joystick:isDown(1)) or love.keyboard.isDown("space") then
      self.jump = {timer = 0, maxElevation = 8, maxTime = 1}
    end
    if (joystick and joystick:isDown(3)) or love.keyboard.isDown("lctrl") then
      camera.scale = math.max(camera.scale - camera.scaleChangeRate*dt, camera.minScale)
    else
      camera.scale = math.min(camera.scale + camera.scaleChangeRate*dt, camera.maxScale)
    end
  end
  table.insert(entities, player)
  camera.mode = {"follow", player}

  addDrawFunction(function ()
    love.graphics.push()
    love.graphics.translate(player.x, player.y)
    love.graphics.scale(2/camera.scale)
    love.graphics.print(math.floor(player.x) .."\t"..math.floor(player.y))
    love.graphics.pop()
  end, 8)

  for i = 1, 10 do
    local ennemy = {
      shape = "rectangle",
      color = {.1, .2, .9},
      x=math.random(-width/2, width/2), y=math.random(-height/2, height/2), width=5, height=5, angle=0,
      draw = function (self)
        basicEntityDraw(self)
        love.graphics.rotate(-self.angle)
        love.graphics.translate(3, 0)
        love.graphics.scale(2/camera.scale)
        love.graphics.print(self.IA.task)
      end,
      --movement
      speed={x=0, y=0}, speedDrag= 0.9, maxAcceleration = 90,
      --actions
      shootCooldown = 0,
      --behavior
      update = function (self, dt)
        self.IA[self.IA.task](self.IA, self, dt)
      end,
      IA = {
        task = "follow", shootCooldown = 0,
        follow = function (self, intelligentEntity, dt)
          intelligentEntity.angle = -math.atan2(intelligentEntity.x - player.x, intelligentEntity.y - player.y)-math.rad(90)
          intelligentEntity.speed.x = intelligentEntity.speed.x + intelligentEntity.maxAcceleration*math.cos(intelligentEntity.angle)*dt*math.min(1,math.abs(intelligentEntity.x - player.x)/600)
          intelligentEntity.speed.y = intelligentEntity.speed.y + intelligentEntity.maxAcceleration*math.sin(intelligentEntity.angle)*dt*math.min(1,math.abs(intelligentEntity.y - player.y)/600)
          intelligentEntity.x = intelligentEntity.x + intelligentEntity.speed.x * dt
          intelligentEntity.y = intelligentEntity.y + intelligentEntity.speed.y * dt
          if (math.abs(intelligentEntity.x - player.x) < 60 and math.abs(intelligentEntity.y -  player.y) < 60) then
            self.task = "slowdown"
          end
        end,
        slowdown = function (self, intelligentEntity, dt)
          intelligentEntity.speed.x = intelligentEntity.speed.x * intelligentEntity.speedDrag
          intelligentEntity.speed.y = intelligentEntity.speed.y * intelligentEntity.speedDrag
          intelligentEntity.x = intelligentEntity.x + intelligentEntity.speed.x * dt
          intelligentEntity.y = intelligentEntity.y + intelligentEntity.speed.y * dt
          if math.abs(intelligentEntity.speed.x) < 0.1 and math.abs(intelligentEntity.speed.y) < 0.1 then
            self.task = "shoot"
          end
        end,
        shoot = function (self, intelligentEntity, dt)
          intelligentEntity.angle = -math.atan2(intelligentEntity.x - player.x, intelligentEntity.y - player.y)-math.rad(90)
          local projectile = {
              shape = "rectangle",
              color = {0, 0, 0},
              x=intelligentEntity.x + math.cos(intelligentEntity.angle)*5,
              y=intelligentEntity.y + math.sin(intelligentEntity.angle)*5,
              width=3, height=1, angle=intelligentEntity.angle, speed = 300,
              timer = 0,
              update = function (self, dt)
                self.timer = self.timer + dt
                if self.timer > 4 then self.killmenow = true return end
                self.x = self.x + math.cos(self.angle)*dt*self.speed
                self.y = self.y + math.sin(self.angle)*dt*self.speed
              end
          }
          self.shootCooldown = 0.8
          self.task = "reload"
          table.insert(entities, projectile)
        end,
        reload = function (self, intelligentEntity, dt)
          self.shootCooldown = self.shootCooldown - dt
          if self.shootCooldown <= 0 then
            if (math.abs(intelligentEntity.x - player.x) > 100 or math.abs(intelligentEntity.y -  player.y) > 100) then
              self.task = "follow"
            else
              self.task = "shoot"
            end
          end
        end
      }
    }
    -- ennemy.update = function (self, dt)
      -- --follow player
      -- self.angle = -math.atan2(self.x - player.x, self.y - player.y)-math.rad(90)
      -- if  (self.x<-960 and self.x>960 and self.y<-540 and self.y>540) then
      --   self.speed.x = 0
      --   self.speed.y = 0
      --   self.x = math.max(math.min(self.x, 960), -960)
      --   self.y = math.max(math.min(self.y, 540), -540)
      -- elseif (math.abs(self.x - player.x) > 60 or math.abs(self.y -  player.y) > 60) then
      --   self.speed.x = self.speed.x + self.maxAcceleration*math.cos(self.angle)*dt*math.min(1,math.abs(self.x - player.x)/600)
      --   self.speed.y = self.speed.y + self.maxAcceleration*math.sin(self.angle)*dt*math.min(1,math.abs(self.y - player.y)/600)
      -- else
      --   self.speed.x = self.speed.x * self.speedDrag
      --   self.speed.y = self.speed.y * self.speedDrag
      -- end
      -- self.x = self.x + self.speed.x * dt
      -- self.y = self.y + self.speed.y * dt
      -- self.shootCooldown = self.shootCooldown - dt
      -- if self.shootCooldown <= 0 then
      --   if math.abs(self.speed.x) < 0.1 and math.abs(self.speed.y) < 0.1 then
      --     self.shootCooldown = .8
      --     local projectile = {
      --       shape = "rectangle",
      --       color = {0, 0, 0},
      --       x=self.x + math.cos(self.angle)*5, y=self.y + math.sin(self.angle)*5, width=3, height=1, angle=self.angle, speed = 300,
      --       timer = 0,
      --       update = function (self, dt)
      --         self.timer = self.timer + dt
      --         if self.timer > 4 then self.killmenow = true return end
      --         self.x = self.x + math.cos(self.angle)*dt*self.speed
      --         self.y = self.y + math.sin(self.angle)*dt*self.speed
      --       end
      --     }
      --     table.insert(entities, projectile)
      --   end
      -- end
    -- end
    table.insert(entities, ennemy)
  end
end

function cameraSetup()
  camera.scale = 4
  camera.maxScale = 6
  camera.minScale = 3
  camera.scaleChangeRate = 2
end
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
function love.joystickpressed(joystick, button)
  -- print(button)
end
function love.keypressed(key, scancode, isrepeat)
  if key == "escape" then
    love.event.quit()
  end
end
