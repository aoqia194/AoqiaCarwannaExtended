-- -------------------------------------------------------------------------- --
--                       Sandbox Options Blacklist Stuff                      --
-- -------------------------------------------------------------------------- --

-- AoqiaCarwannaExtended requires.
local mod_constants = require("AoqiaCarwannaExtendedShared/mod_constants")

-- std globals
local string = string
local table = table
-- TIS globals cache.
local SandboxVars = SandboxVars

local logger = mod_constants.LOGGER

-- ------------------------------ Module Start ------------------------------ --

local blacklists = {}
--- @type { index: table<string, int>, values: table<int, string> }
blacklists.part_whitelist = { index = table.newarray({}), values = table.newarray({}) }
--- @type { index: table<string, int>, values: table<int, string> }
blacklists.pinkslip_blacklist = { index = table.newarray({}), values = table.newarray({}) }
--- @type { index: table<string, int>, values: table<int, string> }
blacklists.trailer_blacklist = { index = table.newarray({}), values = table.newarray({}) }
--- @type { index: table<string, int>, values: table<int, string> }
blacklists.vehicle_blacklist = { index = table.newarray({}), values = table.newarray({}) }
--- @type table<int, string>
blacklists.known_trailers = { "trailer", "trailerTruck" }

function blacklists.init()
    logger:debug_server("Parsing blacklists from SandboxVars.")

    local sbvars = SandboxVars[mod_constants.MOD_ID]
    --- @cast sbvars SandboxVarsDummy

    -- Part Whitelist
    if #sbvars.PartWhitelist > 0 then
        local temp = sbvars.PartWhitelist:split(";")
        for i = 1, #temp do
            local full_name = temp[i]

            blacklists.part_whitelist.index[i] = i
            blacklists.part_whitelist.values[i] = full_name
        end
    end

    -- Vehicle Blacklist
    if #sbvars.VehicleBlacklist > 0 then
        local temp = sbvars.VehicleBlacklist:split(";")
        for i = 1, #temp do
            local full_name = temp[i]

            blacklists.vehicle_blacklist.index[i] = i
            blacklists.vehicle_blacklist.values[i] = full_name
        end
    end

    -- Trailer Blacklist
    if #sbvars.TrailerBlacklist > 0 then
        local temp = sbvars.TrailerBlacklist:split(";")
        for i = 1, #temp do
            local full_name = temp[i]

            blacklists.trailer_blacklist.index[i] = i
            blacklists.trailer_blacklist.values[i] = full_name
        end
    end

    if sbvars.DoPinkslipLoot or sbvars.DoZedLoot then
        -- Loot Blacklist
        if sbvars.PinkslipLootBlacklist ~= "" then
            local temp = sbvars.PinkslipLootBlacklist:split(";")
            for i = 1, #temp do
                local full_name = temp[i]

                blacklists.pinkslip_blacklist.index[i] = i
                blacklists.pinkslip_blacklist.values[i] = full_name
            end
        end
    end

    logger:debug_server("Finished parsing blacklists.")
end

return blacklists
