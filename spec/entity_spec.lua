--------------------------------------------------------------------
-- spec/entity_spec.lua : entity composition and mixins
--------------------------------------------------------------------

local loader = require("spec.game_loader")

describe("entitySetup composition", function()
  loader.loadGame()

  it("chains init functions and applies params", function()
    local e = entitySetup({movingEntityInit, livingEntityInit}, {
      maxLife = 50, name = "test"
    })
    assert.are.equal(50, e.maxLife)
    assert.are.equal(50, e.life) -- maxLife propagated to life
    assert.are.equal("test", e.name)
    assert.are.equal(2, #e.updates) -- one update per mixin
  end)

  it("extraParams.maxLife overrides for life", function()
    local e = entitySetup({livingEntityInit}, {maxLife = 100})
    assert.are.equal(100, e.life)
  end)
end)

describe("livingEntityInit", function()
  loader.loadGame()
  local function freshEntity()
    local e = livingEntityInit()
    e.maxLife, e.life = 10, 10
    return e
  end

  it("hit() reduces life, grants invicibility frames", function()
    local e = freshEntity()
    e:hit(3)
    assert.are.equal(7, e.life)
    assert.is_not.equal(nil, e.invicibility)
    assert.True(e.intangible)
  end)

  it("hit() triggers onDeath when life reaches 0", function()
    loader.resetWorld()
    local e = freshEntity()
    e:hit(10)
    assert.True(e.dead)
    assert.are.equal(2, #particuleEffects) -- 1 hit popup + 1 death burst
  end)

  it("dead entities ignore further hits", function()
    local e = freshEntity()
    e:hit(10)
    e:hit(5)
    assert.are.equal(0, e.life)
  end)

  it("invicibility expires with time", function()
    local e = freshEntity()
    e.invicibilityTimeAfterHit = 0.5
    e:hit(1)
    e:update(0.6)
    assert.is_nil(e.invicibility)
    assert.are.equal(false, e.intangible) -- reset to false, not nil
  end)

  it("collide() ignores intangible entities and same-team hits", function()
    local e = freshEntity()
    e.intangible = true
    e:collide({contactDamage = 5})
    assert.are.equal(10, e.life)
    e.intangible = nil
    e.team, e.life = 1, 10
    e:collide({team = 1, contactDamage = 5}) -- same team
    assert.are.equal(10, e.life)
    e:collide({team = 2, contactDamage = 5}) -- other team
    assert.are.equal(5, e.life)
  end)

  it("ressources regenerate per quarter second", function()
    local e = freshEntity()
    e.ressources.mana = {current = 0, max = 100, regenPerSec = 40}
    e:update(0.3) -- one regen tick (> .25s)
    assert.are.equal(10, e.ressources.mana.current)
    e:update(1) -- a single update only performs one tick
    assert.are.equal(20, e.ressources.mana.current)
  end)
end)

describe("movingEntityInit", function()
  loader.loadGame()

  it("stuck entities freeze and reset their motion", function()
    local e = movingEntityInit()
    e.stuck = true
    e.acceleration = {x = 100, y = 100}
    e:update(0.016)
    assert.are.equal(0, e.speed.x)
    assert.are.equal(0, e.speed.y)
    assert.are.equal(0, e.acceleration.x)
  end)

  it("speed integrates acceleration and is clamped by maxSpeed", function()
    local e = movingEntityInit()
    e.maxSpeed = 100
    e.acceleration = {x = 50000, y = 0}
    e:update(0.016)
    assert.are.equal(100, e.speed.x) -- clamped by maxSpeed after drag
  end)

  it("tryMovingTo moves freely without walls", function()
    walls = {}
    local e = movingEntityInit()
    e.x, e.y = 50, 50
    local blocked = e:tryMovingTo({x = 60, y = 50})
    assert.is_nil(blocked)
    assert.are.equal(60, e.x)
  end)

  it("tryMovingTo is blocked by a wall and keeps position", function()
    walls = {{{x = 0, y = 0}, {x = 0, y = 100}}}
    local e = movingEntityInit()
    e.x, e.y = 50, 50
    local blocked = e:tryMovingTo({x = -50, y = 50})
    assert.is_not.equal(nil, blocked)
    assert.are.equal(50, e.x) -- unchanged
  end)
end)

describe("ghost", function()
  loader.loadGame()

  it("newGhost spawns a followable ghost in entities", function()
    entities = {}
    local g = newGhost({x = 123, y = 456})
    assert.are.equal(123, g.x)
    assert.are.equal(1, #entities)
    assert.are.same({"follow", g}, camera.mode)
    ghost = nil -- cleanup
  end)

  it("ghost colliding with a dead enemy possesses it (playerInit)", function()
    entities = {}
    local corpse = entitySetup({livingEntityInit, movingEntityInit}, {team = 2, maxLife = 10})
    corpse.dead = true
    table.insert(entities, corpse)
    abilitiesHUD = {load = function() end}
    local g = newGhost({x = 0, y = 0})
    g:collide(corpse)
    assert.are.same(corpse, player)
    assert.is_nil(ghost)
    assert.are.same({"follow", player}, camera.mode)
  end)
end)
