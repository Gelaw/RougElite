
function gameSetup()
  local joysticks = love.joystick.getJoysticks()
  if joysticks then joystick = joysticks[1] end
  lifebarWidth = 30
  teamColors = {
    {0, 0, 1, .2},
    {1, 0, 0, .2},
    {0, 1, 0, .2}
  }


  normalfont = love.graphics.newFont(12)
  bigassfont = love.graphics.newFont(48)


  difficultyCoef = 1
  enemies = {}
  updateTimerClosestEnemy = .2
  addUpdateFunction(function (dt)
    if not player or #enemies==0 then return end
    updateTimerClosestEnemy = updateTimerClosestEnemy - dt
    if updateTimerClosestEnemy <= 0 then
      updateTimerClosestEnemy = 3
      closest, dist = enemies[1], math.dist(player.x, player.y,enemies[1].x, enemies[1].y)
      for e = #enemies, 1, -1 do
        enemy = enemies[e]
        if enemy.dead or enemy.terminated then
          table.remove(enemies, e)
        else
          enemy.IA.difficultyCoef = difficultyCoef
          if math.dist(player.x, player.y,enemy.x, enemy.y) < dist then
            closest, dist = enemy, math.dist(player.x, player.y,enemy.x, enemy.y)
          end
        end
      end
      closest.IA.difficultyCoef = 10
    end
  end)
  addDrawFunction(function ()
    if not closest then return end
    love.graphics.setColor(1, 1, 1)
    love.graphics.translate(closest.x, closest.y)
    love.graphics.line(-20, -20, -15, -20)
    love.graphics.line(-20, -20, -20, -15)
    love.graphics.line(20, 20, 15, 20)
    love.graphics.line(20, 20, 20, 15)
    love.graphics.line(20, -20, 15, -20)
    love.graphics.line(20, -20, 20, -15)
    love.graphics.line(-20, 20, -15, 20)
    love.graphics.line(-20, 20, -20, 15)
  end ,9)
  addDrawFunction(function ()
    if StartingNumberEnemies > 0 then
      if #enemies == 0 then
        love.graphics.push()
        love.graphics.origin()
        love.graphics.translate(.5*width, .5*height)
        victoire = victoire or {s=30}
        love.graphics.setColor(.73, .5, .4)
        love.graphics.polygon("fill",
        victoire.s,  victoire.s,
        -victoire.s,  victoire.s,
        -1.5*victoire.s, 0,
        -victoire.s, -victoire.s,
        victoire.s, -victoire.s,
        1.5*victoire.s, 0)
        victoire.s = math.min(victoire.s + 1, 120)
        love.graphics.setColor(.2, .8, .4)
        local text = "Victoire"
        love.graphics.setFont(bigassfont)
        love.graphics.print(text, -.5*bigassfont:getWidth(text),-.5*bigassfont:getHeight())
        love.graphics.setFont(normalfont)
        love.graphics.pop()
        return
      end
      love.graphics.origin()
      love.graphics.setColor(.1, .1, .2, .3)
      love.graphics.print(#enemies)
      love.graphics.setFont(bigassfont)
      local text = "Enemy forces:"
      local marge = 30 + bigassfont:getWidth(text)
      love.graphics.rectangle("fill", marge, 30, width - 2*marge, bigassfont:getHeight())
      love.graphics.setColor(.5, .1, .1)
      love.graphics.print(text, 30, 30)
      love.graphics.rectangle("fill", marge, 30, (width - 2*marge)*#enemies/StartingNumberEnemies, bigassfont:getHeight())
      love.graphics.setFont(normalfont)
    end
  end, 9)
  --player hud
  addDrawFunction(function()
    if player then
      --lifebar display
      love.graphics.push()
      love.graphics.translate(player.x, player.y)
      love.graphics.translate(-15, -15)
      if player.life then
        love.graphics.setColor(.1, .1, .2, .3)
        love.graphics.rectangle("fill", 3, 0, lifebarWidth, 5)
        if player.life > 0 then
          love.graphics.setColor(.1, .8, .2, .7)
        else
          love.graphics.setColor(.8, .2, .1, .2)
        end
        love.graphics.rectangle("fill", 3, 0, lifebarWidth*math.max(player.life, 0)/player.maxLife, 5)
        love.graphics.setColor(.8, .2, .1, .9)
        love.graphics.rectangle("fill", 3+lifebarWidth*math.max(player.life, 0)/player.maxLife, 0, lifebarWidth*player.healthCutoff/player.maxLife, 5)
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
      love.graphics.pop()
    end
    if ghost then
      love.graphics.translate(ghost.x, ghost.y)
      love.graphics.setColor(1, 1, 1, .2)
      for e, entity in pairs(entities) do
        if entity.team and entity.team > 1 and entity.dead and entity.collide then
          local angle = math.angle(ghost.x, ghost.y, entity.x, entity.y)
          local distance = math.dist(ghost.x, ghost.y, entity.x, entity.y)
          love.graphics.push()
          if entity.archetypeName then
            love.graphics.print(entity.archetypeName, entity.x-camera.x-.5*normalfont:getWidth(entity.archetypeName), entity.y-camera.y-15)
          end
          love.graphics.rotate(angle)
          love.graphics.arc("line", "open", distance, 0, 20, math.rad(15), 2*math.pi/3 - math.rad(15))
          love.graphics.arc("line", "open", distance, 0, 20, 2*math.pi/3 + math.rad(15), 4*math.pi/3 - math.rad(15))
          love.graphics.arc("line", "open", distance, 0, 20, 4*math.pi/3 + math.rad(15), 2*math.pi - math.rad(15))

          love.graphics.translate((math.min(distance/100, .9)+.1)*50, 0)
          love.graphics.polygon("fill", 0, 0, -10, 3, -10, -3)
          love.graphics.pop()
        end
      end
    end
  end, 8)
  --abilities hud
  addDrawFunction( function ()
    if not player or not player.abilities then return end
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

  levelDisplayInit()
  levelSetup()
  cameraSetup()

end


function spawn(enemyArchetype, params)

  local entity = applyParams(enemyArchetype(), params)

  table.insert(entities, entity)
  if entity.team and entity.team > 1 then
    table.insert(enemies, entity)
  end
  if entity.dead then
    entity:onDeath()
  end
  return entity
end

function newPlayer(params)

  player = entitySetup({ableEntityInit,livingEntityInit,movingEntityInit,playerInit},  {
    --display
    color = {.4, .6, .2},
    maxLife = 1000,
    life = 1000,
    x=0, y=0,
    abilities = {
      shoot = newAbility("shoot"),
      boeingboeingboeing = newAbility("boeingboeingboeing"),
    },
  })
  if params then
    applyParams(player, params)
  end
  table.insert(entities, player)
end


--variables used in player update
function cameraSetup()
  camera.scale = 1
  camera.maxScale = 2
  camera.minScale = 1
  camera.scaleChangeRate = 2
end
