require "base"
require "level"
require "entity"
require "bestiary"
require "ia"

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
      love.graphics.rectangle("fill", 3, 0, 3*player.maxLife, 5)
      if player.life > 0 then
        love.graphics.setColor(.1, .8, .2, .7)
      else
        love.graphics.setColor(.8, .2, .1, .2)
      end
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
  player = entitySetup({ableEntityInit,livingEntityInit,movingEntityInit,playerInit},  {
    --display
    color = {.4, .6, .2},
    x=10, y=10,
    abilities = {
      dash = applyParams(newAbility(), abilitiesLibrary.dash),
      jump = applyParams(newAbility(), abilitiesLibrary.jump),
      decimatingSmash = applyParams(newAbility(), abilitiesLibrary.decimatingSmash),
      unbreakable = applyParams(newAbility(), abilitiesLibrary.unbreakable),
      absoluteZero = applyParams(newAbility(), abilitiesLibrary.absoluteZero),
      autohit = applyParams(newAbility(), abilitiesLibrary.meleeAutoHit),
      shoot = applyParams(newAbility(), abilitiesLibrary.shoot)
    },
  })

  table.insert(entities, player)


  --ennemy spawn
  for i = 1, 10 do
    local type = math.random(2)
    local ennemy = entitySetup({IAinit,ableEntityInit,livingEntityInit,movingEntityInit},{
        color = (type == 1 and  {.1, .2, .9} or {.9, .3, .1}),
        ignoreWalls = type == 1,
        x=math.random(-width/2, width/2), y=math.random(-height/2, height/2),
        height = (type == 1 and 5 or 10), contactDamage = (type==1 and nil or 1),
        maxAcceleration = math.random(1200, 1500)*type,
        maxSpeed = 100,
        abilities = {
          shoot = applyParams(newAbility(), abilitiesLibrary.shoot)
        },
        --behavior
        IA = basicIA(),
        --necessary for base collision detection to consider this entity
        team = 2,
        life = 3+2*type, maxLife = 3+2*type,
      }
    )
    table.insert(entities, ennemy)
  end
  for i = 1, 20 do
    if math.random() > .5  then
      table.insert(entities, applyParams(meleeDps(), {x=math.random(-width/2, width/2), y=math.random(-height/2, height/2), team=2}))
    else
      table.insert(entities, applyParams(meleeTank(), {x=math.random(-width/2, width/2), y=math.random(-height/2, height/2), team=2}))
    end
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
  if key == "k"  then
    if not player.dead then
      player.dead = true
      player:onDeath()
    else
      player = entitySetup({ableEntityInit,livingEntityInit,movingEntityInit,playerInit},  {
        --display
        color = {.4, .6, .2},
        x=ghost.x, y=ghost.y,
        abilities = {
          dash = applyParams(newAbility(), abilitiesLibrary.dash),
          jump = applyParams(newAbility(), abilitiesLibrary.jump),
          decimatingSmash = applyParams(newAbility(), abilitiesLibrary.decimatingSmash),
          unbreakable = applyParams(newAbility(), abilitiesLibrary.unbreakable),
          absoluteZero = applyParams(newAbility(), abilitiesLibrary.absoluteZero),
          autohit = applyParams(newAbility(), abilitiesLibrary.meleeAutoHit),
          shoot = applyParams(newAbility(), abilitiesLibrary.shoot)
        },
      })
      table.insert(entities, player)
      ghost.terminated = true
    end
  end
  if key == "h" then
    showHitboxes = not showHitboxes
  end
end
