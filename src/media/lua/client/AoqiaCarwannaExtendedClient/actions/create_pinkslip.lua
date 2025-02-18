-- -------------------------------------------- --
-- CREATE PINKSLIP TIMED ACTION                 --
-- -------------------------------------------- --

-- AoqiaCarwannaExtended requires.
local aoqia_table = require("AoqiaZomboidUtilsShared/table")
local mod_constants = require("AoqiaCarwannaExtendedShared/mod_constants")

-- std globals.
local setmetatable = setmetatable
-- TIS globals.
local getText = getText
local ISBaseTimedAction = ISBaseTimedAction
local Metabolics = Metabolics
local SandboxVars = SandboxVars
local sendClientCommand = sendClientCommand
-- Mod globals
local UdderlyVehicleRespawn = UdderlyVehicleRespawn

local logger = mod_constants.LOGGER

-- ------------------------------ Module Start ------------------------------ --

local action_id = mod_constants.MOD_ID .. "_create_pinkslip"

--- @class CreatePinkslipAction: ISBaseTimedAction
local create_pinkslip = ISBaseTimedAction:derive(action_id)

function create_pinkslip:is_part_missing(part)
    local part_type = part:getItemType()
    return part_type and part_type:isEmpty() == false and part:getInventoryItem() == nil
end

function create_pinkslip:isValid()
    return self.vehicle
        and self.vehicle:isRemovedFromWorld() == false
        and getPlayer():getZ() == 0
end

function create_pinkslip:waitToStart()
    self.character:faceThisObject(self.vehicle)
    return self.character:shouldBeTurning()
end

function create_pinkslip:update()
    self.character:faceThisObject(self.vehicle)
    self.character:setMetabolicTarget(Metabolics.LightDomestic --[[@as float]])

    if self.character:getEmitter():isPlaying(self.sound --[[@as string]]) == false then
        self.sound = self.character:playSound("CreatePinkslip")
    end
end

--- Create the pinkslip item after the action is completed.
function create_pinkslip:perform()
    local sbvars = SandboxVars[mod_constants.MOD_ID] --[[@as SandboxVarsDummy]]

    if self.sound ~= 0 then
        self.character:getEmitter():stopSound(self.sound)
    end

    local vehicle_script = self.vehicle:getScript()
    local vehicle_id = vehicle_script:getName()
    local vehicle_name = getText("IGUI_VehicleName" .. vehicle_id) --[[@as string]]

    local player_inventory = self.character:getInventory()
    local pinkslip = player_inventory:AddItem(mod_constants.MOD_ID .. ".Pinkslip")
    pinkslip:setName(("%s (%s)"):format(
        getText(("IGUI_%s_Pinkslip"):format(mod_constants.MOD_ID)),
        vehicle_name))
    pinkslip:setTooltip(getText(("Tooltip_%s_Pinkslip"):format(mod_constants.MOD_ID)))

    if sbvars.DoDynamicPinkslipWeight then
        pinkslip:setWeight(self.vehicle:getWeight())
    end

    -- Make sure the table exists in the pinkslip.
    --- @type ModDataDummy | nil
    local mdata = aoqia_table.init_mdata(pinkslip, mod_constants.MOD_ID)
    if mdata == nil then
        logger:warn("Pinkslip mdata failed to create/retrieve. THIS IS SO BAD!!!")
        return
    end

    -- Replicate vehicle mod data to pinkslip mod data.
    local veh_mdata = self.vehicle:getModData()

    local has_mdata = false
    for _, _ in pairs(veh_mdata) do
        has_mdata = true
        break
    end

    if veh_mdata and has_mdata then
        mdata.ModData = aoqia_table.shallow_copy(veh_mdata)
    end

    if mdata.Parts and mdata.Parts.index and mdata.Parts.values then
        mdata.Parts = mdata.Parts
    else
        --- @diagnostic disable-next-line: assign-type-mismatch
        mdata.Parts = { index = {}, values = {} }
    end

    mdata.Blood = mdata.Blood or {}
    mdata.Color = mdata.Color or {}

    mdata.Blood.F = self.vehicle:getBloodIntensity("Front")
    mdata.Blood.B = self.vehicle:getBloodIntensity("Rear")
    mdata.Blood.L = self.vehicle:getBloodIntensity("Left")
    mdata.Blood.R = self.vehicle:getBloodIntensity("Right")
    mdata.Color.H = self.vehicle:getColorHue()
    mdata.Color.S = self.vehicle:getColorSaturation()
    mdata.Color.V = self.vehicle:getColorValue()
    mdata.EngineLoudness = self.vehicle:getEngineLoudness()
    mdata.EnginePower = self.vehicle:getEnginePower()
    mdata.EngineQuality = self.vehicle:getEngineQuality()
    mdata.HasKey = self.vehicle:isKeysInIgnition()
    mdata.HeadlightsActive = self.vehicle:getHeadlightsOn()
    mdata.Hotwired = self.vehicle:isHotwired()
    mdata.Skin = self.vehicle:getSkinIndex()
    mdata.Rust = self.vehicle:getRust()
    mdata.FullType = vehicle_script:getFullName()
    mdata.Name = vehicle_name

    local key = player_inventory:haveThisKeyId(self.vehicle:getKeyId())
    if key and mdata.HasKey == false then
        mdata.MakeKey = true
        player_inventory:Remove(key --[[@as string]])
    end

    local parts = mdata.Parts
    -- Should never happen~
    if parts == nil then return end

    local missing_parts = 0
    local damaged_parts = 0

    -- FIXME: We loop over parts and store the ones that exist
    -- but we have no way currently of storing what parts are missing.
    local weight = 0

    local idx = 1
    for i = 1, self.vehicle:getPartCount() do
        -- Breaks are continue here!
        repeat
            local part = self.vehicle:getPartByIndex(i - 1)
            local part_id = part:getId()
            local part_condition = part:getCondition()
            local part_item = part:getInventoryItem() --[[@as DrainableComboItem | nil]]

            -- Construct initial part table.
            parts.index[idx] = i - 1
            parts.values[idx] = {} --- @diagnostic disable-line: missing-fields

            logger:debug("Setting part (%s) condition to (%d).", part_id, part_condition)
            local pdata = parts.values[idx]
            pdata.Condition = part_condition
            pdata.Type = part_id

            -- If the part has no item, it means it cannot be uninstalled.
            -- In this case, we mark it as missing an item.
            if part_item == nil then
                logger:debug("Part (%s) item does not exist or is missing.", part_id)
                pdata.MissingItem = true

                missing_parts = missing_parts + 1
                idx = idx + 1
                break
            end

            -- Check if the part is hidden in the mechanic overlay and mark it as nodisplay.
            -- TsarATA's parts are nodisplay but also displayable, so still loop them!
            if  sbvars.DoIgnoreHiddenParts
            and part:getCategory() == "nodisplay"
            and (sbvars.DoCompatTsarMod == false
                or ATA2TuningTable == false
                or ATA2TuningTable[vehicle_id] == false
                or ATA2TuningTable[vehicle_id].parts[part_id] == false) then
                logger:debug("Part (%s) is nodisplay.", part_id)

                pdata.NoDisplay = true
                idx = idx + 1
                break
            end

            -- TODO: Find out what this does!
            local item_types = part:getItemType()
            if item_types == nil or item_types:isEmpty() then
                logger:debug("Part (%s) type is empty.", part_id)

                if part_condition < 100 then
                    logger:debug("Part (%s) is damaged.", part_id)
                    damaged_parts = damaged_parts + 1
                end

                idx = idx + 1
                break
            end

            -- Set the part item type to use.
            local item_type = part_item:getFullType()
            logger:debug("Setting part (%s) item type to (%s).", part_id, item_type)
            pdata.ItemFullType = item_type

            -- Set the part item's weight.
            local item_weight = part_item:getWeight()
            logger:debug("Setting part (%s) item weight to (%f).", part_id, item_weight)
            pdata.ItemWeight = item_weight
            weight = weight + item_weight

            -- Sync the part's mod data.
            local part_mdata = part:getModData()
            if part:hasModData() and part_mdata then
                pdata.ModData = aoqia_table.shallow_copy(part_mdata)
            end

            -- If the part holds fluids, set the container content.
            if part:isContainer() and part:getItemContainer() == nil then
                local amount = part:getContainerContentAmount()

                logger:debug("Setting part (%s) content to (%d).",
                    part_id,
                    amount)
                pdata.Content = amount
            end

            -- The part is a battery, set the delta.
            if part_item:IsDrainable() then
                local delta = part_item:getUsedDelta()

                logger:debug("Setting part (%s) delta to (%d).",
                    part_id,
                    delta)
                pdata.Delta = delta
            end

            -- Count broken parts
            if part_condition < 100 or part_item:getCondition() < 100 then
                damaged_parts = damaged_parts + 1
            end

            idx = idx + 1
        until true
    end

    logger:debug("Vehicle part item weights combined: (%d)", weight)
    logger:debug("Total vehicle weight calculated: (%d)", weight + vehicle_script:getMass())

    mdata.PartsDamaged = damaged_parts
    mdata.PartsMissing = missing_parts

    -- Remove form item if required.
    if sbvars.DoRequiresAutoForm then
        logger:debug("Removing form from inventory...")

        local form = player_inventory:getFirstTypeRecurse(mod_constants.MOD_ID .. ".AutoForm")
        --- @diagnostic disable-next-line: param-type-mismatch
        form:getContainer():Remove(form)
    end

    -- Give the player the pinkslip.
    --- @diagnostic disable-next-line: param-type-mismatch
    local _ = player_inventory:AddItem(pinkslip)

    -- Remove the vehicle from the world.
    local args = { vehicle = self.vehicle:getId() }
    sendClientCommand(self.character, "vehicle", "remove", args)

    -- Spawn a replacement vehicle somewhere as to repopulate the vehicles in the world.
    if UdderlyVehicleRespawn and sbvars.DoCompatUdderlyRespawn then
        UdderlyVehicleRespawn.SpawnRandomVehicleSomewhere()
    end

    ISBaseTimedAction.perform(self)
end

function create_pinkslip:stop()
    if self.sound ~= 0 then
        self.character:getEmitter():stopSound(self.sound)
    end

    ISBaseTimedAction.stop(self)
end

function create_pinkslip:start()
    self:setActionAnim("VehicleWorkOnMid")
    self.sound = self.character:playSound("CreatePinkslip")
end

--- @param character IsoPlayer
--- @param vehicle BaseVehicle
--- @return CreatePinkslipAction
function create_pinkslip:new(character, vehicle)
    --- @class CreatePinkslipAction: ISBaseTimedAction
    local o = {}

    setmetatable(o, self)
    self.__index = self

    o.stopOnWalk = true
    o.stopOnRun = true
    o.character = character
    o.vehicle = vehicle
    o.maxTime = character:isTimedActionInstant() and 1 or 600

    return o
end

return create_pinkslip
