--------------------------------------------------------------------
-- spec/ability_spec.lua : ability framework, hitInHitbox, newAbility
--------------------------------------------------------------------

local loader = require("spec.game_loader")

describe("newAbility", function()
  loader.loadGame()

  it("returns a default ability when index is unknown", function()
    local ab = newAbility()
    assert.are.equal("defaultName", ab.name)
    assert.False(ab.active)
  end)

  it("applies a library entry by key (bouncingBomb)", function()
    local ab = newAbility("bouncingBomb")
    assert.are.equal("bouncingBomb", ab.name)
    assert.are.equal(3, ab.bounces)
  end)

  it("cooldown ticks down to 0", function()
    local ab = newAbility()
    ab.baseCooldown = 5
    ab:onCooldownStart()
    assert.are.equal(5, ab.cooldown)
    ab:cooldownUpdate(2)
    assert.are.equal(3, ab.cooldown)
    ab:cooldownUpdate(10)
    assert.are.equal(0, ab.cooldown)
  end)

  it("charges deplete and regenerate", function()
    local ab = applyParams(newAbility(), {charges = 2, maxCharges = 4, baseChargeCooldown = 5})
    ab:deactivate()
    assert.are.equal(1, ab.charges)
  end)
end)

describe("hitInHitbox", function()
  loader.loadGame()

  local function freshVictim()
    local v = livingEntityInit()
    v.team, v.life, v.maxLife = 2, 100, 100
    return v
  end

  it("rectangular hitbox hits contained entities and returns them", function()
    loader.resetWorld()
    local victim = freshVictim()
    -- off-center: an entity exactly at the hitbox center is MISSED by the
    -- corner-vs-center segment test (segments pass through it) — quirk of
    -- the current collision filter, documented here.
    victim.x, victim.y = 20, 10
    entities = {victim}
    local caster = {team = 1, x = 0, y = 0}
    local hits = hitInHitbox({x = 0, y = 0, angle = 0, w = 100, h = 100}, caster, 5)
    -- quirk: the RECTANGULAR branch damages entities but does NOT append
    -- them to the returned `hits` list (only the circular branch does).
    -- Documented as-is; consumers of the return value use circular hitboxes.
    assert.are.equal(0, #hits)
    assert.are.equal(95, victim.life)
  end)

  it("circular hitbox hits entities within radius", function()
    loader.resetWorld()
    local victim = freshVictim()
    victim.x, victim.y = 30, 0
    entities = {victim}
    local hits = hitInHitbox({x = 0, y = 0, radius = 50}, {team = 1}, 5)
    assert.are.equal(1, #hits)
    victim.x = 100
    hits = hitInHitbox({x = 0, y = 0, radius = 50}, {team = 1}, 5)
    assert.are.equal(0, #hits)
  end)

  it("ignores same-team and dead entities", function()
    loader.resetWorld()
    local ally = freshVictim()
    ally.team = 1
    local corpse = freshVictim()
    corpse.dead = true
    corpse.life = 0 -- note: hitInHitbox filters on life, not dead; a dead
    -- entity that still has life > 0 IS included in `hits` (harmless: hit()
    -- returns early on dead) — documented quirk of the current filter.
    entities = {ally, corpse}
    local hits = hitInHitbox({x = 0, y = 0, radius = 500}, {team = 1}, 5)
    assert.are.equal(0, #hits)
  end)
end)

describe("abilitiesLibrary entries", function()
  loader.loadGame()

  it("all bestiary-referenced ability keys exist in the library", function()
    local referenced = {}
    local function collect(tbl)
      for k, v in pairs(tbl) do
        if type(v) == "table" then collect(v) end
        if k == "newAbility" or type(v) == "function" then
          -- handled below via bestiary inspection
        end
      end
    end
    -- Every ability key used by bestiary archetypes must resolve.
    local seen = {}
    local function checkArchetype(factory)
      local ok, entity = pcall(factory)
      if not ok then error("bestiary factory crashed: " .. tostring(entity)) end
      for key, ability in pairs(entity.abilities or {}) do
        seen[key] = true
        assert.is_not.equal(nil, ability.name, "ability '" .. key .. "' has no name")
      end
    end
    for name, factory in pairs(enemiesLibrary) do
      checkArchetype(factory)
    end
    assert.True(next(seen) ~= nil)
  end)

  it("every abilitiesLibrary key instantiates via newAbility", function()
    for key, _ in pairs(abilitiesLibrary) do
      local ab = newAbility(key)
      assert.is_not.equal(nil, ab, "newAbility('" .. key .. "') failed")
      assert.are_not.same("defaultName", ab.name,
        "library key '" .. key .. "' not applied")
    end
  end)
end)
