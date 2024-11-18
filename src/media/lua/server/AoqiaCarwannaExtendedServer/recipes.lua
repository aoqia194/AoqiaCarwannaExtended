-- -------------------------------------------------------------------------- --
--                       Sandbox Options Blacklist Stuff                      --
-- -------------------------------------------------------------------------- --

-- AoqiaCarwannaExtended requires.
local blacklist = require("AoqiaCarwannaExtendedShared/blacklists")
local constants = require("AoqiaZomboidUtilsShared/constants")
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
    script_items:addAll(script_manager:getItemsByType("Pinkslip"))
end

--- @type Recipe_OnCanPerform
Recipe.OnCanPerform[mod_constants.MOD_ID].ClaimVehicle = function (recipe, player, item)
    --- @cast player IsoPlayer

    local sbvars = SandboxVars[mod_constants.MOD_ID] --[[@as SandboxVarsDummy]]

    local player_username = player:getUsername()
    logger:info_server("Player (%s) <%s> is trying to claim a vehicle using pinkslip!",
        tostring(player_username), tostring(getSteamIDFromUsername(player_username)))

    local perform = true

    -- If the player is not outside, don't claim it.
    local player_sq = player:getSquare()
    if player:isOutside() == false then
        player:setHaloNote(getText(("IGUI_%s_HaloNote_NotOutside"):format(mod_constants.MOD_ID)),
            (128.0 * 2))
        logger:debug_server("Failed to spawn vehicle as the player is not outside.")
        perform = false
    end

    if player_sq:isVehicleIntersecting() then
        player:setHaloNote(
            getText(("IGUI_%s_HaloNote_VehicleIntersecting"):format(mod_constants.MOD_ID)),
            (128.0 * 2))
        logger:debug_server(
            "Failed to spawn vehicle as the player is intersecting with another vehicle.")
        perform = false
    end

    -- If we need to be in a safehouse to spawn the vehicle.
    if constants.IS_SINGLEPLAYER == false and sbvars.DoSafehouseOnly then
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
            local temp = safehouses:get(i - 1) --[[@as SafeHouse | nil]]
            if temp == nil then
                logger:error_server(
                    "Safehouse was nil while looping through the safehouse list.")
                break
            end

            -- Get the closest safehouse recursively.
            if temp:playerAllowed(username) then
                local x = temp:getX()
                local y = temp:getY()
                local x2 = temp:getX2()
                local y2 = temp:getY2()

                local center = getSquare(math.max(0, x2 - (x2 - x)),
                    math.max(0, y2 - (y2 - y)), 0)
                -- If distance is shorter, update the tracked `sq` and it's data.
                local dist = player_sq:DistTo(center)
                if sq_dist == nil or dist < sq_dist then
                    sq_dist = dist
                    sq_x = x
                    sq_y = y
                    sq_x2 = x2
                    sq_y2 = y2
                end
            end
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
                (128.0 * 2))

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

    local mdata = item:getModData() --[[@as ModDataDummy]]
    local args = {} --[[@as ModDataDummy]] --- @diagnostic disable-line

    -- If there are no parts, it means the pinkslip isn't player-made.
    -- We have to handle it differently because it will not have stored any proper data for parts.
    local generated_key = false
    if mdata.Parts == nil then
        if sbvars.DoAllowGeneratedPinkslips == false then
            player:setHaloNote(
                getText(("IGUI_%s_HaloNote_NoGeneratedPinkslips"):format(mod_constants.MOD_ID)),
                (128.0 * 2))

            return
        end

        -- Get a random vehicle for the pinkslip that isn't blacklisted.
        local vehicle_names = getAllVehicles()
        local vehicle_name = nil

        local count = 1
        while true do
            if count >= 60 then
                logger:error_server("Unable to select random vehicle due to timeout.")
                return
            end

            vehicle_name = vehicle_names:get(ZombRand(0, vehicle_names:size() - 1)) --[[@as string]]
            local name_lower = vehicle_name:lower()
            logger:debug_server("Selecting random vehicle (%s).", vehicle_name)

            -- If vehicle not blacklisted, trailer, burnt, or smashed.
            if  blacklist.vehicle_blacklist.index[vehicle_name] == nil
            and name_lower:contains("trailer") == false
            and name_lower:contains("burnt") == false
            and name_lower:contains("smashed") == false then
                logger:debug_server("Random vehicle selected.")
                break
            end

            count = count + 1
        end
        assert(vehicle_name,
            "No vehicle found when trying to claim random vehicle from pinkslip.")

        args.FullType = vehicle_name
        generated_key = ZombRand(0, 100) <= 25 and true or false
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

    args.Color = mdata.Color and { H = mdata.Color.H, S = mdata.Color.S, V = mdata.Color.V } or nil

    args.X = player:getX()
    args.Y = player:getY()
    args.Z = player:getZ()
    args.Dir = player:getDir()

    sendClientCommand(player, mod_constants.MOD_ID, "spawn_vehicle", args)
end

return recipes
