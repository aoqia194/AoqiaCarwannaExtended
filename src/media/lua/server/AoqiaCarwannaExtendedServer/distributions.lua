-- -------------------------------------------------------------------------- --
--             Handles the procedural distributions (loot tables)             --
-- -------------------------------------------------------------------------- --

-- This mod requires
local mod_constants = require("AoqiaCarwannaExtendedShared/mod_constants")

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
--- @param tbl table<string, table<int, string>>
--- @param proclist ProcListDummy
function distributions.register_suburbs(tbl, proclist)
    for i = 1, #tbl[1] do
        local location = tbl[1][i]

        for j = 1, #tbl[2] do
            local container = tbl[2][j]

            local dist_cont = SuburbsDistributions[location][container]
            if dist_cont == nil then
                dist_cont = { procList = {}, procedural = true }
            end

            local list = dist_cont.procList
            list[#list + 1] = proclist
        end
    end
end

--- Registers a table of items into the loot table.
--- @param tbl DistributionsTableDummy
function distributions.register_procedural(tbl)
    for i = 1, #tbl.containers do
        local container = tbl.containers[i]

        for j = 1, #tbl.items do
            local item = tbl.items[j]
            local item_name = item[1]
            local item_chance = item[2]

            -- NOTE: I hate this.
            local cont = ProceduralDistributions.list[container]
            if cont == nil then
                cont = { items = {} }
            end

            local items = cont.items
            items[#items + 1] = (mod_constants.MOD_ID .. "." .. item_name)
            items[#items + 1] = item_chance
        end
    end
end

--- Adds the AutoForm item to the ProceduralDistributions.
function distributions.add_autoform()
    logger:debug_server("Adding AutoForm item to loot tables.")

    local sbvars = SandboxVars[mod_constants.MOD_ID] --[[@as SandboxVarsDummy]]

    local tbl = {
        containers = { "OfficeDesk", "PoliceDesk", "Pinkslips" },
        items = { { mod_constants.MOD_ID .. ".AutoForm", sbvars.AutoFormLootChance } },
    }

    distributions.register_procedural(tbl)
end

--- Adds the PinkSlip item to the loot table in a zombie.
--- @param item_name string
function distributions.add_pinkslip_zombie(item_name)
    local sbvars = SandboxVars[mod_constants.MOD_ID] --[[@as SandboxVarsDummy]]
    if sbvars.DoZedLoot == false then return end

    --- @diagnostic disable: assign-type-mismatch
    local items = SuburbsDistributions.all.Outfit_Mechanic.items
    items[#items + 1] = item_name
    items[#items + 1] = sbvars.ZedLootChance
    --- @diagnostic enable: assign-type-mismatch
end

--- Adds the PinkSlip item to the SuburbsDistributions.
function distributions.add_pinkslip()
    logger:debug_server("Adding Pinkslip item to loot tables.")

    local sbvars = SandboxVars[mod_constants.MOD_ID] --[[@as SandboxVarsDummy]]
    local dummy = { rolls = 1, items = {}, junk = { rolls = 1, items = {} } }

    if sbvars.DoZedLoot then
        SuburbsDistributions.all.Outfit_Mechanic = SuburbsDistributions.all.Outfit_Mechanic or dummy
    end

    local proclist = { name = "pinkslips", min = 0, max = 1, weightChance = sbvars.PinkslipLootChance }
    local tbl = {
        { "mechanic", "pawnshop", "policestorage" },
        {
            { "crate",   "metal_shelves" },
            { "counter", "displaycase" },
            { "counter", "crate",        "locker", "metal_shelves" },
        },
    }

    distributions.register_suburbs(tbl, proclist)
end

function distributions.init()
    logger:debug_server("Parsing distributions...")

    local sbvars = SandboxVars[mod_constants.MOD_ID] --[[@as SandboxVarsDummy]]

    if sbvars.DoAutoFormLoot and sbvars.DoRequiresForm then
        distributions.add_autoform()
    end

    if sbvars.DoPinkslipLoot or sbvars.DoZedLoot then
        distributions.add_pinkslip()
    end

    logger:debug_server("Finished parsing distributions. Reparsing loot tables...")
    ItemPickerJava.Parse()
end

return distributions
