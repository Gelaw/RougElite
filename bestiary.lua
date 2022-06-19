

enemiesLibrary = {

  meleeTank = function ()
    return entitySetup({IAinit,ableEntityInit,livingEntityInit,movingEntityInit}, {
      archetypeName = "melee tank",
      maxSpeed= 250,
      width=10, height = 10,
      color = {.5, .4, .8},
      maxLife = 100,
      abilities = {
        decimatingSmash = newAbility("decimatingSmash"),
        unbreakable = newAbility("unbreakable"),
        absoluteZero = newAbility("absoluteZero"),
      },
      IA = basicIA()
    })
  end,

  meleeDps = function ()
    return entitySetup({IAinit,ableEntityInit,livingEntityInit,movingEntityInit}, {
      archetypeName = "melee dps",
      maxSpeed= 400,
      color = {.8, .4, .2},
      life = 60,
      maxLife=60,
      abilities = {
        autohit = newAbility("meleeAutoHit"),
        dash = newAbility("dash"),
      },
      IA = basicIA()
    })
  end,

  shooter = function ()
    local type = math.random(2)
    return entitySetup({IAinit,ableEntityInit,livingEntityInit,movingEntityInit},{
      archetypeName = "shooter type " .. type,
      color = (type == 1 and  {.1, .2, .9} or {.9, .3, .1}),
      x=math.random(-width/2, width/2), y=math.random(-height/2, height/2),
      width = (type == 1 and 7 or 5),
      height = (type == 1 and 5 or 7),
      maxAcceleration = math.random(1200, 1500)*type,
      maxSpeed = 100,
      abilities = {
        boeingboeingboeing = applyParams(newAbility(), abilitiesLibrary.boeingboeingboeing),
        shoot = applyParams(newAbility(), abilitiesLibrary.shoot)
      },
      --behavior
      IA = basicIA(),
      --necessary for base collision detection to consider this entity
      team = 2,
      maxLife = 30+20*type,
    })
  end,

  mage = function ()
    return entitySetup({IAinit,ableEntityInit,livingEntityInit,movingEntityInit}, {
      archetypeName = "mage",
      maxSpeed= 400,
      color = {.8, 0, .8},
      maxLife=30,
      abilities = {
        thunderCall = newAbility("thunderCall"),
        arc = newAbility("arc")
      },
      IA = basicIA()
    })
  end,

  meleeKamikaze = function ()
    return entitySetup({IAinit,ableEntityInit,livingEntityInit,movingEntityInit}, {
      archetypeName = "melee kamikaze",
      maxSpeed= 150,
      color = {.9, 0, .4},
      maxLife=10,
      width = 8,
      height = 4,
      abilities = {
        cupcakeTrap = newAbility("cupcakeTrap"),
        valkyrie = newAbility("valkyrie")
      },
      IA = basicIA()
    })
  end
}
