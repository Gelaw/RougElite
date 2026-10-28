--------------------------------------------------------------------
-- core/base.lua : engine core — registries, camera, entity manager,
-- math and geometry helpers. NO love.* references: rendering goes
-- through the injected `G` interface (adapters/render.lua), time and
-- randomness through `getTimestamp`/`random` (adapters/love_adapter).
--------------------------------------------------------------------

--------------------------------------------------------------------
-- Config
--------------------------------------------------------------------
joystickButtons = {"A","B","X","Y","LB","RB", "select", "start", "LJ", "RJ"}

--------------------------------------------------------------------
-- Adapter injection points
-- These are replaced by the LÖVE adapter at startup (and by test
-- doubles in spec/). Defaults are no-op safe.
--------------------------------------------------------------------

-- Rendering interface (G = graphics). Must expose the love.graphics
-- functions used by draw callbacks: push/pop/translate/rotate/scale/
-- setColor/rectangle/circle/line/polygon/arc/print/origin/...
G = G or setmetatable({}, {__index = function() return function() end end})

-- Wall clock (seconds) for cooldowns, shake, HUD timers.
getTimestamp = getTimestamp or function() return 0 end

-- RNG entry points (love.math.random equivalents).
random = random or function(a, b)
  if a == nil then return math.random() end
  if b == nil then return math.random(a) end
  return math.random(a, b)
end

-- Level file IO (love.filesystem backed; adapters override).
loadLevelFile = loadLevelFile or function(name)
  return loadfile and loadfile(name) or nil, "loadLevelFile unavailable"
end
writeLevelFile = writeLevelFile or function(text)
  return false, "writeLevelFile unavailable"
end

--------------------------------------------------------------------
-- Table helpers
--------------------------------------------------------------------

-- Copies every entry of 'parameters' into 'table' and returns it.
function applyParams(table, parameters)
  for p, parameter in pairs(parameters) do
    table[p] = parameter
  end
  return table
end

--------------------------------------------------------------------
-- Draw layers
--------------------------------------------------------------------
draws = {}
for i = 1, 9 do
  draws[i] = {}
end

-- Registers a draw callback on a layer (1 = bottom, 9 = top, default 5).
function addDrawFunction(draw, layer)
  layer = layer or 5
  table.insert(draws[layer], draw)
end

--------------------------------------------------------------------
-- Update loop
--------------------------------------------------------------------
updates = {}

function addUpdateFunction(update)
  table.insert(updates, update)
end

--------------------------------------------------------------------
-- Input bindings
--------------------------------------------------------------------
bindings = {}

function addBind(key, action)
  bindings[action] = key
end

function getBindOf(action)
  return bindings[action]
end

--------------------------------------------------------------------
-- Camera
--------------------------------------------------------------------
camera = {
  x = 0, y = 0, scale = 1, angle = 0, mode = nil,
  shaker = { steps = {}, n = 1, stepTimer = 0, shakeTimer = 0},
  boxSize = 100,
  apply = function (self)
    local shaker = self.shaker
    if shaker.steps[shaker.n] then
      local c = shaker.stepTimer - shaker.steps[shaker.n].time
      G.translate(c*shaker.steps[shaker.n].dx, c*shaker.steps[shaker.n].dy)
    end
    G.rotate(self.angle)
    G.scale(self.scale, self.scale)
    G.translate( - self.x, - self.y)
  end,
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
        self.mode = nil
      end
    end
  end
}

function cameraShake(intensity, duration, pattern)
  if not pattern then
    camera.shaker.shakeTimer = duration
    for i = 1, 10 do
      camera.shaker.steps[i] = { dx = random(-1,1)*intensity/2, dy = random(-1, 1)*intensity/2, time = 0.1}
    end
  else
    --Named shake patterns (left-right, crossing the screen, etc) to be implemented
    if pattern == "cross" then

    end
  end
end

--------------------------------------------------------------------
-- Default draws
--------------------------------------------------------------------
function basicParticuleEffectDraw(pe)
  G.setColor(pe.color)
  G.translate(pe.x, pe.y)
  local t = getTimestamp()
  for i = 1, 8 do
    G.push()
    G.translate(math.cos(60*t+10*i)*pe.nudge/2, math.sin(40*t+60*i)*pe.nudge/2)
    G.rotate(math.sin(t + 69*i))
    G.polygon("fill", {pe.size, 0, 0, pe.size, -pe.size, 0, 0, -pe.size})
    G.pop()
  end
end

function basicEntityDraw(entity)
  if entity.color then
    G.setColor(entity.color)
  else
    G.setColor({0.8,0.3,1})
  end
  G.translate(entity.x, entity.y)
  if entity.angle then G.rotate(entity.angle) end
  if entity.shape == "rectangle" then
    local w, h = entity.w or entity.width, entity.h or entity.height
    G.rectangle("fill", -w/2, -h/2, w, h)
  elseif entity.shape == "circle" then
    G.circle("fill", 0, 0, entity.radius)
  end
end

--------------------------------------------------------------------
-- Entity management
--------------------------------------------------------------------

-- Returns the list of points that form the hitbox of the entity
-- in global coordinates (requires w/width and h/height).
function getPointsGlobalCoor(entity)
  local cos, sin = math.cos, math.sin
  local x, y, a = entity.x, entity.y, -(entity.angle or 0)
  local w, h = (entity.w or entity.width), (entity.h or entity.height)
  local points = {}
  if w and h then
    local corners = {{.5, .5},{.5, -.5}, {-.5, -.5}, {-.5, .5}}
    for i = 1, 4 do
      local c = corners[i]
      table.insert(points, {x=x+c[1]*w*cos(a)+c[2]*h*sin(a), y=y-c[1]*w*sin(a)+c[2]*h*cos(a)})
    end
  end
  return points
end

local function addEntitiesLayer()
  entities = {}
  addDrawFunction(function ()
    for e, entity in pairs(entities) do
      if math.abs(entity.x  - camera.x) <= .75*(width)/camera.scale
      and math.abs(entity.y - camera.y) <= .75*(height)/camera.scale then
        G.push()
        if entity.draw then
          entity:draw()
        else
          basicEntityDraw(entity)
        end
        G.pop()
      end
    end
  end, 5)
end

local function addEntitiesCollisionUpdate()
  addUpdateFunction(function (dt)
    for e = #entities, 1, -1 do
      local entity = entities[e]
      if entity.update then
        entity:update(dt)
      end
      --Collision check: Warning: collisions are not detected when one entity is within another
      --  for each pair of entities, check if the segments of the hitboxes intersect
      if entity.collide then
        local points1 = getPointsGlobalCoor(entity)
        for e2 = e + 1, #entities do
          local entity2 = entities[e2]
          if entity2.collide then
            local points2 = getPointsGlobalCoor(entity2)
            local collision = false
            for p1 = 1, #points1 do
              for p2 = 1, #points2 do
                if checkIntersect(points1[p1], points1[p1%#points1+1], points2[p2], points2[p2%#points2+1]) then
                  collision=true
                end
              end
            end
            if collision then
              entity2:collide(entity)
              --check in case the first collide caused the entity to lose its collide function
              if entity.collide then
                entity:collide(entity2)
              end
            end
          end
        end
      end
      if entity.terminated == true then
        table.remove(entities, e)
      end
    end
  end)
end

local function addParticuleEffectsLayer()
  particuleEffects = {}

  addDrawFunction(function ()
    for pe, particuleEffect in pairs(particuleEffects) do
      if math.abs(particuleEffect.x  - camera.x) <= .75*(width)/camera.scale
      and math.abs(particuleEffect.y - camera.y) <= .75*(height)/camera.scale then
        G.push()
        if particuleEffect.draw then
          particuleEffect:draw()
        else
          basicParticuleEffectDraw(particuleEffect)
        end
        G.pop()
      end
    end
  end, 6)

  addUpdateFunction(function (dt)
    for pe = #particuleEffects, 1, -1 do
      local particuleEffect = particuleEffects[pe]
      particuleEffect.timeLeft = particuleEffect.timeLeft - dt
      if particuleEffect.timeLeft <= 0 then
        table.remove(particuleEffects, pe)
      end
    end
  end)
end

--------------------------------------------------------------------
-- Engine init
--------------------------------------------------------------------
function init()
  width  = width or 800
  height = height or 600
  entities = nil -- recreated by addEntitiesLayer
  addEntitiesLayer()
  addEntitiesCollisionUpdate()
  addParticuleEffectsLayer()
end

-- Loads and runs a Lua file without crashing the game on error
-- (used for editableScript.lua and level files). The actual loading
-- goes through the adapter-provided loadLevelFile; tests inject fakes.
function safeLoadAndRun(name)
  local ok, chunk, result
  ok, chunk = pcall(loadLevelFile, name)
  if not ok then
    -- print('The following error happened: ' .. tostring(chunk))
  else
    ok, result = pcall(chunk)
    if not ok then
      -- print('The following error happened: ' .. tostring(result))
    end
  end
end

--------------------------------------------------------------------
-- Extra math functions (from https://love2d.org/wiki/General_math)
--------------------------------------------------------------------

-- Averages an arbitrary number of angles (in radians).
function math.averageAngles(...)
  local x,y = 0,0
  for i=1,select('#',...) do local a= select(i,...) x, y = x+math.cos(a), y+math.sin(a) end
  return math.atan2 and math.atan2(y, x) or math.atan(y, x)
end

-- Returns the distance between two points.
function math.dist(x1,y1, x2,y2) return ((x2-x1)^2+(y2-y1)^2)^0.5 end

-- Returns the shortest absolute difference between two angles.
function math.angleDiff(a1, a2)
  return  math.pi - math.abs(math.abs(a1 - a2) - math.pi);
end

-- Returns the angle between two points.
function math.angle(x1,y1, x2,y2)
  local dx, dy = x2-x1, y2-y1
  if math.atan2 then return math.atan2(dy, dx) end
  return math.atan(dy, dx)
end

-- Returns the closest multiple of 'size' (defaulting to 10).
function math.multiple(n, size) size = size or 10 return math.round(n/size)*size end

-- Clamps a number to within a certain range.
function math.clamp(low, n, high) return math.min(math.max(low, n), high) end

-- Linear interpolation between two numbers.
function lerp(a,b,t) return (1-t)*a + t*b end
function lerp2(a,b,t) return a+(b-a)*t end

-- Cosine interpolation between two numbers.
function cerp(a,b,t) local f=(1-math.cos(t*math.pi))*.5 return a*(1-f)+b*f end

-- Normalizes two numbers. Returns x, y and the initial length.
function math.normalize(x,y) local l=(x*x+y*y)^.5 if l==0 then return 0,0,0 else return x/l,y/l,l end end

-- Returns 'n' rounded to the nearest 'deci'th (defaulting whole numbers).
function math.round(n, deci) deci = 10^(deci or 0) return math.floor(n*deci+.5)/deci end

-- Randomly returns either -1 or 1.
function math.rsign() return random(2) == 2 and 1 or -1 end

-- Gives a precise random decimal number given a minimum and maximum.
function math.prandom(min, max) return random() * (max - min) + min end

-- Returns 1 if number is positive, -1 if it's negative, or 0 if it's 0.
function math.sign(n) return n>0 and 1 or n<0 and -1 or 0 end

--------------------------------------------------------------------
-- Geometry
--------------------------------------------------------------------

-- Checks if two line segments intersect. Segments are given as ({x,y},{x,y}, {x,y},{x,y}).
function checkIntersect(l1p1, l1p2, l2p1, l2p2)
  local function checkDir(pt1, pt2, pt3) return math.sign(((pt2.x-pt1.x)*(pt3.y-pt1.y)) - ((pt3.x-pt1.x)*(pt2.y-pt1.y))) end
  return (checkDir(l1p1,l1p2,l2p1) ~= checkDir(l1p1,l1p2,l2p2)) and (checkDir(l2p1,l2p2,l1p1) ~= checkDir(l2p1,l2p2,l1p2))
end

-- Checks if two lines intersect (or line segments if seg1/seg2 is true).
-- Lines are given as four numbers (two coordinates).
function findIntersect(l1p1x,l1p1y, l1p2x,l1p2y, l2p1x,l2p1y, l2p2x,l2p2y, seg1, seg2)
  local a1,b1,a2,b2 = l1p2y-l1p1y, l1p1x-l1p2x, l2p2y-l2p1y, l2p1x-l2p2x
  local c1,c2 = a1*l1p1x+b1*l1p1y, a2*l2p1x+b2*l2p1y
  local det = a1*b2 - a2*b1
  if det==0 then return false, "The lines are parallel." end
  local x,y = (b2*c1-b1*c2)/det, (a1*c2-a2*c1)/det
  if seg1 or seg2 then
    local min,max = math.min, math.max
    if seg1 and not (min(l1p1x,l1p2x) <= x and x <= max(l1p1x,l1p2x) and min(l1p1y,l1p1y) <= y and y <= max(l1p1y,l1p1y)) or
    seg2 and not (min(l2p1x,l2p2x) <= x and x <= max(l2p1x,l2p2x) and min(l2p1y,l2p2y) <= y and y <= max(l2p1y,l2p2y)) then
      return false, "The lines don't intersect."
    end
  end
  return x,y
end

-- Returns the closest point on line (x1,y1)-(x2,y2) to point (a,b).
function get_closest_point(x1,y1, x2,y2, a,b)
  if x1==x2 then return {x1,b} end
  if y1==y2 then return {a,y1} end
  local m1 = (y2-y1)/(x2-x1)
  local m2 = -1/m1
  local x = (m1*x1-m2*a+b-y1) / (m1-m2)
  local y = m2*(x-a)+b
  return {x,y}
end
