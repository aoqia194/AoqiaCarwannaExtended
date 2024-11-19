-- -------------------------------------------------------------------------- --
--                       Sandbox Options Blacklist Stuff                      --
-- -------------------------------------------------------------------------- --

-- AoqiaCarwannaExtended requires.
local mod_constants = require("AoqiaCarwannaExtendedShared/mod_constants")

-- std globals
local table = table
-- TIS globals cache.
local SandboxVars = SandboxVars

local logger = mod_constants.LOGGER

-- ------------------------------ Module Start ------------------------------ --

local sandbox_data = {}

--- @type { index: table<string, int>, values: table<int, string> }
sandbox_data.part_whitelist = { index = {}, values = table.newarray({}) }
--- @type { index: table<string, int>, values: table<int, string> }
sandbox_data.trailer_blacklist = { index = {}, values = table.newarray({}) }
--- @type { index: table<string, int>, values: table<int, string> }
sandbox_data.vehicle_blacklist = { index = {}, values = table.newarray({}) }
--- @type { index: table<string, int>, values: table<int, string> }
sandbox_data.pinkslip_blacklist = { index = {}, values = table.newarray({}) }
--- @type { index: table<string, int>, values: table<int, { type: string, chance: int }> }
sandbox_data.pinkslip_chances = { index = {}, values = table.newarray({}) }

--- @type table<int, string>
sandbox_data.known_trailers = { "trailer", "trailerTruck" }

--- Sadly this needs to be done in shared (which means clients run it too)
--- so that both servers and clients can access the parsed tables.
function sandbox_data.init()
    logger:debug_shared("Parsing blacklists from SandboxVars.")

    local sbvars = SandboxVars[mod_constants.MOD_ID]
    --- @cast sbvars SandboxVarsDummy

    -- Part Whitelist
    if #sbvars.PartWhitelist > 0 then
        logger:debug_shared("Parsing part whitelist.")

        local temp = sbvars.PartWhitelist:split(";")
        for i = 1, #temp do
            local full_name = temp[i]

            sandbox_data.part_whitelist.index[full_name] = i
            sandbox_data.part_whitelist.values[i] = full_name
        end
    end

    -- Vehicle Blacklist
    if #sbvars.VehicleBlacklist > 0 then
        logger:debug_shared("Parsing vehicle blacklist.")

        local temp = sbvars.VehicleBlacklist:split(";")
        for i = 1, #temp do
            local full_name = temp[i]

            sandbox_data.vehicle_blacklist.index[full_name] = i
            sandbox_data.vehicle_blacklist.values[i] = full_name
        end
    end

    -- Trailer Blacklist
    if #sbvars.TrailerBlacklist > 0 then
        logger:debug_shared("Parsing trailer blacklist.")

        local temp = sbvars.TrailerBlacklist:split(";")
        for i = 1, #temp do
            local full_name = temp[i]

            sandbox_data.trailer_blacklist.index[full_name] = i
            sandbox_data.trailer_blacklist.values[i] = full_name
        end
    end

    -- Loot Blacklist
    if (sbvars.DoPinkslipLoot or sbvars.DoZedLoot) and #sbvars.PinkslipGeneratedBlacklist > 0 then
        logger:debug_shared("Parsing pinkslip loot blacklist.")

        local temp = sbvars.PinkslipGeneratedBlacklist:split(";")
        for i = 1, #temp do
            local full_name = temp[i]

            sandbox_data.pinkslip_blacklist.index[full_name] = i
            sandbox_data.pinkslip_blacklist.values[i] = full_name
        end
    end

    if sbvars.DoAllowGeneratedPinkslips and #sbvars.PinkslipGeneratedChances > 0 then
        logger:debug_shared("Parsing generated pinkslip weights.")

        local pinkslip_weights = sbvars.PinkslipGeneratedChances
        local temp = pinkslip_weights:split(";")
        for i = 1, #temp do
            local entry = temp[i]

            local temp2 = entry:split("=")
            local full_name = temp2[1]
            local chance = tonumber(temp2[2])
            if full_name == nil or chance == nil then
                logger:error_shared("Failed to init generated pinkslip weights.")
                return
            end

            sandbox_data.pinkslip_chances.index[full_name] = i
            sandbox_data.pinkslip_chances.values[i] = { type = full_name, chance = chance }
        end
    end

    logger:debug_shared("Finished parsing blacklists.")
end

return sandbox_data
