-- -------------------------------------------------------------------------- --
--                       Sandbox Options Blacklist Stuff                      --
-- -------------------------------------------------------------------------- --

-- AoqiaCarwannaExtended requires.
local mod_constants = require("AoqiaCarwannaExtended/mod_constants")

-- TIS globals cache.
local getScriptManager = getScriptManager

local logger = mod_constants.LOGGER

-- ------------------------------ Module Start ------------------------------ --

local recipes = {}
recipes.can_perform = {}
recipes.on_create = {}
recipes.item_types = {}

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
    local vehicle = { type = mdata.VehicleId }
    if mdata.Parts then
        -- Player-created pinkslip branch.
        vehicle.parts = mdata.Parts
    else
        -- Premade pinkslip branch.
        -- NOTE: Previous code did type checks like type(mdata.val) == "number"
        -- TODO: It's really ugly, maybe we just loop mod table in mdata.
        if mdata.Battery then vehicle.battery = mdata.Battery end
        if mdata.Condition then vehicle.condition = mdata.Condition end
        if mdata.EngineQuality then vehicle.enginequality = mdata.EngineQuality end
        if mdata.GasTank then vehicle.gastank = mdata.GasTank end
        if mdata.HasKey then vehicle.haskey = mdata.HasKey end
        if mdata.Hotwire then vehicle.hotwire = true end
        if mdata.OtherTank then vehicle.othertank = mdata.OtherTank end
        if mdata.Rust then vehicle.rust = mdata.Rust end
        if mdata.Skin then vehicle.skin = mdata.Skin end
        if mdata.TirePsi then vehicle.tirepsi = mdata.TirePsi end
        if mdata.Upgrade then vehicle.upgrade = true end
    end

    -- Transfer blood on parts if mod data has it.
    if mdata.Blood then
        vehicle.blood.f = mdata.Blood.F
        vehicle.blood.b = mdata.Blood.B
        vehicle.blood.l = mdata.Blood.L
        vehicle.blood.r = mdata.Blood.R
    end

    -- Transfer colours if the mod data has it.
    if mdata.Color then
        vehicle.color.h = mdata.Color.H
        vehicle.color.s = mdata.Color.S
        vehicle.color.v = mdata.Color.V
    end

    vehicle.x = character:getX()
    vehicle.y = character:getY()
    -- vehicle.z = character:getZ()
    vehicle.dir = character:getDir()
    vehicle.clear = true

    sendClientCommand(character, mod_constants.MOD_ID, "spawn_vehicle", vehicle)
end

-- Add all above to global namespace (required by recipes)
Recipe.OnCanPerform.ClaimVehicle = recipes.can_perform.claim_vehicle
Recipe.OnCreate.ClaimVehicle = recipes.on_create.claim_vehicle
Recipe.GetItemTypes.Pinkslip = recipes.item_types.pinkslip

return recipes
