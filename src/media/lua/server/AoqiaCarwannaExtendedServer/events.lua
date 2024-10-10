-- -------------------------------------------------------------------------- --
--            Handles event stuff like registering listeners/hooks.           --
-- -------------------------------------------------------------------------- --

-- My modules.
local blacklists = require("AoqiaCarwannaExtendedShared/blacklists")
local commands = require("AoqiaCarwannaExtendedServer/commands")
local distributions = require("AoqiaCarwannaExtendedServer/distributions")
local mod_constants = require("AoqiaCarwannaExtendedShared/mod_constants")

-- TIS globals.
local Events = Events

local logger = mod_constants.LOGGER

-- ------------------------------ Module Start ------------------------------ --

local events = {}

--- @type Callback_OnClientCommand
function events.on_client_command(module, command, player, args)
    -- This isn't being called when a client tries to send command to server.
    if module ~= mod_constants.MOD_ID then return end
    if commands[command] == nil then
        logger:info_server("Received non-existent client command (%s).", command)
        return
    end

    logger:info_server("Received client command (%s) from player (%s) <%s>.", command,
        player:getUsername(), tostring(player:getSteamID()))
    commands[command](player, args)
end

--- @type Callback_OnInitGlobalModData
function events.init_global_moddata(new_game)
    blacklists.init()
    distributions.init()
end

function events.register()
    logger:debug_server("Registering events...")

    Events.OnClientCommand.Add(events.on_client_command)
    Events.OnInitGlobalModData.Add(events.init_global_moddata)
end

return events
