

enemiesLibrary = {

  meleeTank = function ()
    return entitySetup({IAinit,ableEntityInit,livingEntityInit,movingEntityInit}, {
      maxSpeed= 250,
      width=10, height = 10,
      color = {.5, .4, .8},
      life = 10,
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
      maxSpeed= 400,
      color = {.8, .4, .2},
      life = 6,
      maxLife=6,
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
      color = (type == 1 and  {.1, .2, .9} or {.9, .3, .1}),
      x=math.random(-width/2, width/2), y=math.random(-height/2, height/2),
      width = (type == 1 and 7 or 5),
      height = (type == 1 and 5 or 7),
      maxAcceleration = math.random(1200, 1500)*type,
      maxSpeed = 100,
      abilities = {
        shoot = applyParams(newAbility(), abilitiesLibrary.shoot)
      },
      --behavior
      IA = basicIA(),
      --necessary for base collision detection to consider this entity
      team = 2,
      life = 3+2*type, maxLife = 3+2*type,
    })
  end,

  mage = function ()
    return entitySetup({IAinit,ableEntityInit,livingEntityInit,movingEntityInit}, {
      maxSpeed= 400,
      color = {.8, 0, .8},
      life = 3,
      maxLife=3,
      abilities = {
        thunderCall = newAbility("thunderCall")
      },
      IA = basicIA()
    })
  end,

  meleeKamikaze = function ()
    return entitySetup({IAinit,ableEntityInit,livingEntityInit,movingEntityInit}, {
      maxSpeed= 150,
      color = {.9, 0, .4},
      life = 1,
      maxLife=1,
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
