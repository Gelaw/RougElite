enemiesLibrary = {
  meleeTank = function ()
    local entity = entitySetup({IAinit,ableEntityInit,livingEntityInit,movingEntityInit}, {
      archetypeName = "melee tank",
      name = "melee tank",
      maxSpeed= 250,
      width=10, height = 10,
      color = {.5, .4, .8},
      maxLife = 100,
      abilities = {
        decimatingSmash = newAbility("decimatingSmash"),
        unbreakable = newAbility("unbreakable"),
        absoluteZero = newAbility("absoluteZero"),
      }
    })
    entity.IA = basicIA(entity)
    return entity
  end,

  meleeDps = function ()
    local entity = entitySetup({IAinit,ableEntityInit,livingEntityInit,movingEntityInit}, {
      archetypeName = "melee dps",
      name = "melee dps",
      maxSpeed= 400,
      color = {.8, .4, .2},
      life = 60,
      maxLife=60,
      abilities = {
        autohit = newAbility("meleeAutoHit"),
        dash = newAbility("dash"),
      }
    })
    entity.IA = basicIA(entity)
    return entity
  end,

  shooter = function ()
    local type = math.random(2)
    local entity = entitySetup({IAinit,ableEntityInit,livingEntityInit,movingEntityInit},{
      archetypeName = "shooter type " .. type,
      name =  "shooter type " .. type,
      color = (type == 1 and  {.1, .2, .9} or {.9, .3, .1}),
      x=0, y=0,
      width = (type == 1 and 7 or 5),
      height = (type == 1 and 5 or 7),
      maxAcceleration = math.random(1200, 1500)*type,
      maxSpeed = 100,
      abilities = {
        bouncingBomb = applyParams(newAbility(), abilitiesLibrary.bouncingBomb),
        shoot = applyParams(newAbility(), abilitiesLibrary.shoot)
      },
      --necessary for base collision detection to consider this entity
      team = 2,
      maxLife = 30+20*type,
    })
    entity.IA = basicIA(entity)
    return entity
  end,

  mage = function ()
    local entity = entitySetup({IAinit,ableEntityInit,livingEntityInit,movingEntityInit}, {
      archetypeName = "mage",
      name = "mage",
      maxSpeed= 400,
      color = {.8, 0, .8},
      ressources = {mana = {current = 40, max = 40, regenPerSec = 5}},
      maxLife=30,
      abilities = {
        thunderCall = newAbility("thunderCall"),
        arc = newAbility("arc")
      }
    })
    entity.IA = basicIA(entity)
    return entity
  end,

  meleeKamikaze = function ()
    local entity = entitySetup({IAinit,ableEntityInit,livingEntityInit,movingEntityInit}, {
      archetypeName = "melee kamikaze",
      name = "melee kamikaze",
      maxSpeed= 150,
      color = {.9, 0, .4},
      maxLife=10,
      width = 8,
      height = 4,
      abilities = {
        cupcakeTrap = newAbility("cupcakeTrap"),
        valkyrie = newAbility("valkyrie")
      }
    })
    entity.IA = basicIA(entity)
    return entity
  end
}
