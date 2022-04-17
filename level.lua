
function levelSetup()
  --wall Generation
  walls = {
  }
  p1 = p1 or {x=-width/2, y=-height/2}
  p2 = p2 or  {x=width/2, y=height/2}
  table.insert(walls, {p1, {x=p1.x, y=p2.y}})
  table.insert(walls, {p1, {x=p2.x, y=p1.y}})
  table.insert(walls, {{x=p1.x, y=p2.y}, p2})
  table.insert(walls, {p2, {x=p2.x, y=p1.y}})
  splitRoom(p1, p2)
  --wall Display
    -- TODO non urgent setup a image on load to increase display performances
  addDrawFunction( function ()
      for w, wall in pairs(walls) do
        love.graphics.setColor(0, 0, 0)
        love.graphics.line(wall[1].x, wall[1].y, wall[2].x, wall[2].y)
      end
    end
  )
end

function splitRoom(p1, p2, horizontal)
  --debug display
  local roomcolor = {math.random(), math.random(), math.random(), .2}
  addDrawFunction(function ()
    love.graphics.setColor(roomcolor)
    love.graphics.rectangle("fill", p1.x, p1.y, p2.x-p1.x, p2.y-p1.y)
  end, 3)

  if horizontal == nil then horizontal = math.random()<.5 end
  --Recursive breakpoint: room size
  if math.abs(p2.x - p1.x) > 500 and math.abs(p2.y - p1.y) > 500 then
    --midPoint : wall and door position
    local mp = {x=math.random(p1.x+15, p2.x-15), y = math.random(p1.y+15, p2.y+15)}
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
  end
end
