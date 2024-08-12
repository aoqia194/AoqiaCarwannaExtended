-- -------------------------------------------------------------------------- --
--                                    wawa                                    --
-- -------------------------------------------------------------------------- --

-- My requires.
local create_title = require("AoqiaCarwannaExtended/actions/create_title")
local mod_constants = require("AoqiaCarwannaExtended/mod_constants")
-- TIS requires.
require("luautils")

-- std globals.
local table = table
-- TIS globals.
local ISModalDialog = ISModalDialog
local ISTimedActionQueue = ISTimedActionQueue
local ISToolTip = ISToolTip
local luautils = luautils
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
    if pinkslip.trailer_list[vehicle_script:getFullName()] then
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

--- @param player IsoPlayer
--- @param vehicle BaseVehicle
--- @param button ISRadioButtons
function pinkslip.create_title(player, vehicle, button)
    if button.internal == "NO" then return end

    if luautils.walkAdj(player, vehicle:getSquare()) then
        ISTimedActionQueue.add(create_title:new(player, vehicle))
    end
end

--- @param player IsoPlayer
--- @param vehicle BaseVehicle
function pinkslip.confirm_dialog(player, vehicle)
    local player_num = player:getPlayerNum()
    local vehicle_script = vehicle:getScript()

    local confirm_text = getText(("IGUI_%s_Confirm"):format(mod_constants.MOD_ID)) or "NULL_TRANSLATION"
    local message = confirm_text:format(getText("IGUI_VehicleName" .. vehicle_script:getName()))

    local modal = ISModalDialog:new(
        0,
        0,
        300,
        150,
        message,
        true,
        player,
        pinkslip.create_title,
        player_num,
        vehicle)
    modal:initialise()
    modal:addToUIManager()
end

--- TODO: Rewrite this function holy shit it looks like a idk its bad
--- @param player IsoPlayer
--- @param context ISContextMenu
--- @param vehicle BaseVehicle
function pinkslip.add_option_to_menu(player, context, vehicle)
    local sbvars = SandboxVars[mod_constants.MOD_ID] --[[@as SandboxVarsDummy]]
    if sbvars.DoRegistration then return end

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

    if Valhalla and Valhalla.VehicleClaims then
        local data = Valhalla.VehicleClaims:getOwner(vehicle)
        if data then
            text = text ..
                (" <LINE> <LINE> <RGB:1,1,1> %s <LINE> <RGB:1,0,0> %s"):format(getText(
                    ("Tooltip_%s_Aegis"):format(mod_constants.MOD_ID), data))
            not_available = true
        end
    end

    local key = player_inv:haveThisKeyId(vehicle:getKeyId())
    text = text ..
        (" <LINE> <LINE> <RGB:1,1,1> %s"):format(getText(("Tooltip_%s_Key"):format(mod_constants
            .MOD_ID)))
    if key == nil then
        local ktcolour = "<RGB:1,1,0>"
        local endtext = getText(("Tooltip_%s_NeedsKey"):format(mod_constants.MOD_ID))

        if pinkslip.is_trailer(vehicle) then
            ktcolour = "<RGB:0,1,0>"
            endtext = getText(("Tooltip_%s_KeyTrailer"):format(mod_constants.MOD_ID))
        elseif sbvars.DoRequiresKey then
            not_available = true
            ktcolour = "<RGB:1,0,0>"
        end

        text = text .. (" <LINE> %s %s"):format(ktcolour, endtext)
    else
        text = text ..
            (" <LINE> <RGB:0,1,0> %s"):format(getText(("Tooltip_%s_HasKey"):format(mod_constants
                .MOD_ID)))
    end

    if vehicle:isHotwired() then
        if sbvars.DoCanHotwire then
            text = text .. " <LINE> <RGB:1,1,0> "
        else
            text = text .. " <LINE> <RGB:1,0,0> "
            not_available = true
        end

        text = text .. getText(("Tooltip_%s_Hotwired"):format(mod_constants.MOD_ID))
    end

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

            if  part:getCategory() == "nodisplay"
            and (sbvars.DoIgnoreHiddenParts == false
                and part:getCategory() ~= "nodisplay")
            and (sbvars.DoCompatTsarMod
                and ATA2TuningTable
                and ATA2TuningTable[vehicle_id]
                and ATA2TuningTable[vehicle_id].parts[part_id]) then
                break
            end

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
            end
        until true
    end

    if #missing_parts > 0 then
        text = text
            .. " <LINE> <LINE> <RGB:1,1,1> "
            .. getText(("Tooltip_%s_Install"):format(mod_constants.MOD_ID))
        for i = 1, #missing_parts do
            local part = missing_parts[i]
            text = text
                .. " <LINE> <LINE> <RGB:1,1,1> "
                .. getText("IGUI_VehiclePart" .. part)
        end

        if sbvars.DoRequiresAllParts then
            not_available = true
        end
    end

    if #broken_parts > 0 then
        text = text
            .. " <LINE> <LINE> <RGB:1,1,1> "
            .. getText(("Tooltip_%s_Repair"):format(mod_constants.MOD_ID),
                sbvars.MinimumCondition)
        for i = 1, #broken_parts do
            local part = broken_parts[i]
            text = text
                .. " <LINE> <RGB:1,0,0> "
                .. getText("IGUI_VehiclePart" .. part)
        end

        not_available = true
    end

    if #container_items > 0 then
        text = text
            .. " <LINE> <LINE> <RGB:1,1,1> "
            .. getText(("Tooltip_%s_HasItems"):format(mod_constants.MOD_ID))
        local ttcolour = "<RGB:1,1,0>"
        if sbvars.DoClearInventory then
            ttcolour = "<RGB:1,0,0>"
            not_available = true
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
            .. " <LINE> <LINE> <RGB:1,1,1> "
            .. getText(("Tooltip_%S_Blacklisted"):format(mod_constants.MOD_ID))
            .. " <LINE> <RGB:1,0,0> "
            .. vehicle_fullname
        not_available = true
    end

    if not_available
    and player:getAccessLevel() == "Admin"
    and sbvars.DoAdminOverride then
        text = text
            .. " <LINE> <LINE> <RGB:0,1,0> "
            .. getText(("Tooltip_%s_DoAdminOverride"):format(mod_constants.MOD_ID))
        not_available = false
    end

    if not_available == false then
        text = text
            .. " <LINE> <LINE> <RGB:1,1,1> "
            .. getText(("Tooltip_%s_Inspection"):format(mod_constants.MOD_ID))
        text = text
            .. " <LINE> <RGB:0,1,0> "
            .. getText(("Tooltip_%s_Pass"):format(mod_constants.MOD_ID))
    end

    tooltip.description = text
    option.notAvailable = not_available
end

return pinkslip
