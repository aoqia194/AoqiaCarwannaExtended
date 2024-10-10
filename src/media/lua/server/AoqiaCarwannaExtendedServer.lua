-- -------------------------------------------------------------------------- --
--                      The main entry point for the mod.                     --
-- -------------------------------------------------------------------------- --

-- AoqiaCarwannaExtended requires.
local constants = require("AoqiaZomboidUtilsShared/constants")
local events = require("AoqiaCarwannaExtendedServer/events")
local mod_constants = require("AoqiaCarwannaExtendedShared/mod_constants")

-- TIS globals cache
local getActivatedMods = getActivatedMods

local logger = mod_constants.LOGGER

-- ------------------------------- Entrypoint ------------------------------- --

-- Don't load on the client (excluding singleplayer).
if constants.IS_CLIENT and constants.IS_SINGLEPLAYER == false then
    logger:debug("Prevented server entrypoint from being executed because that is bad.")
    return
end

local mods = getActivatedMods()
if mods:contains("CW") then
    logger:error("The original CarWanna mod was found. To prevent collisions, this mod is disabled.")
    return
end

events.register()

logger:debug_server("Lua init done!")
