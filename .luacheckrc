-- luacheck configuration for RougElite
-- Docs: https://luacheck.readthedocs.io/en/stable/config.html
--
-- The engine deliberately shares state through globals. This file is the
-- exhaustive inventory: any global assigned or read in the root game code
-- that is NOT listed here is flagged by luacheck (and by CI).

std = "lua51"

-- The only external API. love.* is read-only for us; fields (love.graphics,
-- love.timer, ...) are not individually declared as luacheck only tracks
-- the top-level name.
read_globals = { "love" }

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
  -- bestiary.lua (library, assigned below)
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

  -- ==== data libraries ====
  "abilitiesLibrary", "enemiesLibrary",
}

-- The editors are standalone apps with their own diverged copies of
-- base.lua. Linting them here would produce false positives against the
-- root config; keep them out until they are deduplicated.
exclude_files = { "levelEditor/*", "particuleEmiterEditor/*", "*.love" }

-- Style choices of this codebase: no line-length limit.
no_max_line_length = true

-- CI runs on every push; disable the cache for consistent output.
cache = false
