-- -------------------------------------------------------------------------- --
--                       Sandbox Options Blacklist Stuff                      --
-- -------------------------------------------------------------------------- --

-- AoqiaCarwannaExtended requires.
local mod_constants = require("AoqiaCarwannaExtendedShared/mod_constants")

-- TIS globals cache.
local getScriptManager = getScriptManager
local Recipe = Recipe

local logger = mod_constants.LOGGER

-- ------------------------------ Module Start ------------------------------ --

local recipes = { can_perform = {}, on_create = {}, item_types = {} }

--- @param script_items ArrayList<Item>
function recipes.item_types.pinkslip(script_items)
    local script_manager = getScriptManager()
    --- @diagnostic disable-next-line
    script_items:addAll(script_manager:getItemsTag("Pinkslip"))
end

--- @type Recipe_OnCanPerform
function recipes.can_perform.claim_vehicle(recipe, character, item)
    local square = getCell():getGridSquare(character:getX(), character:getY(), character:getZ())

    if  character:isOutside()
    and character:getZ() == 0
    and square:isVehicleIntersecting() == false then
        return true
    end

    return false
end

--- @type Recipe_OnCreate
function recipes.on_create.claim_vehicle(
    sources,
    result,
    character,
    item,
    isPrimaryHandItem,
    isSecondaryHandItem)
    --- @diagnostic disable-next-line
    local pinkslip = sources:get(1 - 1) --[[@as InventoryItem]]

    if character:isOutside() == false or character:getZ() > 0 then
        character:Say("I think this will work better on the ground if I go outside...")
        --- @diagnostic disable-next-line
        character:getInventory():AddItem(pinkslip)
        return
    end

    local mdata = pinkslip:getModData() --[[@as ModDataDummy]]

    -- The vehicle that is being requested by the player.
    local vehicle = { Type = mdata.VehicleId }
    if mdata.Parts then
        -- Player-created pinkslip branch.
        vehicle.parts = mdata.Parts
    else
        -- Premade pinkslip branch.
        -- NOTE: Previous code did type checks like type(mdata.val) == "number"
        -- TODO: It's really ugly, maybe we just loop mod table in mdata.
        if mdata.Battery then vehicle.Battery = mdata.Battery end
        if mdata.Condition then vehicle.Condition = mdata.Condition end
        if mdata.EngineQuality then vehicle.EngineQuality = mdata.EngineQuality end
        if mdata.GasTank then vehicle.GasTank = mdata.GasTank end
        if mdata.HasKey then vehicle.HasKey = mdata.HasKey end
        if mdata.Hotwire then vehicle.Hotwire = true end
        if mdata.OtherTank then vehicle.OtherTank = mdata.OtherTank end
        if mdata.Rust then vehicle.Rust = mdata.Rust end
        if mdata.Skin then vehicle.Skin = mdata.Skin end
        if mdata.TirePsi then vehicle.TirePsi = mdata.TirePsi end
        if mdata.Upgrade then vehicle.Upgrade = true end
    end

    -- Transfer blood on parts if mod data has it.
    if mdata.Blood then
        vehicle.Blood.F = mdata.Blood.F
        vehicle.Blood.B = mdata.Blood.B
        vehicle.Blood.L = mdata.Blood.L
        vehicle.Blood.R = mdata.Blood.R
    end

    -- Transfer colours if the mod data has it.
    if mdata.Color then
        vehicle.Color.H = mdata.Color.H
        vehicle.Color.S = mdata.Color.S
        vehicle.Color.V = mdata.Color.V
    end

    vehicle.X = character:getX()
    vehicle.Y = character:getY()
    -- vehicle.z = character:getZ()
    vehicle.Dir = character:getDir()
    vehicle.Clear = true

    sendClientCommand(character, mod_constants.MOD_ID, "spawn_vehicle", vehicle)
end

-- Add all above to global namespace (required by recipes)
Recipe.OnCanPerform[mod_constants.MOD_ID] = { ClaimVehicle = recipes.can_perform.claim_vehicle }
Recipe.OnCreate[mod_constants.MOD_ID] = { ClaimVehicle = recipes.on_create.claim_vehicle }
Recipe.GetItemTypes[mod_constants.MOD_ID] = { Pinkslip = recipes.item_types.pinkslip }

return recipes
