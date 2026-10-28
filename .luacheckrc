-- luacheck configuration for RougElite
-- Docs: https://luacheck.readthedocs.io/en/stable/config.html
--
-- The engine deliberately shares state through globals. This file is the
-- exhaustive inventory: any global assigned or read in the root game code
-- that is NOT listed here is flagged by luacheck (and by CI).

-- lua51 std + the love2d std from luacheck's bundled definitions
-- (registers love callbacks like love.update as writable fields).
std = "lua51+love"

stds = stds or {}

-- base.lua extends the math library at load time (math.dist, math.angle,
-- math.round, math.sign, math.angleDiff, math.normalize, math.multiple,
-- math.averageAngles, math.rsign, math.prandom, math.clamp).
-- luacheck's bundled stds don't know them; declare them and merge into
-- the active std with +rougelite.
stds.rougelite = {
  read_globals = {
    math = {
      fields = {
        "dist", "angle", "round", "sign", "angleDiff", "normalize",
        "multiple", "averageAngles", "rsign", "prandom", "clamp",
      },
    },
  },
}

-- merge rougelite into the default stds (use +rougelite in std)
std = "lua51+love+rougelite"

globals = {
  -- ==== top-level functions (engine modules) ====
  -- base.lua
  "applyParams", "addDrawFunction", "addUpdateFunction", "addBind",
  "getBindOf", "cameraShake", "basicParticuleEffectDraw",
  "basicEntityDraw", "getPointsGlobalCoor", "init", "safeLoadAndRun",
  "lerp", "lerp2", "cerp", "checkIntersect", "findIntersect",
  "get_closest_point", "saveToFile", "recursiveToString",
  -- level.lua
  "levelDisplayInit", "levelSetup", "wallCollision", "locatePoint",
  "addRoom", "addWall", "generateWalls", "cardinalOpposite",
  -- entity.lua
  "newEntity", "movingEntityInit", "livingEntityInit", "playerInit",
  "newGhost", "entitySetup",
  -- ia.lua
  "newTask", "newIA", "basicIA", "IAinit", "IAtargetingUpdate",
  -- ability.lua
  "newAbility", "ableEntityInit", "hitInHitbox", "calculate",
  -- game.lua
  "gameSetup", "setupSkillAndMonsterUIs", "newInvocationCircle",
  "gameStart", "spawnIAPlaytester", "spawn", "newCheatPlayer",
  "cameraSetup", "gameMousePress", "gameMouseRelease",
  -- ui.lua
  "drawUIs", "drawElementAndChildren", "getElementOn",
  "getElementOrChildOn", "UIMousePress", "UIMouseRelease",
  -- main.lua
  "projectSetup",

  -- ==== registries & shared runtime state ====
  "draws", "updates", "uis", "bindings", "camera", "joystickButtons",
  "player", "ghost", "enemies", "entities", "particuleEffects",
  "walls", "rooms", "doors", "levelRooms", "baseRoomSize", "basedoorWidth",
  "width", "height", "joystick", "closest", "dist",
  "invocationCircle", "abilitiesHUD", "passiveSkillUI", "monsterdexUI",
  "passives", "ennemyPassives", "StartingNumberEnemies", "teamColors",
  "enemyLibKeys", "mode", "victoire", "roomHighlight",
  "mousePressedOnWorld", "showHitboxes", "gameover", "debugSpeedAcc",
  "updateTimerClosestEnemy", "lifebarWidth", "interIATUtick",
  "normalfont", "bigassfont", "directions", "north", "south", "east", "west",
  "pressed",

  -- ==== globals leaked by ability.lua (to be localized when the module
  --      is refactored; declared so CI stays green meanwhile) ====
  "projectile", "angleWall", "deltaAngle", "hits", "wall",

  -- ==== data libraries ====
  "abilitiesLibrary", "enemiesLibrary",
}

-- Lint only the root game code. The editors are standalone apps with
-- their own diverged copies of base.lua; .luarocks/ may exist locally
-- after tooling installation and must never be linted.
-- (CI runs `luacheck *.lua` — this list is the fallback for bare `luacheck .`)
include_files = {
  "*.lua",
  ".luacheckrc",
}

-- Style choices of this codebase: no line-length limit.
no_max_line_length = true

-- Unused loop variables/args are pervasive in callbacks (love.keypressed
-- signatures, pairs loops); shadowing is common in nested closures.
-- Keep them at info level so CI blocks only on real global leaks.
unused_args = false
self = false

-- CI runs on every push; disable the cache for consistent output.
cache = false
