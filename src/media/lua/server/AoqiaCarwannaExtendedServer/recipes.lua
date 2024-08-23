-- -------------------------------------------------------------------------- --
--                       Sandbox Options Blacklist Stuff                      --
-- -------------------------------------------------------------------------- --

-- AoqiaCarwannaExtended requires.
local mod_constants = require("AoqiaCarwannaExtendedShared/mod_constants")

-- TIS globals cache.
local getCell = getCell
local getScriptManager = getScriptManager
local Recipe = Recipe
local sendClientCommand = sendClientCommand

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
    local args = { VehicleId = mdata.VehicleId }
    if mdata.Parts then
        -- Player-created pinkslip branch.
        args.parts = mdata.Parts
    else
        -- Premade pinkslip branch.
        if mdata.Battery then args.Battery = mdata.Battery end
        if mdata.Condition then args.Condition = mdata.Condition end
        if mdata.EngineLoudness then args.EngineLoudness = mdata.EngineLoudness end
        if mdata.EnginePower then args.EnginePower = mdata.EnginePower end
        if mdata.EngineQuality then args.EngineQuality = mdata.EngineQuality end
        if mdata.GasTank then args.GasTank = mdata.GasTank end
        if mdata.HasKey then args.HasKey = true end
        if mdata.MakeKey then args.MakeKey = true end
        if mdata.HeadlightsActive then args.HeadlightsActive = true end
        if mdata.HeaterActive then args.HeaterActive = true end
        if mdata.Hotwire then args.Hotwire = true end
        if mdata.LockedDoor then args.LockedDoor = true end
        if mdata.LockedTrunk then args.LockedTrunk = true end
        if mdata.OtherTank then args.OtherTank = mdata.OtherTank or mdata.FuelTank end
        if mdata.Rust then args.Rust = mdata.Rust end
        if mdata.Skin then args.Skin = mdata.Skin end
        if mdata.TirePsi then args.TirePsi = mdata.TirePsi end
        if mdata.Upgrade then args.Upgrade = true end
    end

    -- Transfer blood on partst.
    if mdata.Blood then
        args.Blood = args.Blood or {}
        args.Blood.F = mdata.Blood.F
        args.Blood.B = mdata.Blood.B
        args.Blood.L = mdata.Blood.L
        args.Blood.R = mdata.Blood.R
    end

    -- Transfer colours.
    if mdata.Color then
        args.Color = args.Color or {}
        args.Color.H = mdata.Color.H
        args.Color.S = mdata.Color.S
        args.Color.V = mdata.Color.V
    end

    args.X = character:getX()
    args.Y = character:getY()
    args.Z = character:getZ()

    args.Dir = character:getDir()
    args.Clear = true

    sendClientCommand(character, mod_constants.MOD_ID, "spawn_vehicle", args)
end

-- Add all above to global namespace (required by recipes)
Recipe.OnCanPerform[mod_constants.MOD_ID] = { ClaimVehicle = recipes.can_perform.claim_vehicle }
Recipe.OnCreate[mod_constants.MOD_ID] = { ClaimVehicle = recipes.on_create.claim_vehicle }
Recipe.GetItemTypes[mod_constants.MOD_ID] = { Pinkslip = recipes.item_types.pinkslip }

return recipes
