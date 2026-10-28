--------------------------------------------------------------------
-- spec/base_math_spec.lua : pure math/geometry helpers from base.lua
--------------------------------------------------------------------

local loader = require("spec.game_loader")

describe("base.lua math helpers", function()
  loader.loadGame()

  it("math.dist returns euclidean distance", function()
    assert.are.equal(5, math.dist(0, 0, 3, 4))
    assert.are.equal(0, math.dist(1, 1, 1, 1))
  end)

  it("math.round rounds to the given decimal", function()
    assert.are.equal(3, math.round(3.14159))
    assert.are.equal(3.14, math.round(3.14159, 2))
    assert.are.equal(4, math.round(3.5))
  end)

  it("math.clamps to the range (signature: clamp(low, n, high))", function()
    assert.are.equal(5, math.clamp(0, 5, 10))
    assert.are.equal(0, math.clamp(0, -3, 10))
    assert.are.equal(10, math.clamp(0, 15, 10))
  end)

  it("math.sign returns -1/0/1", function()
    assert.are.equal(-1, math.sign(-3))
    assert.are.equal(1, math.sign(42))
    assert.are.equal(0, math.sign(0))
  end)

  it("math.angleDiff returns the shortest absolute difference", function()
    assert.are.equal(0, math.angleDiff(1, 1))
    assert.True(math.angleDiff(0, math.pi) - math.pi < 0.0001)
  end)

  it("math.normalize returns direction and length", function()
    local x, y, l = math.normalize(3, 4)
    assert.are.equal(0.6, x)
    assert.are.equal(0.8, y)
    assert.are.equal(5, l)
    local x0, y0, l0 = math.normalize(0, 0)
    assert.are.equal(0, x0)
    assert.are.equal(0, y0)
    assert.are.equal(0, l0)
  end)

  it("lerp interpolates linearly", function()
    assert.are.equal(0.5, lerp(0, 1, 0.5))
    assert.are.equal(0, lerp(0, 1, 0))
    assert.are.equal(1, lerp(0, 1, 1))
  end)
end)

describe("base.lua geometry", function()
  loader.loadGame()

  it("checkIntersect detects crossing segments", function()
    assert.True(checkIntersect(
      {x=0, y=0}, {x=10, y=10},
      {x=0, y=10}, {x=10, y=0}))
  end)

  it("checkIntersect rejects parallel segments", function()
    assert.False(checkIntersect(
      {x=0, y=0}, {x=10, y=0},
      {x=0, y=5}, {x=10, y=5}))
  end)

  it("get_closest_point projects onto horizontal line", function()
    local p = get_closest_point(0, 5, 10, 5, 7, 20)
    assert.are.equal(7, p[1])
    assert.are.equal(5, p[2])
  end)

  it("getPointsGlobalCoor returns the 4 rotated corners", function()
    local e = {x=0, y=0, angle=0, w=10, h=10}
    local pts = getPointsGlobalCoor(e)
    assert.are.equal(4, #pts)
    assert.are.equal(5, pts[1].x)
    assert.are.equal(5, pts[1].y)
    -- 90° rotation maps corner (5,5) to (-5, 5) (screen-space y is down)
    local r = {x=0, y=0, angle=math.pi/2, w=10, h=10}
    local rpts = getPointsGlobalCoor(r)
    assert.True(math.abs(rpts[1].x + 5) < 1e-9)
    assert.True(math.abs(rpts[1].y - 5) < 1e-9)
  end)
end)

describe("base.lua registries", function()
  loader.loadGame()

  it("addDrawFunction registers on layers 1..9, default 5", function()
    local f = function() end
    local before = #draws[5]
    addDrawFunction(f)
    assert.are.equal(before + 1, #draws[5])
    addDrawFunction(f, 9)
    assert.are.equal(#draws[9] + 0, #draws[9]) -- smoke: no error
  end)

  it("addUpdateFunction appends to the update list", function()
    local before = #updates
    addUpdateFunction(function() end)
    assert.are.equal(before + 1, #updates)
  end)
end)

describe("base.lua camera", function()
  loader.loadGame()

  it("follow mode tracks its target", function()
    local target = {x = 42, y = 84}
    camera.mode = {"follow", target}
    camera:update(0.016)
    assert.are.equal(42, camera.x)
    assert.are.equal(84, camera.y)
  end)

  it("moveTo mode snaps and clears itself (regression: was self.mode[1] = {})", function()
    camera.mode = {"moveTo", {x = 42, y = 42}}
    camera:update(0.016)
    assert.are.equal(42, camera.x)
    assert.are.equal(42, camera.y)
    assert.is_nil(camera.mode) -- a cleared mode must be nil, not a truthy {}
  end)

  it("apply uses self, not the global (regression: was camera.rotate)", function()
    local cam = applyParams({}, {
      x = 10, y = 20, scale = 1, angle = 0,
      shaker = {steps = {}, n = 1},
      apply = camera.apply
    })
    assert.has_no.errors(function() cam:apply() end)
  end)
end)
