
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
        love.graphics.rectangle("fill", room.p1.x, room.p1.y, room.p2.x-room.p1.x, room.p2.y-room.p1.y)
      end
    end, 3)

    --minimap
    addDrawFunction(function ()
      love.graphics.origin()
      love.graphics.scale(.1)
      love.graphics.translate(.5*width+100, .5*height+100)
      love.graphics.setColor(.4,.4,.4)
      love.graphics.rectangle("fill", -.5*width-100, -.5*height-100, width+200, height+200)
      for r, room in pairs(rooms) do
        love.graphics.setColor(room.roomcolor)
        love.graphics.rectangle("fill", room.p1.x, room.p1.y, room.p2.x-room.p1.x, room.p2.y-room.p1.y)
      end
      love.graphics.scale(10)
      love.graphics.setColor(0, 0, 0)
      for w, wall in pairs(walls) do
        love.graphics.line(wall[1].x/10, wall[1].y/10, wall[2].x/10, wall[2].y/10)
      end
      love.graphics.scale(.1)
      love.graphics.setColor(player.color)
      love.graphics.rectangle("fill", player.x, player.y, math.max(player.width, 30), math.max(player.height, 30))
    end,9)
end

function levelSetup()
  --wall Generation
  walls = {}
  rooms = {}
  p1 = p1 or {x=-width/2, y=-height/2}
  p2 = p2 or  {x=width/2, y=height/2}
  table.insert(walls, {p1, {x=p1.x, y=p2.y}})
  table.insert(walls, {p1, {x=p2.x, y=p1.y}})
  table.insert(walls, {{x=p1.x, y=p2.y}, p2})
  table.insert(walls, {p2, {x=p2.x, y=p1.y}})
  splitRoom(p1, p2)
end

function splitRoom(p1, p2, horizontal)


  if horizontal == nil then horizontal = math.random()<.5 end
  --Recursive breakpoint: room size
  if math.abs(p2.x - p1.x) > 500 and math.abs(p2.y - p1.y) > 500 then
    print(math.abs(p2.x - p1.x), math.abs(p2.y - p1.y))
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
    local roomcolor = {math.random()*.5+.1, math.random()*.5+.1, math.random()*.5+.1, .3}
    table.insert(rooms, {p1=p1, p2=p2, roomcolor=roomcolor})
  end
end
