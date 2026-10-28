--------------------------------------------------------------------
-- spec/ia_ui_spec.lua : AI state machine and UI press/release logic
--------------------------------------------------------------------

local loader = require("spec.game_loader")

local function step(ia, entity, dt)
  local task = ia[ia.task]
  task.update(task, ia, entity, dt or 0.016)
end

describe("basicIA task machine", function()
  loader.loadGame()

  local function freshEnemy()
    local e = entitySetup({IAinit, ableEntityInit, livingEntityInit, movingEntityInit}, {
      name = "tester", maxSpeed = 100, maxLife = 100,
      abilities = {
        farAb = applyParams(newAbility(), {name = "far", baseCooldown = 0, range = 500}),
      },
    })
    e.IA = basicIA(e)
    return e
  end

  it("starts in the unstarted task", function()
    local e = freshEnemy()
    assert.are.equal("unstarted", e.IA.task)
  end)

  it("transitions unstarted -> idle -> decision -> attack when a target exists", function()
    _G.walls = {}
    local e = freshEnemy()
    e.IA.target = {x = e.x + 50, y = e.y, life = 100, dead = false}
    step(e.IA, e)
    assert.are.equal("idle", e.IA.task)
    step(e.IA, e) -- inside aggroRange (1300)
    assert.are.equal("decision", e.IA.task)
    step(e.IA, e)
    assert.are.equal("attack", e.IA.task)
    assert.are.equal("farAb", e.IA.choice)
  end)

  it("idle keeps waiting when the target is out of aggro range", function()
    _G.walls = {}
    local e = freshEnemy()
    e.IA.target = {x = e.x + 5000, y = e.y, life = 100, dead = false}
    step(e.IA, e) -- unstarted -> idle
    step(e.IA, e)
    assert.are.equal("idle", e.IA.task)
  end)

  it("attack turns toward the target before casting", function()
    _G.walls = {}
    local e = freshEnemy()
    e.IA.target = {x = e.x, y = e.y - 10, life = 100, dead = false}
    step(e.IA, e) step(e.IA, e) step(e.IA, e) -- -> attack
    step(e.IA, e)
    -- the entity turns toward its target (angle moves up)
    assert.is_not.equal(nil, e.targetAngle)
  end)

  it("losing the target returns to idle", function()
    _G.walls = {}
    local e = freshEnemy()
    e.IA.target = {x = e.x + 50, y = e.y, life = 100, dead = false}
    step(e.IA, e) step(e.IA, e) step(e.IA, e) -- -> attack
    e.IA.target = nil
    step(e.IA, e)
    assert.are.equal("idle", e.IA.task)
  end)
end)

describe("IAtargetingUpdate", function()
  loader.loadGame()

  it("assigns the closest hostile target through walls-free line of sight", function()
    loader.resetWorld()
    _G.walls = {}
    local a = entitySetup({IAinit, livingEntityInit, movingEntityInit}, {team = 1, maxLife = 100})
    a.IA = basicIA(a) -- IAinit runs the task loop but the IA table is assigned by the bestiary
    local near = entitySetup({livingEntityInit, movingEntityInit}, {team = 2, maxLife = 100})
    local far = entitySetup({livingEntityInit, movingEntityInit}, {team = 2, maxLife = 100})
    near.x, near.y = a.x + 100, a.y
    far.x, far.y = a.x + 900, a.y
    _G.entities = {a, near, far}
    _G.interIATUtick = 1
    IAtargetingUpdate(2) -- force a tick
    assert.are.same(near, a.IA.target)
  end)

  it("targets nothing when a wall blocks the line of sight", function()
    loader.resetWorld()
    -- vertical wall between a (0,0) and b (100,0)
    _G.walls = {{{x = 50, y = -500}, {x = 50, y = 500}}}
    local a = entitySetup({IAinit, livingEntityInit, movingEntityInit}, {team = 1, maxLife = 100})
    a.IA = basicIA(a)
    local b = entitySetup({livingEntityInit, movingEntityInit}, {team = 2, maxLife = 100})
    a.x, a.y = 0, 0
    b.x, b.y = 100, 0
    _G.entities = {a, b}
    IAtargetingUpdate(2)
    assert.is_nil(a.IA.target)
  end)
end)

describe("ui press/release", function()
  loader.loadGame()

  local function freshButton()
    _G.uis = {}
    local clicks = {n = 0}
    local btn = {
      x = 0, y = 0, width = 100, height = 50,
      onClick = function(self) clicks.n = clicks.n + 1 end,
    }
    table.insert(uis, btn)
    return btn, clicks
  end

  it("press on a widget tracks it and returns true", function()
    local btn, _ = freshButton()
    assert.True(UIMousePress(50, 25, 1))
    assert.are.same(btn, pressed)
  end)

  it("click fires only when press and release hit the same widget", function()
    local _, clicks = freshButton()
    UIMousePress(50, 25, 1)
    assert.True(UIMouseRelease(50, 25, 1))
    assert.are.equal(1, clicks.n)
    assert.is_nil(pressed)
  end)

  it("release outside the widget cancels the click", function()
    local _, clicks = freshButton()
    UIMousePress(50, 25, 1)
    assert.False(UIMouseRelease(500, 500, 1))
    assert.are.equal(0, clicks.n)
    assert.is_nil(pressed)
  end)

  it("nested children are hit-tested relative to the parent", function()
    _G.uis = {}
    local childClicks = {n = 0}
    local child = {
      x = 10, y = 10, width = 20, height = 20,
      onClick = function(self) childClicks.n = childClicks.n + 1 end,
    }
    table.insert(uis, {x = 0, y = 0, width = 100, height = 100, children = {child}})
    assert.True(UIMousePress(15, 15, 1))
    assert.are.same(child, pressed)
    UIMouseRelease(15, 15, 1)
    assert.are.equal(1, childClicks.n)
  end)
end)
