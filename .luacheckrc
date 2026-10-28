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
  globals = {
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

  -- ==== adapter interfaces (injected by adapters/love_adapter.lua,
  --      defaulted in core/base.lua, doubled in spec/game_loader.lua) ====
  "G", "getTimestamp", "random",
  "loadLevelFile", "writeLevelFile", "refreshJoystick",
  "Mouse", "Keyboard", "Joystick",

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


  -- ==== data libraries ====
  "abilitiesLibrary", "enemiesLibrary",
}

-- Lint only the root game code. The editors are standalone apps with
-- their own diverged copies of base.lua; .luarocks/ may exist locally
-- after tooling installation and must never be linted.
-- (CI runs `luacheck *.lua` — this list is the fallback for bare `luacheck .`)
include_files = {
  "main.lua", "core/*.lua", "domain/*.lua", "adapters/*.lua",
  ".luacheckrc",
  -- spec/ is excluded: specs legitimately reference the game's globals
  -- as their subjects; they are validated by execution (busted), not lint.
}

exclude_files = { "levelEditor/*", "particuleEmiterEditor/*", "spec/*", "*.love" }

-- CI policy: block ONLY on real global leaks / undefined accesses.
-- Warning codes: https://luacheck.readthedocs.io/en/stable/warnings.html
-- Kept active (fail CI):
--   111 setting undefined global, 112 mutating, 113 accessing,
--   121/122 setting read-only global/field, 131 unused implicit global,
--   142/143 undefined field of a global
-- Ignored (style, pervasive and intentional in this codebase):
--   2xx unused locals/args/loop vars, 3xx unused values,
--   4xx shadowing/redefining (nested closures reuse self/dt/entity),
--   5xx control flow (empty branches kept as TODOs, unbalanced RHS),
--   6xx formatting (long lines, whitespace)
ignore = {
  "211", "212", "213", "214", "221", "222", "223", "231", "232", "233", "241",
  "311", "312", "313", "314", "321", "331", "341",
  "411", "412", "413", "421", "422", "423", "431", "432", "433",
  "511", "512", "521", "531", "532", "541", "542", "551", "561", "571", "581", "582",
  "611", "612", "613", "614", "621", "631",
}

-- Style choices of this codebase: no line-length limit.
no_max_line_length = true
unused_args = false
self = false

-- CI runs on every push; disable the cache for consistent output.
cache = false
