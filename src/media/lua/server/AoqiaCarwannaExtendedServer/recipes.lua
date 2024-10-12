-- -------------------------------------------------------------------------- --
--                       Sandbox Options Blacklist Stuff                      --
-- -------------------------------------------------------------------------- --

-- AoqiaCarwannaExtended requires.
local blacklist = require("AoqiaCarwannaExtendedShared/blacklists")
local mod_constants = require("AoqiaCarwannaExtendedShared/mod_constants")

-- std globals.
local assert = assert

-- TIS globals cache.
local getAllVehicles = getAllVehicles
local getScriptManager = getScriptManager
local getSquare = getSquare
local Recipe = Recipe
local sendClientCommand = sendClientCommand
local ZombRand = ZombRand

local logger = mod_constants.LOGGER

-- ------------------------------ Module Start ------------------------------ --

local recipes = {}

Recipe.GetItemTypes[mod_constants.MOD_ID] = {}
Recipe.OnCanPerform[mod_constants.MOD_ID] = {}
Recipe.OnCreate[mod_constants.MOD_ID] = {}

--- @param script_items ArrayList<Item>
Recipe.GetItemTypes[mod_constants.MOD_ID].Pinkslip = function (script_items)
    local script_manager = getScriptManager()
    --- @diagnostic disable-next-line
    script_items:addAll(script_manager:getItemsTag("Pinkslip"))
end

--- @type Recipe_OnCanPerform
Recipe.OnCanPerform[mod_constants.MOD_ID].ClaimVehicle = function (recipe, character, item)
    local square = getSquare(character:getX(), character:getY(), character:getZ())

    if  character:isOutside()
    and character:getZ() == 0
    and square:isVehicleIntersecting() == false then
        return true
    end

    return false
end

--- @type Recipe_OnCreate
Recipe.OnCreate[mod_constants.MOD_ID].ClaimVehicle = function (
    sources,
    result,
    character,
    item,
    isPrimaryHandItem,
    isSecondaryHandItem)
    --- @cast character IsoPlayer

    local sbvars = SandboxVars[mod_constants.MOD_ID] --[[@as SandboxVarsDummy]]

    --- @diagnostic disable-next-line: undefined-field
    local pinkslip = sources:get(1 - 1) --[[@as InventoryItem]]

    local mdata = pinkslip:getModData() --[[@as ModDataDummy]]
    local args = {} --[[@as ModDataDummy]] --- @diagnostic disable-line

    -- If there are no parts, it means the pinkslip isn't player-made.
    -- We have to handle it differently because it will not have stored any proper data for parts.
    if mdata.Parts == nil then
        if sbvars.DoAllowGeneratedPinkslips == false then
            character:setHaloNote(
                getText(("IGUI_%s_HaloNote_NoGeneratedPinkslips")
                    :format(mod_constants.MOD_ID)))

            return
        end

        -- Get a random vehicle for the pinkslip that isn't blacklisted.
        local vehicle_names = getAllVehicles()
        local vehicle_name = nil

        local count = 1
        while true do
            if count >= 60 then
                logger:error("Unable to select random vehicle due to timeout.")
                return
            end

            vehicle_name = vehicle_names:get(ZombRand(0, vehicle_names:size() - 1)) --[[@as string]]
            local name_lower = vehicle_name:lower()
            logger:debug("Selecting random vehicle (%s).", vehicle_name)

            -- If vehicle not blacklisted, trailer, burnt, or smashed.
            if  blacklist.vehicle_blacklist.index[vehicle_name] == nil
            and name_lower:contains("trailer") == false
            and name_lower:contains("burnt") == false
            and name_lower:contains("smashed") == false then
                logger:debug("Random vehicle selected.")
                break
            end

            count = count + 1
        end
        assert(vehicle_name, "No vehicle found when trying to claim random vehicle from pinkslip.")

        args.Id = vehicle_name
    else
        args.Parts = mdata.Parts
        args.Id = mdata.Id
    end

    -- Set general vehicle properties.

    if mdata.EngineLoudness then args.EngineLoudness = mdata.EngineLoudness end
    if mdata.EnginePower then args.EnginePower = mdata.EnginePower end
    if mdata.EngineQuality then args.EngineQuality = mdata.EngineQuality end
    if mdata.HasKey then args.HasKey = true end
    if mdata.MakeKey then args.MakeKey = true end
    if mdata.HeadlightsActive then args.HeadlightsActive = true end
    if mdata.HeaterActive then args.HeaterActive = true end
    if mdata.Hotwired then args.Hotwired = true end
    if mdata.Rust then args.Rust = mdata.Rust end
    if mdata.Skin then args.Skin = mdata.Skin end

    if mdata.Blood then
        args.Blood = { F = mdata.Blood.F, B = mdata.Blood.B, L = mdata.Blood.L, R = mdata.Blood.R }
    end

    if mdata.Color then
        args.Color = { H = mdata.Color.H, S = mdata.Color.S, V = mdata.Color.V }
    end

    args.X = character:getX()
    args.Y = character:getY()
    args.Z = character:getZ()
    args.Dir = character:getDir()

    sendClientCommand(character, mod_constants.MOD_ID, "spawn_vehicle", args)
end

return recipes
