

meleeTank = function ()
  return entitySetup({IAinit,ableEntityInit,livingEntityInit,movingEntityInit}, {
    maxSpeed= 40,
    color = {.5, .4, .8},
    life = 10,
    contactDamage = 1,
    abilities = {
      decimatingSmash = newAbility("decimatingSmash"),
      unbreakable = newAbility("unbreakable"),
      absoluteZero = newAbility("absoluteZero"),
    },
    IA = basicIA()
  })
end

meleeDps = function ()
  return entitySetup({IAinit,ableEntityInit,livingEntityInit,movingEntityInit}, {
    maxSpeed= 120,
    color = {.8, .4, .2},
    life = 6,
    maxLife=6,
    abilities = {
      autohit = newAbility("meleeAutoHit"),
      dash = newAbility("dash"),
    },
    IA = basicIA()
  })
end
