-- -------------------------------------------------------------------------- --
--                       Sandbox Options Blacklist Stuff                      --
-- -------------------------------------------------------------------------- --

-- AoqiaCarwannaExtended requires.
local distributions = require("AoqiaCarwannaExtended/distributions")
local mod_constants = require("AoqiaCarwannaExtended/mod_constants")

-- std globals
local string = string
-- TIS globals cache.
local getScriptManager = getScriptManager
local instanceItem = instanceItem
local SandboxVars = SandboxVars

local logger = mod_constants.LOGGER

-- ------------------------------ Module Start ------------------------------ --

local blacklists = {}
--- @type table<integer, table<string, boolean>>
blacklists.loot_blacklist = {}
--- @type table<integer, table<string, boolean>>
blacklists.part_whitelist = {}
--- @type table<integer, table<string, boolean>>
blacklists.trailer_blacklist = {}
--- @type table<integer, table<string, boolean>>
blacklists.vehicle_blacklist = {}

function blacklists.init()
    logger:debug("Parsing blacklists from SandboxVars.")

    local sbvars = SandboxVars[mod_constants.MOD_ID]
    --- @cast sbvars SandboxVarsDummy

    -- Part Whitelist
    if #sbvars.PartWhitelist > 0 then
        -- FIXME: Fix your fucking shit and stop using string
        -- FIXME: Don't use ipairs here as it's slow as BRICKS
        local temp = string.split(sbvars.PartWhitelist, ";")
        for i = 1, #temp do
            blacklists.part_whitelist[i] = { temp[i], true }
        end
    end

    -- Vehicle Blacklist
    if #sbvars.VehicleBlacklist > 0 then
        -- FIXME: Fix your fucking shit and stop using string
        -- FIXME: Don't use ipairs here as it's slow as BRICKS
        local temp = string.split(sbvars.VehicleBlacklist, ";")
        for i = 1, #temp do
            blacklists.vehicle_blacklist[i] = { temp[i], true }
        end
    end

    -- Trailer Blacklist
    if #sbvars.TrailerBlacklist > 0 then
        -- FIXME: Fix your fucking shit and stop using string
        -- FIXME: Don't use ipairs here as it's slow as BRICKS
        local temp = string.split(sbvars.TrailerBlacklist, ";")
        for i = 1, #temp do
            blacklists.trailer_blacklist[i] = { temp[i], true }
        end
    end

    if sbvars.DoRequiresForm and sbvars.DoFormLoot then
        distributions.add_autoform()
    end

    if sbvars.DoLootTables or sbvars.DoZedLoot then
        distributions.add_pinkslip()

        -- Loot Blacklist
        if #sbvars.LootBlacklist > 0 then
            -- FIXME: Fix your fucking shit and stop using string
            -- FIXME: Don't use ipairs here as it's slow as BRICKS
            local temp = string.split(sbvars.LootBlacklist, ";")
            for i = 1, #temp do
                blacklists.loot_blacklist[i] = { temp[i], true }
            end
        end

        local items = getAllItems()
        for i = 1, items:size() do
            local item = items:get(i - 1) --[[@as Item]]
            if item:getModuleName() ~= "PinkSlip" then return end

            local item_name = item:getFullName()
            if blacklists.loot_blacklist[item_name] == nil then
                local script_manager = getScriptManager()

                local script_item = instanceItem(item_name)
                local mdata = script_item:getModData() --[[@as ModDataDummy]]

                local vehicle = script_manager:getVehicle(mdata.VehicleId)
                if vehicle and mdata.IsBlacklisted == false then
                    distributions.add_pinkslip_vehicle(item_name, mdata.LootChance or 1)
                    distributions.add_pinkslip_zombie(item_name)
                else
                    logger:info_server("Item " ..
                        item_name .. " was blacklisted or the vehicleid is invalid.")
                end
            end
        end
    end

    -- NOTE: Shouldn't need to reload the tables.
    -- ItemPickerJava.Parse()
end

return blacklists
