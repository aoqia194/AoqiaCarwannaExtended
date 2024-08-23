-- -------------------------------------------------------------------------- --
--             Handles the procedural distributions (loot tables)             --
-- -------------------------------------------------------------------------- --

-- This mod requires
local constants = require("AoqiaZomboidUtilsShared/constants")
local mod_constants = require("AoqiaCarwannaExtendedShared/mod_constants")

-- STDLIB globals cache.
local table = table
-- TIS globals cache.
local ProceduralDistributions = ProceduralDistributions
local SandboxVars = SandboxVars
local SuburbsDistributions = SuburbsDistributions

local logger = mod_constants.LOGGER

-- ------------------------------ Module Start ------------------------------ --

local distributions = {}

--- @class DistributionsTableDummy
--- @field containers string[]
--- @field items table<{ ["item"]: string, ["chance"]: float }>
distributions.DistributionsTableDummy = {}

--- @class ProcListDummy
--- @field min integer
--- @field max integer
--- @field name string
--- @field weightChance float
distributions.ProcListDummy = {}

--- Registers a table of suburb locations into the loot table.
--- @param tbl { [string]: string[] }
--- @param proclist ProcListDummy
function distributions.register_suburbs(tbl, proclist)
    for location, containers in pairs(tbl) do
        for i = 1, #containers do
            local container = containers[i]
            table.insert(SuburbsDistributions[location][container].procList, proclist)
        end
    end
end

--- Registers a table of items into the loot table.
--- @param tbl DistributionsTableDummy
function distributions.register_procedural(tbl)
    for i = 1, #tbl.containers do
        local container = tbl.containers[i]

        for k, v in pairs(tbl.items) do
            if k == "item" then
                v = (mod_constants.MOD_ID .. v)
            end

            table.insert(ProceduralDistributions.list[container].items, v)
        end
    end
end

--- Adds the AutoForm item to the ProceduralDistributions.
function distributions.add_autoform()
    logger:debug_server("Adding AutoForm item to loot tables.")

    local sbvars = SandboxVars[mod_constants.MOD_ID] --[[@as SandboxVarsDummy]]

    local tbl = {
        containers = { "OfficeDesk", "PoliceDesk" },
        items = { { ["item"] = "AutoForm", ["chance"] = sbvars.FormLootChance } },
    }
    distributions.register_procedural(tbl)
end

--- Adds the PinkSlip item to the loot table inside a vehicle.
--- @param item_name string
--- @param chance float
function distributions.add_pinkslip_vehicle(item_name, chance)
    local sbvars = SandboxVars[mod_constants.MOD_ID] --[[@as SandboxVarsDummy]]

    if sbvars.DoFormLoot == false then return end

    local tbl = {
        containers = { "pinkslips" },
        items = { { ["item"] = item_name, ["chance"] = chance } },
    }
    distributions.register_procedural(tbl)
end

--- Adds the PinkSlip item to the loot table in a zombie.
--- @param item_name string
function distributions.add_pinkslip_zombie(item_name)
    local sbvars = SandboxVars[mod_constants.MOD_ID] --[[@as SandboxVarsDummy]]

    if sbvars.DoZedLoot == false then return end

    table.insert(SuburbsDistributions.all.Outfit_Mechanic.items, item_name)
    table.insert(SuburbsDistributions.all.Outfit_Mechanic.items, sbvars.ZedLootChance)
end

--- Adds the PinkSlip item to the SuburbsDistributions.
function distributions.add_pinkslip()
    logger:debug_server("Adding Pinkslip item to loot tables.")

    local sbvars = SandboxVars[mod_constants.MOD_ID] --[[@as SandboxVarsDummy]]
    local dummy = { rolls = 1, items = {}, junk = { rolls = 1, items = {} } }
    
    if sbvars.DoZedLoot then
        SuburbsDistributions.all.Outfit_Mechanic = SuburbsDistributions.all.Outfit_Mechanic or dummy
    end

    -- TODO: I think this isn't the way to do it. Maybe do it like add_pinkslip_zombie.
    local proclist = { name = "pinkslips", min = 0, max = 1, weightChance = sbvars.LootChance }
    local tbl = {
        mechanic = { "crate", "metal_shelves" },
        pawnshop = { "counter", "displaycase" },
        policestorage = { "counter", "crate", "locker", "metal_shelves" },
    }
    distributions.register_suburbs(tbl, proclist)
end

return distributions
