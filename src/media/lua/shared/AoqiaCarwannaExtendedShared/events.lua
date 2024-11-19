-- -------------------------------------------------------------------------- --
--            Handles event stuff like registering listeners/hooks.           --
-- -------------------------------------------------------------------------- --

-- Vanilla Global Tables/Variables
local Events = Events

-- My Mod Modules
local mod_constants = require("AoqiaCarwannaExtendedShared/mod_constants")
local sandbox_data = require("AoqiaCarwannaExtendedShared/sandbox_data")
local tweaks = require("AoqiaCarwannaExtendedShared/tweaks")

local logger = mod_constants.LOGGER

-- ------------------------------ Module Start ------------------------------ --

local events = {}

--- @type Callback_OnInitGlobalModData
function events.init_global_moddata(new_game)
    sandbox_data.init()
    tweaks.init()
end

function events.register()
    logger:debug_shared("Registering events...")

    Events.OnInitGlobalModData.Add(events.init_global_moddata)
end

return events
