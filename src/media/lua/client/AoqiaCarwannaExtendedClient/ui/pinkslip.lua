-- -------------------------------------------- --
-- PINKSLIP CLAIM UI                            --
-- -------------------------------------------- --

-- My requires.
local aoqia_table = require("AoqiaZomboidUtilsShared/table")
local constants = require("AoqiaZomboidUtilsShared/constants")
local create_pinkslip = require("AoqiaCarwannaExtendedClient/actions/create_pinkslip")
local mod_constants = require("AoqiaCarwannaExtendedShared/mod_constants")
local sandbox_data = require("AoqiaCarwannaExtendedShared/sandbox_data")
-- TIS requires.
require("luautils")

-- std globals.
local math = math
-- TIS globals.
local getText = getText
local ISModalRichText = ISModalRichText
local ISTimedActionQueue = ISTimedActionQueue
local ISToolTip = ISToolTip
local luautils = luautils
local SafeHouse = SafeHouse
local SandboxVars = SandboxVars

local logger = mod_constants.LOGGER

-- ------------------------------ Module Start ------------------------------ --

local pinkslip = {}

--- @param vehicle BaseVehicle
--- @return boolean
function pinkslip.is_trailer(vehicle)
    local vehicle_script = vehicle:getScript()
    if sandbox_data.trailer_blacklist[vehicle_script:getFullName()] then
        return true
    end

    for i = 1, #sandbox_data.known_trailers do
        local trailer = sandbox_data.known_trailers[i]

        local attachment = vehicle_script:getAttachmentById(trailer)
        if attachment and attachment:getCanAttach() then
            return true
        end
    end

    return false
end

--- Param order matters here!
--- @param player IsoPlayer
--- @param button ISRadioButtons
--- @param vehicle BaseVehicle
function pinkslip.create_pinkslip(player, button, vehicle)
    if button.internal == "NO" then return end

    if luautils.walkAdj(player, vehicle:getSquare()) then
        ISTimedActionQueue.add(create_pinkslip:new(player, vehicle))
    end
end

--- @param player IsoPlayer
--- @param vehicle BaseVehicle
function pinkslip.confirm_dialog(player, vehicle)
    local sbvars = SandboxVars[mod_constants.MOD_ID] --[[@as SandboxVarsDummy]]

    local player_num = player:getPlayerNum()

    local interior_warning = ((sbvars.DoCompatRvInteriors and sbvars.DoUnassignInterior
            and RVInterior and RVInterior.vehicleHasInteriorParameters(vehicle)) and
        getText(("IGUI_%s_ConfirmInteriorWarning"):format(mod_constants.MOD_ID)) or "")

    local confirm_text = getText(("IGUI_%s_ConfirmText"):format(mod_constants.MOD_ID),
            getText("IGUI_VehicleName" .. vehicle:getScript():getName()))
        .. ((interior_warning ~= "") and (" <LINE> <RGB:1,0,0> " .. interior_warning) or "")

    local modal = ISModalRichText:new(
        0,
        0,
        300,
        150,
        confirm_text,
        true,
        player,
        pinkslip.create_pinkslip,
        player_num,
        vehicle)
    modal:initialise()
    modal:addToUIManager()
end

--- @param player IsoPlayer
--- @param context ISContextMenu
--- @param vehicle BaseVehicle
function pinkslip.add_option_to_menu(player, context, vehicle)
    local sbvars = SandboxVars[mod_constants.MOD_ID] --[[@as SandboxVarsDummy]]
    if sbvars.DoRegistration == false then return end

    local mdata = aoqia_table.init_mdata(vehicle, mod_constants.MOD_ID) --[[@as ModDataDummy]]
    local player_inv = player:getInventory()

    local vehicle_script = vehicle:getScript()
    local vehicle_name = vehicle:getScriptName()
    local vehicle_name_lower = vehicle_name:lower()
    local vehicle_id = vehicle_script:getName()
    local vehicle_fullname = vehicle_script:getFullName()

    -- Who wants a smashed or burnt vehicle? :(
    if vehicle_name_lower:contains("burnt")
    or vehicle_name_lower:contains("smashed") then
        return
    end

    if  sbvars.DoRequiresAutoForm
    and player_inv:containsTypeRecurse(mod_constants.MOD_ID .. ".AutoForm") == false then
        return
    end

    -- Check if the player has permissions with AdvancedVehicleClaimSystem.
    local avcs_perm = nil
    if AVCS then
        avcs_perm = AVCS.checkPermission(player, vehicle)
        if (type(avcs_perm) == "boolean" and avcs_perm == false)
        or (type(avcs_perm) == "table" and avcs_perm.permissions == false) then
            return
        end
    end

    -- Context option and tooltip setup below.

    local option = context:addOption(
        getText(("ContextMenu_%s_CreatePinkslip"):format(mod_constants.MOD_ID)),
        player,
        pinkslip.confirm_dialog,
        vehicle)

    local tooltip = ISToolTip:new()
    local text = getText("IGUI_VehicleName" .. vehicle_id)
    local not_available = false

    -- If the vehicle has passengers, don't even bother.
    local has_passengers = false
    for i = 1, vehicle:getMaxPassengers() do
        if vehicle:getCharacter(i - 1) then
            has_passengers = true
            break
        end
    end

    if has_passengers then
        text = text
            .. " <LINE> <RGB:1,1,0> "
            .. getText(("Tooltip_%s_HasPassengers"):format(mod_constants.MOD_ID))
        not_available = true

        logger:debug("adding option failed: Has passengers.")
    end

    -- Has vehicle key check.
    local key = player_inv:haveThisKeyId(vehicle:getKeyId())
    if key == nil and mdata.HasKey == false then
        local ktcolour = nil
        local endtext = nil

        if pinkslip.is_trailer(vehicle) then
            ktcolour = " <RGB:0,1,0> "
            endtext = getText(("Tooltip_%s_TrailerKey"):format(mod_constants
                .MOD_ID))
        elseif sbvars.DoRequiresKey then
            ktcolour = " <RGB:1,0,0> "
            endtext = getText(("Tooltip_%s_NeedsKey"):format(mod_constants
                .MOD_ID))
            not_available = true

            logger:debug("adding option failed: Needs key.")
        end

        text = text .. " <LINE> " .. ktcolour .. endtext

        logger:debug("Has key check.")
    end

    -- Vehicle hotwire checks.
    if vehicle:isHotwired() then
        if sbvars.DoCanHotwire then
            text = text .. " <LINE> <RGB:1,1,0> "
        else
            text = text .. " <LINE> <RGB:1,0,0> "
            not_available = true
        end

        text = text
            .. getText(("Tooltip_%s_Hotwired"):format(mod_constants.MOD_ID))

        logger:debug("Is hotwired!")
    end

    --- @type string[]
    local container_items = {}
    --- @type string[]
    local damaged_parts = {}
    --- @type string[]
    local missing_parts = {}

    -- Ah shit, here we go again.
    for i = 1, vehicle:getPartCount() do
        -- Break is continue!
        repeat
            local part = vehicle:getPartByIndex(i - 1)
            local part_id = part:getId()
            local part_type = part:getItemType()
            local part_cat = part:getCategory()
            local item = part:getInventoryItem()

            -- Ignores hidden parts.
            -- TsarATA's parts are nodisplay but also displayable, so still loop them!
            if  sbvars.DoIgnoreHiddenParts
            and part_cat == "nodisplay"
            and (sbvars.DoCompatTsarMod == false
                or ATA2TuningTable == false
                or ATA2TuningTable[vehicle_id] == false
                or ATA2TuningTable[vehicle_id].parts[part_id] == false) then
                break
            end

            -- If part is real, broken or in container
            if part_type == nil
            or part_type:isEmpty()
            or item then
                if  part:getCondition() < sbvars.MinimumCondition
                and sandbox_data.part_whitelist[part_id] == nil then
                    damaged_parts[#damaged_parts + 1] = part_id
                end

                local container = part:getItemContainer()
                if container and container:getItems():isEmpty() == false then
                    container_items[#container_items + 1] = part_id
                end

                break
            end

            -- Add missing parts if it is missing
            if sandbox_data.part_whitelist[part_id] == nil then
                missing_parts[#missing_parts + 1] = part_id
            end
        until true
    end

    if missing_parts and #missing_parts > 0 then
        local col = (sbvars.DoRequiresAllParts and " <RGB:1,0,0> " or " <RGB:1,1,0> ")

        if sbvars.DoShowAllParts then
            text = text
                .. " <LINE> <LINE> "
                .. getText(("Tooltip_%s_PartsMissing")
                    :format(mod_constants.MOD_ID))
                .. col

            for i = 1, #missing_parts do
                local part = missing_parts[i]

                local trans_key = "IGUI_VehiclePart" .. part
                local trans_val = getText(trans_key)
                text = text
                    .. " <LINE> "
                    .. (trans_val == trans_key
                        and "[Hidden] " .. part or trans_val)
            end
        else
            text = text
                .. " <LINE> "
                .. col
                .. getText(
                    ("Tooltip_%s_PartsMissingNum"):format(mod_constants.MOD_ID),
                    #missing_parts)
        end

        if sbvars.DoRequiresAllParts then
            not_available = true
            logger:debug("adding option failed: Requires all parts.")
        end
    end

    if damaged_parts and #damaged_parts > 0 then
        local col = (sbvars.DoRequiresRepairedParts and " <RGB:1,0,0> " or " <RGB:1,1,0> ")

        if sbvars.DoShowAllParts then
            text = text
                .. " <LINE> <LINE> <RGB:1,1,1> "
                .. getText(
                    ("Tooltip_%s_PartsDamaged"):format(mod_constants.MOD_ID),
                    sbvars.MinimumCondition)
                .. col
            for i = 1, #damaged_parts do
                local part = damaged_parts[i]

                local trans_key = "IGUI_VehiclePart" .. part
                local trans_val = getText(trans_key)
                text = text
                    .. " <LINE> "
                    .. col
                    .. (trans_val == trans_key
                        and "[Hidden] " .. part or trans_val)
            end
        else
            text = text
                .. " <LINE> "
                .. col
                .. getText(
                    ("Tooltip_%s_PartsDamagedNum"):format(mod_constants.MOD_ID),
                    #damaged_parts)
        end

        if sbvars.DoRequiresRepairedParts then
            not_available = true
            logger:debug("adding option failed: Broken parts found.")
        end
    end

    if container_items and #container_items > 0 then
        text = text
            .. " <LINE> <LINE> <RGB:1,1,1> "
            .. getText(("Tooltip_%s_HasItems"):format(mod_constants.MOD_ID))

        local ttcolour = "<RGB:1,1,0> "
        if sbvars.DoClearInventory then
            ttcolour = "<RGB:1,0,0> "
            not_available = true
            logger:debug("adding option failed: The vehicle has items in it.")
        end

        for i = 1, #container_items do
            local part = container_items[i]

            local trans_key = "IGUI_VehiclePart" .. part
            local trans_val = getText(trans_key)
            text = text
                .. " <LINE> "
                .. ttcolour
                .. (trans_val == trans_key
                    and "[Hidden] " .. part or trans_val)
        end
    end

    if sandbox_data.vehicle_blacklist[vehicle_fullname] then
        text = text
            .. " <LINE> <RGB:1,1,1> "
            .. getText(("Tooltip_%s_Blacklisted"):format(mod_constants.MOD_ID))
            .. " <LINE> <RGB:1,0,0> "
            .. vehicle_fullname
        not_available = true
        logger:debug(
            "adding option failed: Vehicle blacklisted from pinkslip use.")
    end

    if not_available == false and sbvars.DoParkingMeterOnly then
        local found_meter = false

        local sq = vehicle:getSquare()
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
            text = text
                .. " <LINE> <LINE> <RGB:1,0,0> "
                .. getText(("Tooltip_%s_NoParkingMeterFound"):format(mod_constants.MOD_ID))
            not_available = true
        end
    end

    if not_available == false and constants.IS_SINGLEPLAYER == false and sbvars.DoSafehouseOnly then
        local found_safehouse = false

        local username = player:getUsername()
        local veh_sq = vehicle:getSquare()
        local veh_sq_x = veh_sq:getX()
        local veh_sq_y = veh_sq:getY()

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
                    local dist = veh_sq:DistTo(
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
            logger:debug("sq_dist was nil, even after safehouse loop.")
        end

        -- Is the player in the safehouse area?
        local in_safehouse_area = sq_dist and
            (veh_sq_x >= sq_x and veh_sq_x <= sq_x2) and
            (veh_sq_y >= sq_y and veh_sq_y <= sq_y2)

        -- If `sq_dist` is nil, there were no safehouses found.
        -- If we have safehouse distance disabled and are not in the safehouse.
        -- If safehouse distance enabled and we aren't in the safehouse or the distance is too big.
        if sq_dist == nil
        or (sbvars.SafehouseDistance == 0 and in_safehouse_area == false)
        or (sbvars.SafehouseDistance > 0 and sq_dist > sbvars.SafehouseDistance) then
            found_safehouse = false
        else
            found_safehouse = true
        end

        if found_safehouse == false then
            text = text
                .. " <LINE> <LINE> <RGB:1,0,0> "
                .. getText(("Tooltip_%s_NoSafehouseFound"):format(mod_constants.MOD_ID))
            not_available = true
        end
    end

    -- Shouldn't be able to claim if your friends are in the interior LOL.
    if sbvars.DoCompatRvInteriors and RVInterior.vehicleHasInteriorParameters(vehicle) then
        local interior_vehicle_name = RVInterior.getVehicleName(vehicle_name)
        local interior_vehicle_moddata = RVInterior.getVehicleModData(vehicle,
            RVInterior.getInteriorParameters(interior_vehicle_name))

        if interior_vehicle_moddata then
            local online_players = getOnlinePlayers()
            for i = 1, online_players:size() do
                local target = online_players:get(i - 1) --[[@as IsoPlayer]]

                if RVInterior.playerInsideInterior(target) == interior_vehicle_name then
                    text = text
                        .. " <LINE> <LINE> <RGB:1,0,0> "
                        .. getText(("Tooltip_%s_PlayersInInterior"):format(mod_constants.MOD_ID))
                    not_available = true
                end
            end
        end
    end

    -- If the vehicle needs to be unclaimed.
    -- checkPermission will return true for unclaimed vehicles.
    if AVCS and sbvars.DoRequiresUnclaimed and type(avcs_perm) == "table" then
        text = text
            .. " <LINE> <LINE> <RGB:1,0,0> "
            .. getText(("Tooltip_%s_RequiresUnclaimed"):format(mod_constants.MOD_ID))
        not_available = true
    end

    -- If the player is above Z level 0.
    if player:getZ() > 0 then
        text = text
            .. "<LINE> <LINE> <RGB:1,0,0> "
            .. getText(("Tooltip_%s_AboveZLevel"):format(mod_constants.MOD_ID))
        not_available = true
    end

    -- Do admin override if enabled.
    if  not_available
    and player:getAccessLevel() == "Admin"
    and sbvars.DoAdminOverride then
        text = text
            .. " <LINE> <LINE> <RGB:0,1,0> "
            .. getText(("Tooltip_%s_DoAdminOverride"):format(mod_constants
                .MOD_ID))
        not_available = false
    end

    tooltip.description = text
    option.toolTip = tooltip
    option.notAvailable = not_available
end

return pinkslip
