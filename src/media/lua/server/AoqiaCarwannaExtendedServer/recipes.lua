local aoqia_table = require("AoqiaZomboidUtilsShared/table")
local constants = require("AoqiaZomboidUtilsShared/constants")
local mod_constants = require("AoqiaCarwannaExtendedShared/mod_constants")
local sandbox_data = require("AoqiaCarwannaExtendedShared/sandbox_data")

-- std globals.
local assert = assert

-- TIS globals cache.
local getAllVehicles = getAllVehicles
local getScriptManager = getScriptManager
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
    script_items:addAll(script_manager:getItemsByType("Pinkslip"))
end

--- @type Recipe_OnCanPerform
Recipe.OnCanPerform[mod_constants.MOD_ID].ClaimVehicle = function (recipe, player, item)
    --- @cast player IsoPlayer
    if player:getZ() > 0 then
        player:setHaloNote(
            getText(("IGUI_%s_HaloNote_NotOnGround"):format(mod_constants.MOD_ID)),
            255.0,
            0.0,
            0.0,
            (128.0 * 2)) --- @diagnostic disable-line: redundant-parameter

        logger:debug_server("Failed to spawn vehicle as the player is above Z level 0.")
        return false
    end

    -- If the item is nil. it means that crafting menu is checking it.
    -- if item == nil then return false end

    local sbvars = SandboxVars[mod_constants.MOD_ID] --[[@as SandboxVarsDummy]]

    local perform = true

    -- If the player is not outside, don't claim it.
    local player_sq = player:getSquare()
    if player:isOutside() == false then
        player:setHaloNote(getText(("IGUI_%s_HaloNote_NotOutside"):format(mod_constants.MOD_ID)),
            255.0,
            0.0,
            0.0,
            (128.0 * 2)) --- @diagnostic disable-line: redundant-parameter
        logger:debug_server("Failed to spawn vehicle as the player is not outside.")
        perform = false
    end

    if player_sq:isVehicleIntersecting() then
        player:setHaloNote(
            getText(("IGUI_%s_HaloNote_VehicleIntersecting"):format(mod_constants.MOD_ID)),
            255.0,
            0.0,
            0.0,
            (128.0 * 2)) --- @diagnostic disable-line: redundant-parameter
        logger:debug_server(
            "Failed to spawn vehicle as the player is intersecting with another vehicle.")
        perform = false
    end

    if perform and sbvars.DoParkingMeterOnly then
        local found_meter = false

        local sq = player:getSquare()
        local sq_x = sq:getX()
        local sq_y = sq:getY()

        local dist = math.ceil(sbvars.ParkingMeterDistance / 2)
        for x = sq_x - dist, sq_x + dist do
            for y = sq_y - dist, sq_y + dist do
                repeat
                    local s = getSquare(x, y, 0)
                    if s == nil then break end

                    local s_objs = s:getObjects()
                    for i = 1, s_objs:size() do
                        local obj = s_objs:get(i - 1) --[[@as IsoObject]]
                        local obj_name = obj:getSprite():getName()
                        if obj_name == "f_parkingmeters_01_0"
                        or obj_name == "f_parkingmeters_01_1"
                        or obj_name == "f_parkingmeters_01_2"
                        or obj_name == "f_parkingmeters_01_3"
                        or obj_name == "f_parkingmeters_01_4"
                        or obj_name == "f_parkingmeters_01_5"
                        or obj_name == "f_parkingmeters_01_6"
                        or obj_name == "f_parkingmeters_01_7" then
                            found_meter = true
                            break
                        end
                    end
                until true
            end

            if found_meter then break end
        end

        if found_meter == false then
            player:setHaloNote(
                getText(("Tooltip_%s_NoParkingMeterFound"):format(mod_constants.MOD_ID)),
                255.0, 0.0, 0.0,
                (128.0 * 2)) --- @diagnostic disable-line: redundant-parameter
            logger:debug_server(
                "Failed to spawn vehicle as the player is not in range of a parking meter.")
            perform = false
        end
    end

    -- If we need to be in a safehouse to spawn the vehicle.
    if perform and constants.IS_SINGLEPLAYER == false and sbvars.DoSafehouseOnly then
        local username = player:getUsername()

        local player_sq_x = player_sq:getX()
        local player_sq_y = player_sq:getY()

        -- Dist from `player_sq` to `sq`.
        local sq_dist = nil
        -- Safehouse middle square area.
        local sq_x = nil
        local sq_y = nil
        local sq_x2 = nil
        local sq_y2 = nil

        -- Loop through the safehouses and get the closest one.
        local safehouses = SafeHouse.getSafehouseList()
        for i = 1, safehouses:size() do
            repeat
                local temp = safehouses:get(i - 1) --[[@as SafeHouse | nil]]
                if temp == nil then
                    logger:error(
                        "Safehouse was nil while looping through the safehouse list.")
                    break
                end

                -- Get the closest safehouse recursively.
                if temp:playerAllowed(username) then
                    local x = temp:getX()
                    local y = temp:getY()
                    local w = temp:getW()
                    local h = temp:getH()
                    local x2 = temp:getX2()
                    local y2 = temp:getY2()

                    -- local center = getSquare(math.max(0, x2 - (x2 - x)), math.max(0, y2 - (y2 - y)),
                    --     0)
                    -- if center == nil then
                    --     logger:debug(
                    --         "Failed to get safehouse square because the chunk isn't loaded. Assuming that the player is not near their safehouse.")
                    --     break
                    -- end

                    -- If distance is shorter, update the tracked `sq` and it's data.
                    --- @diagnostic disable: redundant-parameter
                    local dist = player_sq:DistTo(
                        math.max(0, (x + (w / 2))),
                        math.max(0, (y + (h / 2))))
                    --- @diagnostic enable: redundant-parameter
                    if sq_dist == nil or dist < sq_dist then
                        sq_dist = dist
                        sq_x = x
                        sq_y = y
                        sq_x2 = x2
                        sq_y2 = y2
                    end
                end
            until true
        end

        if sq_dist == nil then
            logger:debug_server("sq_dist was nil, even after safehouse loop.")
        end

        -- Is the player in the safehouse area?
        local in_safehouse_area = sq_dist and
            (player_sq_x >= sq_x and player_sq_x <= sq_x2) and
            (player_sq_y >= sq_y and player_sq_y <= sq_y2)

        -- If `sq_dist` is nil, there were no safehouses found.
        -- If we have safehouse distance disabled and are not in the safehouse.
        -- If safehouse distance enabled and we aren't in the safehouse or the distance is too big.
        if sq_dist == nil
        or (sbvars.SafehouseDistance == 0 and in_safehouse_area == false)
        or (sbvars.SafehouseDistance > 0 and sq_dist > sbvars.SafehouseDistance) then
            player:setHaloNote(
                getText(("IGUI_%s_HaloNote_NotInSafehouse"):format(mod_constants.MOD_ID)),
                255.0,
                0.0,
                0.0,
                (128.0 * 2)) --- @diagnostic disable-line: redundant-parameter

            perform = false
        end
    end

    return perform
end

--- @type Recipe_OnCreate
Recipe.OnCreate[mod_constants.MOD_ID].ClaimVehicle = function (
    sources,
    result,
    player,
    item,
    isPrimaryHandItem,
    isSecondaryHandItem)
    --- @cast player IsoPlayer

    local sbvars = SandboxVars[mod_constants.MOD_ID] --[[@as SandboxVarsDummy]]

    --- @diagnostic disable-next-line: undefined-field

    local mdata = aoqia_table.init_mdata(item, mod_constants.MOD_ID)
    if mdata == nil then
        logger:warn_server("Pinkslip sub_mdata failed to create/retrieve. THIS IS SO BAD!!!")
        return
    end

    local args = {} --[[@as ModDataDummy]] --- @diagnostic disable-line

    -- If there are no parts, it means the pinkslip isn't player-made.
    -- We have to handle it differently because it will not have stored any proper data for parts.
    local generated_key = false
    if mdata.Parts == nil then
        if sbvars.DoAllowGeneratedPinkslips == false then
            player:setHaloNote(
                getText(("IGUI_%s_HaloNote_NoGeneratedPinkslips"):format(mod_constants.MOD_ID)),
                255.0,
                0.0,
                0.0,
                (128.0 * 2)) --- @diagnostic disable-line: redundant-parameter

            return
        end

        -- Get a random vehicle for the pinkslip that isn't blacklisted.
        local vehicle_names = getAllVehicles()
        local vehicle_name = nil

        local count = 1
        while true do
            if count >= 10000 then
                logger:error_server("Unable to select random vehicle due to timeout.")
                return
            end

            vehicle_name = vehicle_names:get(ZombRand(0, vehicle_names:size())) --[[@as string]]
            local name_lower = vehicle_name:lower()

            local blacklisted = sandbox_data.pinkslip_blacklist.index[vehicle_name] ~= nil

            -- The vehicle's chance to be selected. Influenced by pinkslip weights.
            local chance = blacklisted == false and 100 or 0

            -- If there is no chance listed in the table, assume 100% chance?
            local entry_idx = sandbox_data.pinkslip_chances.index[vehicle_name]
            if entry_idx then
                local entry_type = sandbox_data.pinkslip_chances.values[entry_idx]
                chance = entry_type.chance
            end

            logger:debug_server("Checking random vehicle (%s) with chance (%d).",
                vehicle_name,
                chance)

            -- If vehicle is not blaclisted, trailer, burnt, or smashed.
            -- Or if vehicle is blacklisted but has a chance to spawn.
            if  (blacklisted == false or chance > 0)
            and name_lower:contains("trailer") == false
            and name_lower:contains("burnt") == false
            and name_lower:contains("smashed") == false
            and ZombRand(1, 100) <= chance then
                logger:debug_server("Random vehicle selected.")
                break
            end

            count = count + 1
        end
        assert(vehicle_name,
            "No vehicle found when trying to claim random vehicle from pinkslip.")

        args.FullType = vehicle_name
        -- generated_key = ZombRand(0, 100) <= 25 and true or false
        generated_key = true
    else
        args.Parts = mdata.Parts
        args.FullType = mdata.FullType
    end

    -- Set general vehicle properties.

    args.EngineLoudness = mdata.EngineLoudness or nil
    args.EnginePower = mdata.EnginePower or nil
    args.EngineQuality = mdata.EngineQuality or nil
    args.HasKey = mdata.HasKey or nil
    args.MakeKey = (generated_key and true) or (mdata.MakeKey or nil)
    args.HeadlightsActive = mdata.HeadlightsActive or nil
    args.HeaterActive = mdata.HeaterActive or nil
    args.Hotwired = mdata.Hotwired or nil
    args.Rust = mdata.Rust or nil
    args.Skin = mdata.Skin or nil
    args.ModData = mdata.ModData or nil

    args.Blood = mdata.Blood and {
        F = mdata.Blood.F,
        B = mdata.Blood.B,
        L = mdata.Blood.L,
        R = mdata.Blood.R,
    } or nil

    args.Color = mdata.Color and
        { H = mdata.Color.H, S = mdata.Color.S, V = mdata.Color.V } or nil

    args.X = player:getX()
    args.Y = player:getY()
    args.Z = 0 -- Vehicles can't spawn past level 0
    args.Dir = player:getDir()

    sendClientCommand(player, mod_constants.MOD_ID, "spawn_vehicle", args)
end

return recipes
