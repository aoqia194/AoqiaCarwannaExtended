-- -------------------------------------------------------------------------- --
--            Handles event stuff like registering listeners/hooks.           --
-- -------------------------------------------------------------------------- --

-- AoqiaCarwannaExtended requires.
local hooks = require("AoqiaCarwannaExtendedClient/hooks")
local mod_constants = require("AoqiaCarwannaExtendedShared/mod_constants")

-- TIS globals cache.
local Events = Events

local logger = mod_constants.LOGGER

-- ------------------------------ Module Start ------------------------------ --

local events = {}

function events.game_boot()
    hooks.register()
end

function events.register()
    logger:debug("Registering events...")
    
    Events.OnGameBoot.Add(events.game_boot)
end

return events
