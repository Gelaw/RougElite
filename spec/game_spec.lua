--------------------------------------------------------------------
-- spec/game_spec.lua : spawning, passives, invocation circle
--------------------------------------------------------------------

local loader = require("spec.game_loader")

describe("spawn()", function()
  loader.loadGame()

  local function fakeArchetype()
    return entitySetup({movingEntityInit, livingEntityInit}, {
      name = "fake", maxLife = 100,
      abilities = {myAb = {damage = 10, name = "ab"}},
    })
  end

  it("inserts the entity and applies dead state", function()
    loader.resetWorld()
    _G.entities = {}
    _G.ennemyPassives = nil
    local e = spawn(fakeArchetype, {team = 2, dead = true})
    assert.are.equal(1, #entities)
    assert.are.same(e, entities[1])
    assert.are.equal(.3, e.color[1]) -- onDeath tint
  end)

  it("applies enemy passives to entity-level stats (regression: entity[s] vs ability[s])", function()
    _G.entities = {}
    _G.ennemyPassives = {maxLife = .7, damage = .7}
    local e = spawn(fakeArchetype, {team = 2, maxLife = 200})
    assert.are.equal(140, e.maxLife)
  end)

  it("applies enemy passives to ability stats (regression: entity[s] vs ability[s])", function()
    _G.entities = {}
    _G.ennemyPassives = {damage = .7}
    local e = spawn(fakeArchetype, {team = 2})
    assert.are.equal(7, e.abilities.myAb.damage)
  end)

  it("leaves allies (team 1) untouched by enemy passives", function()
    _G.entities = {}
    _G.ennemyPassives = {damage = .7}
    local e = spawn(fakeArchetype, {team = 1})
    assert.are.equal(10, e.abilities.myAb.damage)
  end)
end)

describe("invocation circle", function()
  loader.loadGame()

  it("newInvocationCircle creates a hidden circle", function()
    _G.entities = {}
    local circle = newInvocationCircle()
    assert.True(circle.hidden)
    assert.are.equal(1, #entities)
    assert.are.same(circle, entities[1])
    assert.are.same(circle, invocationCircle)
  end)

  it("moveTo reveals and resets the animation", function()
    _G.entities = {}
    local circle = newInvocationCircle()
    circle:update(10) -- exhaust the animation, hides itself
    circle:moveTo(42, 84)
    assert.False(circle.hidden)
    assert.are.equal(42, circle.x)
    assert.are.equal(84, circle.y)
    assert.are.equal(0, circle.a)
    assert.are.equal(circle.innerRadius, circle.outerRadius)
  end)

  it("update animates the sweep then fades out", function()
    _G.entities = {}
    local circle = newInvocationCircle()
    circle:moveTo(0, 0)
    local i = 0
    while not circle.hidden and i < 10000 do
      circle:update(0.05)
      i = i + 1
    end
    assert.True(circle.hidden) -- ends hidden after the full ritual
    assert.True(i < 10000)
  end)
end)
