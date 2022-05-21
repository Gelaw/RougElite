
function levelDisplayInit()

    --wall Display
      -- TODO non urgent setup a image on load to increase display performances
    addDrawFunction( function ()
        for w, wall in pairs(walls) do
          love.graphics.setColor(0, 0, 0)
          love.graphics.line(wall[1].x, wall[1].y, wall[2].x, wall[2].y)
        end
      end
    )

    --room Display
    addDrawFunction(function ()
      for r, room in pairs(rooms) do
        love.graphics.setColor(room.roomcolor)
        love.graphics.rectangle("fill", room.x-room.w/2, room.y-room.h/2, room.w, room.h)
      end
    end, 3)

    --minimap
    addDrawFunction(function ()
      love.graphics.origin()
      love.graphics.scale(.1)
      love.graphics.translate(.5*width+100, .5*height+100)
      love.graphics.setColor(.2,.2,.2)
      love.graphics.rectangle("fill", -.5*width-100, -.5*height-100, width+200, height+200)
      love.graphics.translate(-camera.x, -camera.y)
      for r, room in pairs(rooms) do
        love.graphics.setColor(room.roomcolor)
        love.graphics.rectangle("fill", room.x-room.w/2, room.y-room.h/2, room.w, room.h)
      end
      love.graphics.scale(10)
      love.graphics.setColor(0, 0, 0)
      for w, wall in pairs(walls) do
        love.graphics.line(wall[1].x/10, wall[1].y/10, wall[2].x/10, wall[2].y/10)
      end
      if player then
        love.graphics.scale(.1)
        love.graphics.setColor(player.color)
        love.graphics.rectangle("fill", player.x, player.y, math.max(player.width, 30), math.max(player.height, 30))
      end
      if ghost then
        love.graphics.scale(.1)
        love.graphics.setColor(ghost.color)
        love.graphics.rectangle("fill", ghost.x, ghost.y, math.max(ghost.width, 30), math.max(ghost.height, 30))
      end
    end,9)
end



function levelSetup()
  --wall Generation
  walls = {}
  rooms = {}
  baseRoomSize = 300
  genX, genY = 0, 0


  roomWidth, roomHeight = baseRoomSize*2, baseRoomSize/2
  generate(roomWidth, roomHeight, "north")
  i=-1
  for a, archetype in pairs(enemiesLibrary) do
    i=i+1
    local corpse = applyParams(enemiesLibrary[a](), {x=genX+((i+.5)/3-.5)*roomWidth, y=genY+roomHeight*.3, team=2, dead=true})
    corpse:onDeath()
    table.insert(entities, corpse)
  end


  roomWidth, roomHeight = baseRoomSize/2, baseRoomSize*3
  generate(roomWidth, roomHeight, "north")
  enemy = applyParams(enemiesLibrary.meleeTank(), {x=genX+math.random(-roomWidth/2, roomWidth/2), y=genY+math.random(-roomHeight/2, roomHeight/2), team=2})
  table.insert(enemies, enemy)
  table.insert(entities, enemy)


  roomWidth, roomHeight = baseRoomSize*2, baseRoomSize*2
  generate(roomWidth, roomHeight, "north")
  for i = 1, 3 do
    ennemy = applyParams(enemiesLibrary.meleeDps(), {x=genX+math.random(-roomWidth/2, roomWidth/2), y=genY+math.random(-roomHeight/2, roomHeight/2), team=2})
    table.insert(enemies, ennemy)
    table.insert(entities, ennemy)
  end

  roomWidth, roomHeight = baseRoomSize/2, baseRoomSize/2
  generate(roomWidth, roomHeight, "east")
  for i = 1, 3 do
    table.insert(entities, {
      shape = "rectangle",
      x = genX+(math.random()-.5)*roomWidth, y = genY+(math.random()-.5)*roomHeight,
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
  roomWidth, roomHeight = baseRoomSize*3, baseRoomSize/2
  generate(roomWidth, roomHeight, "east")
  for i = 1, 4 do
    ennemy = applyParams(enemiesLibrary.shooter(), {x=genX+math.random(-roomWidth/2, roomWidth/2), y=genY+math.random(-roomHeight/2, roomHeight/2), team=2})
    table.insert(enemies, ennemy)
    table.insert(entities, ennemy)
  end
  generate(3*baseRoomSize/2, 2*baseRoomSize/3, "north")

  roomWidth, roomHeight = baseRoomSize*3, baseRoomSize*3
  generate(roomWidth, roomHeight)
  ennemy = applyParams(enemiesLibrary.meleeTank(), {x=genX, y=genY, team=2, life = 20, maxSpeed = 125, width=25, height = 25, color = {.9, .2, .2}})
  table.insert(enemies, ennemy)
  table.insert(entities, ennemy)

end

local lastGenerated = nil
local lastOut = nil
function generate(w, h, out)
  doors = {}
  if lastGenerated then
    local entrance = cardinalOpposite(lastOut)
    genX = lastGenerated.x + directions[lastOut][1] * (lastGenerated.w/2  + w/2)
    genY = lastGenerated.y + directions[lastOut][2] * (lastGenerated.h/2  + h/2)
    doors[entrance] = {c=.5,w=.2}
  end
  if out then
    doors[out] = {c=.5,w=.2}
  end
  lastGenerated = addRoom({x=genX, y=genY}, w, h, doors)
  lastOut = out
end

directions = {
  north = {0, -1},
  south = {0, 1},
  east = {1, 0},
  west = {-1, 0}
}

function cardinalOpposite(direction)
  if direction == "north" then
    return "south"
  end
  if direction == "south" then
    return "north"
  end
  if direction == "west" then
    return "east"
  end
  if direction == "east" then
    return "west"
  end
end


function addRoom(p, w, h, doors)
  local doors = doors or {}
  addWall({x=p.x-w/2, y=p.y-h/2}, {x=p.x+w/2, y=p.y-h/2}, doors.north)
  addWall({x=p.x-w/2, y=p.y-h/2}, {x=p.x-w/2, y=p.y+h/2}, doors.west)
  addWall({x=p.x-w/2, y=p.y+h/2}, {x=p.x+w/2, y=p.y+h/2}, doors.south)
  addWall({x=p.x+w/2, y=p.y-h/2}, {x=p.x+w/2, y=p.y+h/2}, doors.east)
  local roomcolor = {math.random()*.2+.4, math.random()*.2+.4, math.random()*.2+.4, 1}
  room = {x=p.x, y=p.y, w=w, h=h,  roomcolor=roomcolor}
  table.insert(rooms, room)
  return room
end

function addWall(p1, p2, door)
  if door then
    local pa = {x=p1.x + math.max(door.c-door.w/2,0)*(p2.x - p1.x), y=p1.y + math.max(door.c-door.w/2,0)*(p2.y - p1.y)}
    if p1.x ~= pa.x or p1.y ~= pa.y then
      table.insert(walls, {p1, pa})
    end
    local pb = {x=p1.x + math.min(door.c+door.w/2,1)*(p2.x - p1.x), y=p1.y + math.min(door.c+door.w/2,1)*(p2.y - p1.y)}
    if pb.x ~= p2.x or pb.y ~= p2.y then
      table.insert(walls, {pb, p2})
    end
  else
    table.insert(walls, {p1, p2})
  end
end



--- Previous level generation

function previousLevelSetup()
  repis = {w=200, h=200}
  walls = {}
  rooms = {}
  p1 = p1 or {x=-width/2, y=-height/2}
  p2 = p2 or {x= width/2, y= height/2}

  table.insert(walls, {p1, {x=p1.x, y=p2.y}})
  table.insert(walls, {p1, {x=p2.x, y=p1.y}})
  table.insert(walls, {p2, {x=p2.x, y=p1.y}})
  table.insert(walls, {{x=p1.x, y=p2.y}, {x=(p1.x+p2.x)/2-repis.w/2, y=p2.y}})
  table.insert(walls, {{x=(p1.x+p2.x)/2+repis.w/2, y=p2.y}, p2})
  table.insert(walls, {{x=(p1.x+p2.x)/2+repis.w/2, y=p2.y}, {x=(p1.x+p2.x)/2+repis.w/2, y=p2.y+repis.h}})
  table.insert(walls, {{x=(p1.x+p2.x)/2-repis.w/2, y=p2.y}, {x=(p1.x+p2.x)/2-repis.w/2, y=p2.y+repis.h}})
  table.insert(walls, {{x=(p1.x+p2.x)/2+repis.w/2, y=p2.y+repis.h}, {x=(p1.x+p2.x)/2-repis.w/2, y=p2.y+repis.h}})
  i=-1
  for a, archetype in pairs(enemiesLibrary) do
    i=i+1
    local corpse = applyParams(enemiesLibrary[a](), {x=((i+.5)/3-.5)*repis.w, y=p2.y+repis.h*.3, team=2, dead=true})
    corpse:onDeath()
    table.insert(entities, corpse)
  end

  splitRoom(p1, p2)
end

function splitRoom(p1, p2, horizontal)
  if horizontal == nil then horizontal = math.random()<.5 end
  --Recursive breakpoint: room size
  if math.abs(p2.x - p1.x) > 500 and math.abs(p2.y - p1.y) > 500 then
    --midPoint : wall and door position
    local mp = {x=math.random(p1.x+250, p2.x-250), y = math.random(p1.y+250, p2.y-250)}
    if horizontal then
      table.insert(walls, {{x=mp.x-30, y=mp.y}, {x=p1.x, y=mp.y}})
      table.insert(walls, {{x=mp.x+30, y=mp.y}, {x=p2.x, y=mp.y}})
      splitRoom(p1, {x=p2.x, y=mp.y}, false)
      splitRoom({x=p1.x, y=mp.y}, p2, false)
    else
      table.insert(walls, {{x=mp.x, y=mp.y-30}, {x=mp.x, y=p1.y}})
      table.insert(walls, {{x=mp.x, y=mp.y+30}, {x=mp.x, y=p2.y}})
      splitRoom(p1, {x=mp.x, y=p2.y}, true)
      splitRoom({x=mp.x, y=p1.y}, p2, true)
    end
  else
    local roomcolor = {math.random()*.2+.2, math.random()*.2+.2, math.random()*.2+.2, 1}
    table.insert(rooms, {x=(p1.x+p2.x)/2, y=(p1.y+p2.y)/2, w=math.abs(p2.x-p1.x),h=math.abs(p2.y-p1.y), roomcolor=roomcolor})
  end
end
