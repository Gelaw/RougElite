
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
        if roomHighlight and roomHighlight ~= room then
          love.graphics.setColor(.2, .2, .2, .1)
          love.graphics.rectangle("fill", room.x-room.w/2, room.y-room.h/2, room.w, room.h)
        end
      end
    end, 3)

end



function levelSetup()
  baseRoomSize = 300
  safeLoadAndRun("baselevel.file")
  love.filesystem.setIdentity("levelEditor")
  -- safeLoadAndRun("level.file")
  calculate()
  generateWalls()
end


north = "north"
south = "south"
east = "east"
west = "west"


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

function calculate()
  for r, room in pairs(levelRooms) do
    room.outs = {north = {}, south = {}, east = {}, west = {}}
    room.doors = {north = {}, south = {}, east = {}, west = {}}
  end
  for r, room in pairs(levelRooms) do
    local entry = room.entry
    if entry then
      local previousRoom = levelRooms[entry[1]]
      local direction = directions[entry[2]]
      room.x = previousRoom.x + direction[1]*(.5*previousRoom.w + .5*room.w) + direction[2]*((entry[3]-.5)*previousRoom.w)
      room.y = previousRoom.y + direction[2]*(.5*previousRoom.h + .5*room.h) + direction[1]*((entry[3]-.5)*previousRoom.h)
      local out = previousRoom.outs[entry[2]]
      local ratio = direction[2]*(previousRoom.w/room.w)+direction[1]*(previousRoom.h/room.h)
      local sign = math.abs(ratio)/ratio
      local doorWidth = entry[5]
      if entry[2] == "north" or entry[2] == "west"  then
        table.insert(out, {1-entry[3] + (entry[4]- .5)/ratio})
        table.insert(room.doors[cardinalOpposite(entry[2])], {c=1-entry[4], w=doorWidth/math.abs(direction[2]*room.w+direction[1]*room.h)})
        table.insert(previousRoom.doors[entry[2]], {c=1-entry[3] + (entry[4]- .5)/ratio, w=doorWidth/math.abs(direction[2]*previousRoom.w+direction[1]*previousRoom.h)})
      else
        table.insert(out, {entry[3] + (entry[4]- .5)/ratio})
        table.insert(room.doors[cardinalOpposite(entry[2])], {c=entry[4], w=doorWidth/math.abs(direction[2]*room.w+direction[1]*room.h)})
        table.insert(previousRoom.doors[entry[2]], {c=entry[3] + (entry[4]- .5)/ratio, w=doorWidth/math.abs(direction[2]*previousRoom.w+direction[1]*previousRoom.h)})
      end
    end
  end
end

function generateWalls()
  walls = {}
  rooms = {}
  for r, room in pairs(levelRooms) do
    addRoom({x=room.x, y=room.y}, room.w, room.h, room.doors)
  end
end

function locatePoint(x, y)
  for r, room in pairs(levelRooms) do
    if room.x - room.w/2 < x and room.x + room.w/2 > x and room.y - room.h/2 < y and room.y + room.h/2 > y then
      return r
    end
  end
  return -1
end

function addRoom(p, w, h, doors)
  local doors = doors or {}
  addWall({x=p.x-w/2, y=p.y-h/2}, {x=p.x+w/2, y=p.y-h/2}, doors.north)
  addWall({x=p.x+w/2, y=p.y-h/2}, {x=p.x+w/2, y=p.y+h/2},  doors.east)
  addWall({x=p.x-w/2, y=p.y+h/2}, {x=p.x+w/2, y=p.y+h/2}, doors.south)
  addWall({x=p.x-w/2, y=p.y-h/2}, {x=p.x-w/2, y=p.y+h/2},  doors.west)
  local roomcolor = {math.random()*.2+.4, math.random()*.2+.4, math.random()*.2+.4, 1}
  room = {x=p.x, y=p.y, w=w, h=h,  roomcolor=roomcolor}
  table.insert(rooms, room)
  return room
end

basedoorWidth = 1

function addWall(p1, p2, doors)
    table.sort(doors, function(a, b) return a.c < b.c end)
  if doors then
    local p = p1
    for d, door in pairs(doors) do
      local doorA = {x= math.max(door.c-basedoorWidth*door.w/2,0), y=math.max(door.c-basedoorWidth*door.w/2,0)}
      local doorB = {x= math.min(door.c+basedoorWidth*door.w/2,1), y=math.min(door.c+basedoorWidth*door.w/2,1)}
      local pa = {x=p1.x + doorA.x*(p2.x - p1.x), y=p1.y + doorA.y*(p2.y - p1.y)}
      if p.x ~= pa.x or p.y ~= pa.y then
        table.insert(walls, {p, pa})
      end
      p = {x=p1.x + doorB.x*(p2.x - p1.x), y=p1.y + doorB.y*(p2.y - p1.y)}
    end
    if p.x ~= p2.x or p.y ~= p2.y then
      table.insert(walls, {p, p2})
    end
  else
    table.insert(walls, {p1, p2})
  end
end

function wallCollision(start, destination)
  for w, wall in pairs(walls) do
    if checkIntersect(wall[1], wall[2], start, destination) then return true, wall end
  end
  return false
end

function saveToFile()
  local text = "levelRooms = "
  text = text .. recursiveToString(levelRooms, "")
  print(text)
  success, message = love.filesystem.write( "level.file", text)
  print(success, message)
end

function recursiveToString(element, tabs)
  if type(element) ~= "table" then return element end
  local text = "{"
  local i = 0
  for p, property in pairs(element) do
    if type(p) == "number" then
      i = i + 1
      text = text.."\n" .. tabs.."\t" ..recursiveToString(property, tabs.."\t")..","
    elseif type(property) ~= "function" then
      i = i + 1
      text = text.."\n".. tabs.."\t" ..p .. "="..recursiveToString(property, tabs.."\t")..","
    end
  end
  if i > 0 then text = text .. "\n".. tabs end
  return text .. "}"
end
