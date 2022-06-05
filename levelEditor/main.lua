require "base"
require "level"

function test()
  levelSetup()
  levelDisplayInit()
  key = love.keyboard.isDown
  camera.scale = .5
  love.filesystem.setIdentity("levelEditor")
  safeLoadAndRun("level.file")
  recurPrint(levelRooms)
  calculate()

  addUpdateFunction(calculate)
end
function recurPrint(table, tab)
  tab = tab or ""
  for e, element in pairs(table) do
    if type(element) == "function" then
      print(tab..e .."()")
    elseif type(element) == "table" then
      print(tab..e)
      recurPrint(element, tab.."\t")
    else
      print(tab..e, ":", element)
    end
  end
end

function love.keypressed(key, scancode, isrepeat)
  if key == "escape" then
    love.event.quit()
  end
  if key == "g" then
    generateWalls()
  end
  if key == "delete" or key == "backspace"  then
    if highlightedRoom then
      for r, room in pairs(levelRooms) do
        if room.entry and room.entry[1] == rIndex then
          room.entry = nil
        end
      end
      table.remove(levelRooms, rIndex)
      calculate()
    end
  end
  if key == "i" then
    m = safeLoadAndRun("level.file")
    print(m)
  end
  if key == "s" and love.keyboard.isDown("lctrl") then
    m = saveToFile(levelRooms)
    print(m)
  end
end

function love.mousemoved(x, y, dx, dy)
  if grab then
    grab.move(x, y, dx, dy)
    highlightRoom(highlightedRoom, rIndex)
    return
  end
  highlightedRoom = nil
  rIndex = nil
  x, y = (x  - .5*width)/camera.scale + camera.x, (y  - .5*height)/camera.scale+ camera.y
  for r, room in pairs(levelRooms) do
    if highlightRoom ~= room and  x > room.x-.5*room.w and  x < room.x+.5*room.w and  y > room.y-.5*room.h and  y < room.y+.5*room.h then
      highlightRoom(room, r)
    end
  end
  if not highlightedRoom and love.mouse.isDown(1) then
    camera.x, camera.y = camera.x - dx/camera.scale, camera.y - dy/camera.scale
  end
end

function love.mousepressed(x, y, button, isTouch)
  x, y = (x  - .5*width)/camera.scale + camera.x, (y  - .5*height)/camera.scale + camera.y
  if highlightedRoom then
    for b, button in pairs(buttons) do
      if button.x and button.y then
        if x>button.x-15 and x<button.x+15 and y>button.y-15 and y<button.y+15 then
          grab = button
          if button.press then button.press(x, y) end
          return
        end
      end
    end
  end
  if click and love.timer.getTime() - click[3] < .5 and math.abs(x-click[1]) < 15 and math.abs(y-click[2]) < 15 then
    table.insert(levelRooms, {x= x, y= y, w=  baseRoomSize, h= baseRoomSize})
  end
  click = {x, y, love.timer.getTime()}
end

function love.mousereleased(x, y, button, isTouch)
  if grab and grab.release then grab.release(x, y, button, isTouch) end
  grab = nil
end

function love.wheelmoved(x, y)
  if love.keyboard.isDown("lctrl") then
    camera.scale = math.max(.1, camera.scale + .1*y)
  end
end

snapThreshold = 15
minRoomSize = 50

function resizeRoom(x, y, dx, dy)
  local coef = highlightedRoom.entry and 1 or 2
  highlightedRoom.w, highlightedRoom.h = math.max(minRoomSize, highlightedRoom.w + coef*(dx*grab.dx)/camera.scale), math.max(minRoomSize, highlightedRoom.h + coef*(dy*grab.dy)/camera.scale)
end

cornerArrow = {15, 15, -15, 15, 15, -15}

--highlightedRoom buttons (for moving(or resizing) room or their door)
buttons = {
  --move button
  {
    press = function (x, y) highlightedRoom.entry= nil end,
    move = function (x, y, dx, dy)
      highlightedRoom.x, highlightedRoom.y = highlightedRoom.x + dx/camera.scale, highlightedRoom.y + dy/camera.scale
    end,
    release = function ()
      for r, room in pairs(levelRooms) do
        if room ~= highlightedRoom and (not room.entry or room.entry[1] ~= rIndex) then
          if math.abs((room.x-.5*room.w) - (highlightedRoom.x + .5*highlightedRoom.w)) < snapThreshold and math.abs(room.y - highlightedRoom.y) < .5*(room.h + highlightedRoom.h) then
            highlightedRoom.entry = {r, "west", .5, .5, 30}
          end
          if math.abs((room.x+.5*room.w) - (highlightedRoom.x - .5*highlightedRoom.w)) < snapThreshold and math.abs(room.y - highlightedRoom.y) < .5*(room.h + highlightedRoom.h) then
            highlightedRoom.entry = {r, "east", .5, .5, 30}
          end
          if math.abs((room.y+.5*room.h) - (highlightedRoom.y - .5*highlightedRoom.h)) < snapThreshold and math.abs(room.x - highlightedRoom.x) < .5*(room.w + highlightedRoom.w) then
            highlightedRoom.entry = {r, "south", .5, .5, 30}
          end
          if math.abs((room.y-.5*room.h) - (highlightedRoom.y + .5*highlightedRoom.h)) < snapThreshold and math.abs(room.x - highlightedRoom.x) < .5*(room.w + highlightedRoom.w) then
            highlightedRoom.entry = {r, "north", .5, .5, 30}
          end
        end
      end
    end,
    draw = function (self)
      if highlightedRoom then
        love.graphics.push()
        love.graphics.translate(self.x, self.y)
        love.graphics.rectangle("fill", -15, -15, 30, 30)
        love.graphics.pop()
      end
    end,
    u = function (self)
      self.x = highlightedRoom.x
      self.y = highlightedRoom.y
    end
  },
  --resize Buttons
  {dx= 1, dy= 1, move = resizeRoom},
  {dx=-1, dy= 1, move = resizeRoom},
  {dx= 1, dy=-1, move = resizeRoom},
  {dx=-1, dy=-1, move = resizeRoom},
  --door buttons
  {
    u = function (self)
      if highlightedRoom.entry then
        highlightedRoom.entry[3] = highlightedRoom.entry[3] or .5
        local entryRoom = levelRooms[highlightedRoom.entry[1]]
        local direction = directions[highlightedRoom.entry[2]]
        self.x = highlightedRoom.x - direction[1] * (.5*highlightedRoom.w-80) + direction[2]*(highlightedRoom.entry[3]-.5)*highlightedRoom.w
        self.y = highlightedRoom.y - direction[2] * (.5*highlightedRoom.h-80) + direction[1]*(highlightedRoom.entry[3]-.5)*highlightedRoom.h
      else
        self.x, self.y = nil, nil
      end
    end,
    move = function (x, y, dx, dy)
      local direction = directions[highlightedRoom.entry[2]]
      highlightedRoom.entry[3] = math.max(0, math.min(1, highlightedRoom.entry[3] + 0.001*(dx*direction[2] + dy*direction[1])))
    end
  },
  {
    u = function (self)
      if highlightedRoom.entry then
        local entryRoom = levelRooms[highlightedRoom.entry[1]]
        local direction = directions[highlightedRoom.entry[2]]
        self.x = highlightedRoom.x - direction[1] * (.5*highlightedRoom.w-30) + direction[2]*(highlightedRoom.entry[4]-.5)*highlightedRoom.w
        self.y = highlightedRoom.y - direction[2] * (.5*highlightedRoom.h-30) + direction[1]*(highlightedRoom.entry[4]-.5)*highlightedRoom.h
      else
        self.x, self.y = nil, nil
      end
    end,
    move = function (x, y, dx, dy)
      local direction = directions[highlightedRoom.entry[2]]
      highlightedRoom.entry[4] = math.max(0, math.min(1, highlightedRoom.entry[4] + 0.001*(dx*direction[2] + dy*direction[1])))
    end
  }
}

function highlightRoom(room, index)
  highlightedRoom = room
  rIndex = index
  for i = 1, #buttons do
    if buttons[i].dx and buttons[i].dy then
      buttons[i].x = highlightedRoom.x + buttons[i].dx*.5*highlightedRoom.w - buttons[i].dx*15
      buttons[i].y = highlightedRoom.y + buttons[i].dy*.5*highlightedRoom.h - buttons[i].dy*15
    end
    if buttons[i].u then buttons[i]:u() end
  end
end

addDrawFunction(function ()
  if highlightedRoom then
    love.graphics.setColor(1, 1, 1, .8)
    for i = 1, #buttons do
      if buttons[i].draw then
        buttons[i]:draw()
      elseif buttons[i].dx and buttons[i].dy  then
        love.graphics.push()
        love.graphics.translate(buttons[i].x, buttons[i].y)
        love.graphics.rotate(math.angle(0, 0, buttons[i].dx, buttons[i].dy)-math.rad(45))
        love.graphics.polygon("fill", cornerArrow)
        love.graphics.pop()
      elseif buttons[i].x  and buttons[i].y then
        love.graphics.push()
        love.graphics.translate(buttons[i].x, buttons[i].y)
        love.graphics.rectangle("fill", -15, -15, 30, 30)
        love.graphics.pop()
      end
    end
  end
end, 9)

addDrawFunction(function ()
  math.randomseed(5)
  for r, room in pairs(levelRooms) do
    love.graphics.setColor(0, 0, 0, .2)
    love.graphics.rectangle("line", room.x-.5*room.w, room.y-.5*room.h, room.w, room.h)
    love.graphics.setColor(math.random(), math.random(), math.random(), .2)
    love.graphics.rectangle("fill", room.x-.5*room.w, room.y-.5*room.h, room.w, room.h)
    if roomHighlight and roomHighlight~=room then
      love.graphics.setColor(0, 0, 0, .2)
      love.graphics.rectangle("fill", room.x-.5*room.w, room.y-.5*room.h, room.w, room.h)
    end
  end
end, 5)
