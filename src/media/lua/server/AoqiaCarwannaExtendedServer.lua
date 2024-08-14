-- -------------------------------------------------------------------------- --
--                      The main entry point for the mod.                     --
-- -------------------------------------------------------------------------- --

-- AoqiaCarwannaExtended requires.
local constants = require("AoqiaZomboidUtils/constants")
local events = require("AoqiaCarwannaExtendedServer/events")
local mod_constants = require("AoqiaCarwannaExtendedShared/mod_constants")

-- TIS globals cache
local getActivatedMods = getActivatedMods

local logger = mod_constants.LOGGER

-- ------------------------------- Entrypoint ------------------------------- --

-- Don't load on the client (excluding coop host or singleplayer).
if  constants.IS_CLIENT
and constants.IS_SINGLEPLAYER == false
and constants.IS_COOP == false then
    logger:debug_server("Prevented server code from being loaded because N O.")
    return
end

if getActivatedMods():contains("CW") then
    logger:error("The original CarWanna mod was found. To prevent collisions, this mod is disabled.")
    return
end

events.register()

logger:debug_server("Lua init done!")
