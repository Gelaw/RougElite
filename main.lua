require "base"

function test()
  local joysticks = love.joystick.getJoysticks()
  if joysticks then joystick = joysticks[1] end
  gridSetup()

  start()

end

function start()
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
      --shadow display
      love.graphics.setColor(0, 0, 0, 0.1)
      love.graphics.polygon("fill", 2, 0, -3, -2, -3, 2)
      --body display (flickering in case of invicibility frames)
      if not self.invicibility or (math.floor(self.invicibility.time*20))%2~=1 then
          -- jump calculations
        love.graphics.rotate(-self.angle)
        love.graphics.translate(0, -1-self.elevation)
        love.graphics.rotate(self.angle)
        love.graphics.scale(1+self.elevation*0.3)
        love.graphics.setColor(self.color)
        love.graphics.polygon("fill", 2, 0, -3, -2, -3, 2)
      end
      --lifebar display
      love.graphics.rotate(-self.angle)
      love.graphics.translate(-15, -15)
      for i = 1, 10 do
        love.graphics.setColor(.1, .1, .2, .3)
        love.graphics.rectangle("fill", 3*i, 0, 3, 5)
        if self.vie >= i then
          love.graphics.setColor(.1, .8, .2, .7)
          love.graphics.rectangle("fill", 3*i, 0, 3, 5)
        end
      end
      --position display
      love.graphics.translate(8, 30)
      love.graphics.scale(.2)
      love.graphics.setColor(0, 0, 0)
      love.graphics.print(math.floor(player.x) .."\t"..math.floor(player.y))
      love.graphics.pop()
    end,
    --movement
    speed={x=0, y=0}, speedDrag= 0.9, maxAcceleration = 300,
    --actions
    dash = nil, jump = nil,
    --gameplay(?)
    vie = 10, invicibility = nil,
    collide = function (self, collider)
      --collision dismissed in case of invicibility or jump
      if self.invicibility or self.jump then return end
      --life deduction
      self.vie = self.vie - 1
      self.invicibility = {time = .5}
      --death check
      if self.vie <= 0 then
        self.update = nil
        self.collide = nil
        self.color = {.7, .1, .1}
      end
    end
  }
  player.update = function (self, dt)
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
    --if no acceleration detected from inputs, slow down player
    if ax == 0 and ay == 0 then
      self.speed.x = self.speed.x * self.speedDrag
      self.speed.y = self.speed.y * self.speedDrag
    end
    --speed, position and orientation calculations
    self.speed.x = self.speed.x + ax*dt
    self.speed.y = self.speed.y + ay*dt
    self.angle = -math.atan2(self.speed.x, self.speed.y)+math.rad(90)
    self.x = self.x + self.speed.x * dt
    self.y = self.y + self.speed.y * dt

    --gameplay mecanics
    --invicibility
    -- simple timer, with collide and display effects
    if self.invicibility then
      --timer countdown
      self.invicibility.time = self.invicibility.time - dt
      if self.invicibility.time <= 0 then
        --invicibility end
        self.invicibility = nil
      end
    end
    --dash
    --move player in the direction snapshoted at dash start for a timer
    if self.dash then
      --timer countdown
      self.dash.timer = self.dash.timer - dt
      if self.dash.timer < 0 then
        --dash end
        self.dash = nil
      else
        --dash physics
        self.x = self.x + math.cos(self.dash.angle)*200 * dt
        self.y = self.y + math.sin(self.dash.angle)*200 * dt
      end
    elseif (joystick and joystick:isDown(6)) or love.keyboard.isDown("lshift") then
      --dash init
      self.dash = {timer = 1, angle = self.angle}
    end

    --jump
    --change a display variable during a time,prevents collisions during
    if self.jump then
      --timer countdown
      self.jump.timer = self.jump.timer + dt
      if self.jump.timer < self.jump.maxTime then
        --display variable update
        self.elevation = self.jump.maxElevation * (self.jump.timer>.5*self.jump.maxTime and (1-self.jump.timer/self.jump.maxTime) or (self.jump.timer/self.jump.maxTime))
      else
        --jump end
        self.jump = nil
      end
    elseif (joystick and joystick:isDown(1)) or love.keyboard.isDown("space") then
      --jump init
      self.jump = {timer = 0, maxElevation = 8, maxTime = 1}
    end

    --camera zoom control
    -- variables set in "cameraSetup()" method
    if (joystick and joystick:isDown(3)) or love.keyboard.isDown("lctrl") then
      camera.scale = math.max(camera.scale - camera.scaleChangeRate*dt, camera.minScale)
    else
      camera.scale = math.min(camera.scale + camera.scaleChangeRate*dt, camera.maxScale)
    end
  end
  table.insert(entities, player)
  --use in base camera.update
  camera.mode = {"follow", player}


  --ennemy spawn
  for i = 1, 10 do
    local ennemy = {
      shape = "rectangle",
      color = {.1, .2, .9},
      x=math.random(-width/2, width/2), y=math.random(-height/2, height/2), width=5, height=5, angle=0,
      draw = function (self)
        --function defined in base for quick display
        basicEntityDraw(self)
        --display current IA task of entity
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
        --default task
        task = "follow",
        shootCooldown = 0,
        follow = function (self, intelligentEntity, dt)
          --turn toward player
          intelligentEntity.angle = -math.atan2(intelligentEntity.x - player.x, intelligentEntity.y - player.y)-math.rad(90)
          --math stuff for movement
          intelligentEntity.speed.x = intelligentEntity.speed.x + intelligentEntity.maxAcceleration*math.cos(intelligentEntity.angle)*dt*math.min(1,math.abs(intelligentEntity.x - player.x)/600)
          intelligentEntity.speed.y = intelligentEntity.speed.y + intelligentEntity.maxAcceleration*math.sin(intelligentEntity.angle)*dt*math.min(1,math.abs(intelligentEntity.y - player.y)/600)
          intelligentEntity.x = intelligentEntity.x + intelligentEntity.speed.x * dt
          intelligentEntity.y = intelligentEntity.y + intelligentEntity.speed.y * dt
          --check if player is close
          if (math.abs(intelligentEntity.x - player.x) < 60 and math.abs(intelligentEntity.y -  player.y) < 60) then
            --switch to "slowdown" task
            self.task = "slowdown"
          end
        end,
        slowdown = function (self, intelligentEntity, dt)
          --math stuff for movement
          intelligentEntity.speed.x = intelligentEntity.speed.x * intelligentEntity.speedDrag
          intelligentEntity.speed.y = intelligentEntity.speed.y * intelligentEntity.speedDrag
          intelligentEntity.x = intelligentEntity.x + intelligentEntity.speed.x * dt
          intelligentEntity.y = intelligentEntity.y + intelligentEntity.speed.y * dt
          --check if speed is close to 0
          if math.abs(intelligentEntity.speed.x) < 0.1 and math.abs(intelligentEntity.speed.y) < 0.1 then
            -- switch to "shoot" task
            self.task = "shoot"
          end
        end,
        shoot = function (self, intelligentEntity, dt)
          --turn toward player
          intelligentEntity.angle = -math.atan2(intelligentEntity.x - player.x, intelligentEntity.y - player.y)-math.rad(90)
          --spawn projectile entity
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
              end,
              collide = function () end
          }
          table.insert(entities, projectile)
          --init a cooldown timer and switch to reload task
          self.shootCooldown = 0.8
          self.task = "reload"
        end,
        reload = function (self, intelligentEntity, dt)
          --cooldown countdown
          self.shootCooldown = self.shootCooldown - dt
          if self.shootCooldown <= 0 then
            --switch to "follow" task if player is far or "shoot" task otherwise
            if (math.abs(intelligentEntity.x - player.x) > 100 or math.abs(intelligentEntity.y -  player.y) > 100) then
              self.task = "follow"
            else
              self.task = "shoot"
            end
          end
        end
      },
      --necessary for base collision detection to consider this entity
      collide = function () end
    }
    table.insert(entities, ennemy)
  end
end
--variables used in player update
function cameraSetup()
  camera.scale = 4
  camera.maxScale = 6
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


function love.joystickpressed(joystick, button)
  if player.vie <= 0 then
    entities = {}
    table.insert(entities, player)
    start()
  end
end
function love.keypressed(key, scancode, isrepeat)
  if key == "escape" then
    love.event.quit()
  end
  if player.vie <= 0 then
    entities = {}
    table.insert(entities, player)
    start()
  end
end
