 -- --torch/candle (cosmetic only)
  -- table.insert(entities, {
  --   x = 0, y=0, radius=100,angle=0, color = {.7, .7, 0, 0.2}, shear = {x=0, y=0},
  --   polygon = { 0,0,  -2,-1,  -3,-3,  -2,-5,  0,-10,  2,-5,  3,-3,  2,-1,},
  --   draw=function (self)
  --     love.graphics.translate(self.x, self.y)
  --     love.graphics.setColor(.8, .8, .8, .8)
  --     love.graphics.rectangle("fill", -2, 0, 4, 5)
  --     love.graphics.setColor(.5, .5, .5, .5)
  --     love.graphics.rectangle("fill", -1, 0, 2, -2)
  --     love.graphics.shear(self.shear.x, self.shear.y)
  --     love.graphics.polygon("line",self.polygon)
  --     love.graphics.setColor(self.color)
  --     love.graphics.polygon("fill",self.polygon)
  --     love.graphics.push()
  --     love.graphics.setColor(self.color)
  --     love.graphics.translate(0, -3)
  --     love.graphics.scale(.5)
  --     love.graphics.polygon("fill", self.polygon)
  --     love.graphics.translate(0, 4)
  --     love.graphics.setColor({1, 0, .5, .3})
  --     love.graphics.polygon("fill", self.polygon)
  --     love.graphics.pop()
  --     love.graphics.rotate(self.angle)
  --     love.graphics.setColor(self.color)
  --     love.graphics.circle("fill", 0, 0, self.radius)
  --   end,
  --   update = function (self, dt)
  --     self.color[1], self.color[2], self.color[4] = self.color[1]+(math.random()-.5)*.01, self.color[2]+(math.random()-.5)*.01, self.color[4]+(math.random()-.5)*.01
  --     self.radius = self.radius +(math.random()-.49)*.1
  --     self.angle = self.angle + math.random()*.01
  --     self.shear = {x=self.shear.x+.01*(math.random()-.5), y=self.shear.y+.01*(math.random()-.5)}
  --   end
  -- })

  
  --minimap
  -- table.insert(uis, {draw=  function ()
  --     love.graphics.origin()
  --     love.graphics.translate(width-300, height-200)
  --     love.graphics.scale(.1)
  --     love.graphics.translate(.5*width+100, .5*height+100)
  --     love.graphics.setColor(.2,.2,.2)
  --     love.graphics.rectangle("fill", -.5*width-100, -.5*height-100, width+200, height+200)
  --     love.graphics.translate(-camera.x, -camera.y)
  --     for r, room in pairs(rooms) do
  --       love.graphics.setColor(room.roomcolor)
  --       love.graphics.rectangle("fill", room.x-room.w/2, room.y-room.h/2, room.w, room.h)
  --     end
  --     love.graphics.scale(10)
  --     love.graphics.setColor(0, 0, 0)
  --     for w, wall in pairs(walls) do
  --       love.graphics.line(wall[1].x/10, wall[1].y/10, wall[2].x/10, wall[2].y/10)
  --     end
  --     if player then
  --       love.graphics.scale(.1)
  --       love.graphics.setColor(player.color)
  --       love.graphics.rectangle("fill", player.x, player.y, math.max(player.w, 30), math.max(player.h, 30))
  --     end
  --     if ghost then
  --       love.graphics.scale(.1)
  --       love.graphics.setColor(ghost.color)
  --       love.graphics.rectangle("fill", ghost.x, ghost.y, math.max(ghost.w, 30), math.max(ghost.h, 30))
  --     end
  --   end})



        -- collectibles spawn
        -- addUpdateFunction(function (dt)
        --   if collectibles < 10 and math.random()>.99 then
        --     collectibles = collectibles + 1
        --     table.insert(entities, {
        --       shape = "rectangle",
        --       x = (math.random()-.5)*w, y = (math.random()-.5)*height,
        --       w = 5, h = 5, color = {.2, .8, .4},
        --       collide = function (self, collider)
        --         if collider == player then
        --           collectibles = collectibles - 1
        --           player.life = math.min(player.maxLife, player.life + 1)
        --           table.insert(particuleEffects, {
        --             x=self.x, y=self.y, color = {1, .2, .2}, nudge = 5, size = 3, timeLeft = 1.5,
        --             pluslygon = {-1,-1,  -1,-3,  1,-3,  1,-1,  3,-1,  3,1,  1,1,  1,3,  -1,3,  -1,1,  -3,1,  -3,-1},
        --             draw = function (self)
        --               love.graphics.translate(self.x, self.y)
        --               love.graphics.scale(.5)
        --               love.graphics.setColor(self.color)
        --               local t = love.timer.getTime() % 3600
        --               for i = 1, 4 do
        --                 love.graphics.push()
        --                 love.graphics.translate(math.cos(10*t+i*39)*5, math.cos(12*t+i*22)*5)
        --                 love.graphics.polygon("fill", self.pluslygon)
        --                 love.graphics.pop()
        --               end
        --             end
        --           })
        --           self.terminated = true
        --         end
        --       end
        --     })
        --   end
        -- end)