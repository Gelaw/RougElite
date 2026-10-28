--------------------------------------------------------------------
-- spec/level_spec.lua : level generation, walls, save
--------------------------------------------------------------------

local loader = require("spec.game_loader")

describe("level generation", function()
  loader.loadGame()

  it("calculate() derives room positions from entry chains", function()
    _G.levelRooms = {
      {x = 0, y = 0, w = 100, h = 100}, -- room 1: origin
      {w = 100, h = 100, entry = {1, "east", .5, .5, 10}}, -- attached east of room 1
    }
    calculate()
    local r2 = levelRooms[2]
    -- east of room 1: x = 0 + .5*100 + .5*100 = 100, y stays 0
    assert.are.equal(100, r2.x)
    assert.are.equal(0, r2.y)
    assert.is_not.equal(nil, r2.doors)
  end)

  it("generateWalls() builds rooms and wall segments from levelRooms", function()
    _G.levelRooms = {
      {x = 0, y = 0, w = 100, h = 100},
      {x = 200, y = 0, w = 100, h = 100, entry = {1, "east", .5, .5, 10}},
    }
    calculate()
    generateWalls()
    assert.are.equal(2, #rooms)
    assert.is_not.equal(nil, next(walls)) -- at least some walls
  end)

  it("locatePoint() returns the room index containing the point", function()
    _G.levelRooms = {
      {x = 0, y = 0, w = 100, h = 100},
      {w = 100, h = 100, entry = {1, "east", .5, .5, 10}},
    }
    calculate() -- room 2 is positioned BY calculate(): x=100, y=0
    generateWalls()
    assert.are.equal(1, locatePoint(0, 0))
    assert.are.equal(2, locatePoint(100, 0))
    assert.are.equal(-1, locatePoint(1000, 1000))
  end)

  it("wallCollision detects a crossing and reports the wall", function()
    _G.walls = {{{x = 0, y = 0}, {x = 0, y = 100}}}
    local hit, wall = wallCollision({x = 50, y = 50}, {x = -50, y = 50})
    assert.True(hit)
    assert.is_not.equal(nil, wall)
    local miss = wallCollision({x = 50, y = 50}, {x = 60, y = 50})
    assert.False(miss)
  end)

  it("cardinalOpposite maps directions", function()
    assert.are.equal("south", cardinalOpposite("north"))
    assert.are.equal("north", cardinalOpposite("south"))
    assert.are.equal("west", cardinalOpposite("east"))
    assert.are.equal("east", cardinalOpposite("west"))
  end)
end)

describe("level serialization", function()
  loader.loadGame()

  it("recursiveToString round-trips simple data", function()
    local data = {x = 1, nested = {y = "a", 42}}
    -- round-trip via a return value: portable across Lua 5.1 (game target)
    -- and 5.2+ where load() chunks get a sandboxed environment.
    local chunk = assert((loadstring or load)("return " .. recursiveToString(data, "")))
    local result = chunk()
    assert.are.equal(1, result.x)
    assert.are.equal("a", result.nested.y)
    assert.are.equal(42, result.nested[1])
  end)

  it("skips functions", function()
    local text = recursiveToString({f = function() end, keep = 1}, "")
    local chunk = assert((loadstring or load)("return " .. text))
    local result = chunk()
    assert.is_nil(result.f)
    assert.are.equal(1, result.keep)
  end)
end)
