

draws = {}
for i = 1, 9 do
    draws[i] = {}
end

function addDrawFunction(draw, layer)
  table.insert(draws[layer], draw)
end

function drawParticuleEffect(pe)
  love.graphics.setColor(pe.color)
  for i = 1, 4 do
    local x, y = pe.x+math.random(-pe.nudge/2,pe.nudge/2), pe.y+math.random(-pe.nudge/2,pe.nudge/2)
    love.graphics.polygon("fill", {x+pe.size, y, x, y+pe.size, x-pe.size, y, x, y-pe.size})
  end
end

function basicEntityDraw(entity)
  if entity.color then
    love.graphics.setColor(entity.color)
  else
    love.graphics.setColor({0.8,0.3,1})
  end
  love.graphics.translate(entity.x, entity.y)
  if entity.angle then love.graphics.rotate(entity.angle) end
  if entity.shape == "rectangle" then
      love.graphics.rectangle("fill", -entity.width/2, -entity.height/2, entity.width, entity.height)
  elseif entity.shape == "circle" then
      love.graphics.circle("fill", 0, 0, entity.radius)
  end
end

function love.draw()
  love.graphics.translate(width/2, height/2)
  camera:apply()
  for l, layer in pairs(draws) do
    for d, draw in pairs(layer) do
      if type(draw) ~= "function" then
        print(draw, " is not a function!")
        love.event.quit()
      end
      love.graphics.push()
      draw()
      love.graphics.pop()
    end
  end
end

updates = {}

function addUpdateFunction(update)
  table.insert(updates, update)
end

function love.update(dt)
  if gameover then return end
  for u, update in pairs(updates) do
    if type(update) ~= "function" then
      print(update, " is not a function!")
      love.event.quit()
    end
    update(dt)
  end
  camera:update(dt)
end


bindings = {}

function addBind(key, action)
  bindings[action] = key
end

function getBindOf(action)
  return bindings[action]
end

camera = {x = 0, y = 0, scale = 1, angle = 0, mode = nil,
  shaker = { steps = {}, n = 1, stepTimer = 0, shakeTimer = 0},
  apply = function (self)
    local shaker = self.shaker
    if shaker.steps[shaker.n] then
      local c = shaker.stepTimer - shaker.steps[shaker.n].time
      love.graphics.translate(c*shaker.steps[shaker.n].dx, c*shaker.steps[shaker.n].dy)
    end
    love.graphics.rotate(camera.angle)
    love.graphics.scale(camera.scale, camera.scale)
    love.graphics.translate( - camera.x, - camera.y)
  end,
  boxSize = 100,
  update = function (self, dt)
    local shaker = self.shaker
    shaker.shakeTimer = shaker.shakeTimer - dt
    if shaker.shakeTimer <= 0 then
      shaker.steps = {}
      shaker.n = 1
      shaker.stepTimer = 0
    elseif shaker.steps[shaker.n] then
      shaker.stepTimer = shaker.stepTimer + dt
      if shaker.stepTimer >= shaker.steps[shaker.n].time then
        shaker.stepTimer = shaker.stepTimer - shaker.steps[shaker.n].time
        shaker.n = shaker.n%#shaker.steps + 1
      end
    end
    if self.mode == nil then return end
    if self.mode[1] == "follow" then
      if self.mode[2].x and self.mode[2].y then
        self.x, self.y = self.mode[2].x, self.mode[2].y
      end
    end
    if self.mode[1] == "moveTo" then
      if self.mode[2].x and self.mode[2].y then
        self.x, self.y = self.mode[2].x, self.mode[2].y
        self.mode[1] = {}
      end
    end
  end
}



function cameraShake(intensity, duration, pattern)
  if not pattern then
    camera.shaker.shakeTimer = duration
    for i = 1, 10 do
      camera.shaker.steps[i] = { dx = math.random(-1,1)*intensity/2, dy = math.random(-1, 1)*intensity/2, time = 0.1}
    end
  else
    --Decrit des patterns gauche a droite, croise l ecran etc a modif en fonction
    if pattern == "cross" then

    end
  end
end



function init()
  love.window.setFullscreen(true)
  width  = love.graphics.getWidth()
  height = love.graphics.getHeight()
  love.graphics.setFont(love.graphics.newFont(11))
  love.graphics.setBackgroundColor(.4, .4, .4)
  entities = {}
  addDrawFunction(
    function ()
      for e, entity in pairs(entities) do
        if math.abs(entity.x  - camera.x) <= .75*(width)/camera.scale
        and math.abs(entity.y - camera.y) <= .75*(height)/camera.scale then
          love.graphics.push()
          if entity.draw then
            entity:draw()
          else
            basicEntityDraw(entity)
          end
          love.graphics.pop()
        end
      end
    end, 5
  )

  addUpdateFunction(
    function (dt)
      for e = #entities, 1, -1 do
        local entity = entities[e]
        if entity.update then
          entity:update(dt)
        end
        if entity.collide then
          local m1 = 5
          if entity.radius then
            m1 = entity.radius
          elseif entity.width and entity.height then
            m1 = math.pow(entity.width*entity.width+entity.height*entity.height, .5)
          end
          for e2 = e + 1, #entities do
            local entity2 = entities[e2]
            if entity2.collide then
              local m2 = 5
              if entity2.radius then
                m2 = entity2.radius
              elseif entity2.width and entity2.height then
                m2 = math.pow(entity2.widthentity2.width+entity2.heightentity2.height, .5)
              end
              if math.dist(entity.x, entity.y, entity2.x, entity2.y)<m1+m2 then
                entity2:collide(entity)
                entity:collide(entity2)
              end
            end
          end
        end
        if entity.killmenow == true then
          table.remove(entities, e)
        end
      end
    end
  )

  particuleEffects = {}

  addDrawFunction(
    function ()
      for pe, particuleEffect in pairs(particuleEffects) do
        if math.abs(particuleEffect.x  - camera.x) <= .75*(width)/camera.scale
        and math.abs(particuleEffect.y - camera.y) <= .75*(height)/camera.scale then
          love.graphics.push()
          if particuleEffect.draw then
            particuleEffect:draw()
          else
            drawParticuleEffect(entity)
          end
          love.graphics.pop()
        end
      end
    end, 6
  )
  addUpdateFunction(
    function (dt)
      for pe = #particuleEffects, 1, -1 do
        particuleEffect = particuleEffects[pe]
        particuleEffect.timeLeft = particuleEffect.timeLeft - dt
        if particuleEffect.timeLeft <= 0 then
          table.remove(particuleEffects, pe)
        end
      end
    end
  )
end



function love.load(arg)
  init()
  test()
end



-- Extra math functions from https://love2d.org/wiki/General_math

-- Averages an arbitrary number of angles (in radians).
function math.averageAngles(...)
	local x,y = 0,0
	for i=1,select('#',...) do local a= select(i,...) x, y = x+math.cos(a), y+math.sin(a) end
	return math.atan2(y, x)
end


-- Returns the distance between two points.
function math.dist(x1,y1, x2,y2) return ((x2-x1)^2+(y2-y1)^2)^0.5 end
-- -- Distance between two 3D points:
-- function math.dist(x1,y1,z1, x2,y2,z2) return ((x2-x1)^2+(y2-y1)^2+(z2-z1)^2)^0.5 end


-- Returns the angle between two points.
function math.angle(x1,y1, x2,y2) return math.atan2(y2-y1, x2-x1) end


-- Returns the closest multiple of 'size' (defaulting to 10).
function math.multiple(n, size) size = size or 10 return math.round(n/size)*size end


-- Clamps a number to within a certain range.
function math.clamp(low, n, high) return math.min(math.max(low, n), high) end


-- Linear interpolation between two numbers.
function lerp(a,b,t) return (1-t)*a + t*b end
function lerp2(a,b,t) return a+(b-a)*t end

-- Cosine interpolation between two numbers.
function cerp(a,b,t) local f=(1-math.cos(t*math.pi))*.5 return a*(1-f)+b*f end


-- Normalize two numbers.
function math.normalize(x,y) local l=(x*x+y*y)^.5 if l==0 then return 0,0,0 else return x/l,y/l,l end end


-- Returns 'n' rounded to the nearest 'deci'th (defaulting whole numbers).
function math.round(n, deci) deci = 10^(deci or 0) return math.floor(n*deci+.5)/deci end


-- Randomly returns either -1 or 1.
function math.rsign() return love.math.random(2) == 2 and 1 or -1 end


-- Returns 1 if number is positive, -1 if it's negative, or 0 if it's 0.
function math.sign(n) return n>0 and 1 or n<0 and -1 or 0 end


-- Gives a precise random decimal number given a minimum and maximum
function math.prandom(min, max) return love.math.random() * (max - min) + min end


-- Checks if two line segments intersect. Line segments are given in form of ({x,y},{x,y}, {x,y},{x,y}).
function checkIntersect(l1p1, l1p2, l2p1, l2p2)
	local function checkDir(pt1, pt2, pt3) return math.sign(((pt2.x-pt1.x)*(pt3.y-pt1.y)) - ((pt3.x-pt1.x)*(pt2.y-pt1.y))) end
	return (checkDir(l1p1,l1p2,l2p1) ~= checkDir(l1p1,l1p2,l2p2)) and (checkDir(l2p1,l2p2,l1p1) ~= checkDir(l2p1,l2p2,l1p2))
end

-- Checks if two lines intersect (or line segments if seg is true)
-- Lines are given as four numbers (two coordinates)
function findIntersect(l1p1x,l1p1y, l1p2x,l1p2y, l2p1x,l2p1y, l2p2x,l2p2y, seg1, seg2)
	local a1,b1,a2,b2 = l1p2y-l1p1y, l1p1x-l1p2x, l2p2y-l2p1y, l2p1x-l2p2x
	local c1,c2 = a1*l1p1x+b1*l1p1y, a2*l2p1x+b2*l2p1y
	local det,x,y = a1*b2 - a2*b1
	if det==0 then return false, "The lines are parallel." end
	x,y = (b2*c1-b1*c2)/det, (a1*c2-a2*c1)/det
	if seg1 or seg2 then
		local min,max = math.min, math.max
		if seg1 and not (min(l1p1x,l1p2x) <= x and x <= max(l1p1x,l1p2x) and min(l1p1y,l1p2y) <= y and y <= max(l1p1y,l1p2y)) or
		   seg2 and not (min(l2p1x,l2p2x) <= x and x <= max(l2p1x,l2p2x) and min(l2p1y,l2p2y) <= y and y <= max(l2p1y,l2p2y)) then
			return false, "The lines don't intersect."
		end
	end
	return x,y
end
