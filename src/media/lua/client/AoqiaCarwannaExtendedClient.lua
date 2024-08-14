-- -------------------------------------------------------------------------- --
--                      The main entry point for the mod.                     --
-- -------------------------------------------------------------------------- --

-- AoqiaCarwannaExtended requires.
local events = require("AoqiaCarwannaExtendedClient/events")
local mod_constants = require("AoqiaCarwannaExtendedShared/mod_constants")

-- TIS globals cache.
local getActivatedMods = getActivatedMods

local logger = mod_constants.LOGGER

-- ------------------------------- Entrypoint ------------------------------- --

if getActivatedMods():contains("CW") then
    logger:error("The original CarWanna mod was found. To prevent collisions, this mod is disabled.")
    return
end

events.register()

logger:debug("Lua init done!")
