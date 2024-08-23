-- -------------------------------------------------------------------------- --
--                                    wawa                                    --
-- -------------------------------------------------------------------------- --

-- My requires.
local create_pinkslip = require("AoqiaCarwannaExtendedClient/actions/create_pinkslip")
local mod_constants = require("AoqiaCarwannaExtendedShared/mod_constants")
-- TIS requires.
require("luautils")

-- std globals.
local math = math
local table = table
-- TIS globals.
local getSquare = getSquare
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
--- @type table<integer, table<string, boolean>>
pinkslip.loot_blacklist = {}
--- @type table<integer, table<string, boolean>>
pinkslip.part_whitelist = {}
--- @type table<integer, table<string, boolean>>
pinkslip.trailer_blacklist = {}
--- @type table<integer, table<string, boolean>>
pinkslip.vehicle_blacklist = {}

pinkslip.known_trailers = { "trailer", "trailerTruck" }

--- @param vehicle BaseVehicle
--- @return boolean
function pinkslip.is_trailer(vehicle)
    local vehicle_script = vehicle:getScript()
    if pinkslip.trailer_blacklist[vehicle_script:getFullName()] then
        return true
    end

    for i = 1, #pinkslip.known_trailers do
        local trailer = pinkslip.known_trailers[i]

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
    local player_num = player:getPlayerNum()
    local vehicle_script = vehicle:getScript()

    local confirm_text = getText(("IGUI_%s_Confirm"):format(mod_constants.MOD_ID)) --[[@as string]]
        .. " <LINE> <RGB:1,0,0> "
        .. getText(("IGUI_%s_ConfirmWarning"):format(mod_constants.MOD_ID))
    local message = confirm_text:format(getText("IGUI_VehicleName" .. vehicle_script:getName()))

    local modal = ISModalRichText:new(
        0,
        0,
        300,
        150,
        message,
        true,
        player,
        pinkslip.create_pinkslip,
        player_num,
        vehicle)
    modal:initialise()
    modal:addToUIManager()
end

--- TODO: Rewrite the tooltip portions of the code, its so bad
--- @param player IsoPlayer
--- @param context ISContextMenu
--- @param vehicle BaseVehicle
function pinkslip.add_option_to_menu(player, context, vehicle)
    local sbvars = SandboxVars[mod_constants.MOD_ID] --[[@as SandboxVarsDummy]]
    if sbvars.DoRegistration == false then return end

    local mdata = vehicle:getModData() --[[@as ModDataDummy]]

    local player_inv = player:getInventory()

    local vehicle_script = vehicle:getScript()
    local vehicle_name = vehicle:getScriptName():lower()
    local vehicle_id = vehicle_script:getName()
    local vehicle_fullname = vehicle_script:getFullName()

    -- Who wants a smashed or burnt vehicle :(
    if vehicle_name:contains("burnt")
    or vehicle_name:contains("smashed") then
        return
    end

    if  sbvars.DoRequiresForm
    and player_inv:containsTypeRecurse("AutoForm") == false then
        return
    end

    -- If the vehicle has passengers, don't even bother.
    local has_passengers = false
    for i = 1, vehicle:getMaxPassengers() do
        if vehicle:getCharacter(i - 1) then
            has_passengers = true
            break
        end
    end
    if has_passengers then return end

    local option_text = getText(("ContextMenu_%s_CreatePinkslip"):format(mod_constants.MOD_ID))
    local option = context:addOption(option_text, player, pinkslip.confirm_dialog, vehicle)

    local tooltip = ISToolTip:new()
    local text = getText("IGUI_VehicleName" .. vehicle_id)
    local not_available = false

    -- Some valhalla stuff from the original mod. I have no idea what this is.
    -- Keeping this here for potential compatibility only.
    if Valhalla and Valhalla.VehicleClaims then
        local data = Valhalla.VehicleClaims:getOwner(vehicle)
        if data then
            text = text ..
                (" <LINE> <LINE> <RGB:1,1,1> %s <LINE> <RGB:1,0,0> %s"):format(getText(
                    ("Tooltip_%s_Aegis"):format(mod_constants.MOD_ID), data))
            not_available = true
            logger:debug("Adding pinkslip option to menu failed: Valhalla check.")
        end
    end

    text = text .. " <LINE> "

    -- Has vehicle key check.
    local key = player_inv:haveThisKeyId(vehicle:getKeyId())
    text = text ..
        (" <LINE> <RGB:1,1,1> %s <LINE> "):format(getText(("Tooltip_%s_Key"):format(mod_constants
            .MOD_ID)))
    if key == nil and mdata.HasKey == false then
        local ktcolour = " <RGB:1,1,0> "
        local endtext = getText(("Tooltip_%s_NeedsKey"):format(mod_constants.MOD_ID))

        if pinkslip.is_trailer(vehicle) then
            ktcolour = "<RGB:0,1,0>"
            endtext = getText(("Tooltip_%s_KeyTrailer"):format(mod_constants.MOD_ID))
        elseif sbvars.DoRequiresKey then
            not_available = true
            ktcolour = "<RGB:1,0,0>"
            logger:debug("Adding pinkslip option to menu failed: Needs key.")
        end

        text = text .. (" %s %s"):format(ktcolour, endtext)
    else
        text = text ..
            (" <RGB:0,1,0> %s"):format(getText(("Tooltip_%s_HasKey"):format(mod_constants.MOD_ID)))
    end

    -- Vehicle hotwire checks.
    if vehicle:isHotwired() then
        if sbvars.DoCanHotwire then
            text = text .. " <LINE> <RGB:1,1,0> "
        else
            text = text .. " <LINE> <RGB:1,0,0> "
            not_available = true
        end

        text = text .. getText(("Tooltip_%s_Hotwired"):format(mod_constants.MOD_ID))
    end

    -- These aren't used anywhere else. I thought about removing them.
    -- I am not sure if it's worth it for performance.
    local container_items = table.newarray()
    local broken_parts = table.newarray()
    local missing_parts = table.newarray()

    -- NOTE: Ah shit, here we go again.
    for i = 1, vehicle:getPartCount() do
        -- Break is continue!
        repeat
            local part = vehicle:getPartByIndex(i - 1)
            local part_id = part:getId()
            local part_type = part:getItemType()
            local item = part:getInventoryItem()

            if part:getCategory() == "nodisplay"
            or (sbvars.DoIgnoreHiddenParts and part:getCategory() ~= "nodisplay")
            or (sbvars.DoCompatTsarMod
                and ATA2TuningTable
                and ATA2TuningTable[vehicle_id]
                and ATA2TuningTable[vehicle_id].parts[part_id]) then
                break
            end

            -- If part is real, broken or in container
            if part_type == nil
            or part_type:isEmpty()
            or item then
                if  part:getCondition() < sbvars.MinimumCondition
                and pinkslip.part_whitelist[part_id] then
                    broken_parts[#broken_parts + 1] = part_id
                end

                local container = part:getItemContainer()
                if container and container:getItems():isEmpty() then
                    container_items[#container_items + 1] = part_id
                end

                break
            end

            -- Add missing parts if it is missing
            if pinkslip.part_whitelist[part_id] then
                missing_parts[#missing_parts + 1] = part_id
            end

            break
        until true
    end

    if #missing_parts > 0 then
        text = text
            .. " <LINE> <RGB:1,1,1> "
            .. getText(("Tooltip_%s_Install"):format(mod_constants.MOD_ID))
        for i = 1, #missing_parts do
            local part = missing_parts[i]
            text = text
                .. " <LINE> <LINE> <RGB:1,1,1> "
                .. getText("IGUI_VehiclePart" .. part)
        end

        if sbvars.DoRequiresAllParts then
            not_available = true
            logger:debug("Adding pinkslip option to menu failed: Requires all parts.")
        end
    end

    if #broken_parts > 0 then
        text = text
            .. " <LINE> <RGB:1,1,1> "
            .. getText(("Tooltip_%s_Repair"):format(mod_constants.MOD_ID),
                sbvars.MinimumCondition)
        for i = 1, #broken_parts do
            local part = broken_parts[i]
            text = text
                .. " <LINE> <RGB:1,0,0> "
                .. getText("IGUI_VehiclePart" .. part)
        end

        not_available = true
        logger:debug("Adding pinkslip option to menu failed: Broken parts found.")
    end

    if #container_items > 0 then
        text = text
            .. " <LINE> <RGB:1,1,1> "
            .. getText(("Tooltip_%s_HasItems"):format(mod_constants.MOD_ID))

        local ttcolour = "<RGB:1,1,0> "
        if sbvars.DoClearInventory then
            ttcolour = "<RGB:1,0,0> "
            not_available = true
            logger:debug(
                "Adding pinkslip option to menu failed: The vehicle's inventory needs to be cleared.")
        end

        for i = 1, #container_items do
            local part = container_items[i]
            text = text
                .. " <LINE> "
                .. ttcolour
                .. getText("IGUI_VehiclePart" .. part)
        end
    end

    if pinkslip.vehicle_blacklist[vehicle_fullname] then
        text = text
            .. " <LINE> <RGB:1,1,1> "
            .. getText(("Tooltip_%S_Blacklisted"):format(mod_constants.MOD_ID))
            .. " <LINE> <RGB:1,0,0> "
            .. vehicle_fullname
        not_available = true
        logger:debug("Adding pinkslip option to menu failed: Vehicle blacklisted from pinkslip use.")
    end

    -- If safehouse only.
    if sbvars.DoSafehouseOnly then
        local player_sq = player:getSquare()
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
                logger:error("Safehouse was nil while looping through the safehouse list.")
                break
            end

            -- Get the closest safehouse recursively.
            if temp:playerAllowed(player) then
                local x = temp:getX()
                local y = temp:getY()
                local x2 = temp:getX2()
                local y2 = temp:getY2()

                local center = getSquare(math.max(0, x2 - (x2 - x)), math.max(0, y2 - (y2 - y)), 0)
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
            logger:debug("sq_dist was nil, even after safehouse loop.")
        end

        -- Is the player in the safehouse area?
        local in_safehouse_area = sq_dist and (player_sq_x >= sq_x and player_sq_x <= sq_x2) and
            (player_sq_y >= sq_y and player_sq_y <= sq_y2)

        -- If `sq_dist` is nil, there were no safehouses found.
        -- If we have safehouse distance disabled and are not in the safehouse.
        -- If safehouse distance enabled and we aren't in the safehouse or the distance is too big.
        if sq_dist == nil
        or (sbvars.SafehouseDistance == 0 and in_safehouse_area == false)
        or (sbvars.SafehouseDistance > 0 and sq_dist > sbvars.SafehouseDistance) then
            text = text ..
                " <LINE> <LINE> <RGB:1,0,0> " ..
                getText(("Tooltip_%s_DoSafehouseOnly"):format(mod_constants.MOD_ID))
            not_available = true
        end
    end

    -- Do admin override if enabled.
    if  not_available
    and player:getAccessLevel() == "Admin"
    and sbvars.DoAdminOverride then
        text = text
            .. " <LINE> <LINE> <RGB:0,1,0> "
            .. getText(("Tooltip_%s_DoAdminOverride"):format(mod_constants.MOD_ID))
        not_available = false
    end

    tooltip.description = text
    option.toolTip = tooltip
    option.notAvailable = not_available
end

return pinkslip
