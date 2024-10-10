-- -------------------------------------------------------------------------- --
--                      The main entry point for the mod.                     --
-- -------------------------------------------------------------------------- --

local events = require("AoqiaCarwannaExtendedShared/events")
local mod_constants = require("AoqiaCarwannaExtendedShared/mod_constants")

local logger = mod_constants.LOGGER

-- ------------------------------- Entrypoint ------------------------------- --

events.register()

logger:debug_shared("Lua init done!")
