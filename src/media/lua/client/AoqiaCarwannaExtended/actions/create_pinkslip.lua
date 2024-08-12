-- -------------------------------------------------------------------------- --
--                          Vehicle UI tooltip stuff                          --
-- -------------------------------------------------------------------------- --

-- AoqiaCarwannaExtended requires.
local mod_constants = require("AoqiaCarwannaExtended/mod_constants")

-- TIS globals.
local ISBaseTimedAction = ISBaseTimedAction
local Metabolics = Metabolics
local SandboxVars = SandboxVars

local logger = mod_constants.LOGGER

-- ------------------------------ Module Start ------------------------------ --

local action_id = mod_constants.MOD_ID .. "_create_pinkslip"

--- @class CreatePinkslipAction: ISBaseTimedAction
--- @field character IsoPlayer
--- @field vehicle BaseVehicle
local create_pinkslip = ISBaseTimedAction:derive(action_id)

function create_pinkslip:is_part_missing(part)
    local part_type = part:getItemType()
    return part_type and part_type:isEmpty() == false and part:getInventoryItem() == nil
end

function create_pinkslip:isValid()
    return self.vehicle and self.vehicle:isRemovedFromWorld() == false
end

function create_pinkslip:waitToStart()
    self.character:faceThisObject(self.vehicle)
    return self.character:shouldBeTurning()
end

function create_pinkslip:update()
    self.character:faceThisObject(self.vehicle)
    self.character:setMetabolicTarget(Metabolics.LightDomestic)

    if self.character:getEmitter():isPlaying(self.sound) == false then
        self.sound = self.character:playSound("CreatePinkslip")
    end
end

function create_pinkslip:perform()
    local sbvars = SandboxVars[mod_constants.MOD_ID] --[[@as SandboxVarsDummy]]

    if self.sound ~= 0 then
        self.character:getEmitter():stopSound(self.sound)
    end

    local vehicle_script = self.vehicle:getScript()
    local vehicle_id = vehicle_script:getName()
    local vehicle_name = getText("IGUI_VehicleName" .. vehicle_id) or "NULL_TRANSLATION"

    local player_inventory = self.character:getInventory()
    local pinkslip = player_inventory:AddItem("AoqiaCarwannaExtended.Pinkslip")
    pinkslip:setName("Pinkslip: " .. vehicle_name .. " (used)")

    local mdata = pinkslip:getModData() --[[@as ModDataDummy]]
    mdata.BloodF = self.vehicle:getBloodIntensity("Front")
    mdata.BloodB = self.vehicle:getBloodIntensity("Rear")
    mdata.BloodL = self.vehicle:getBloodIntensity("Left")
    mdata.BloodR = self.vehicle:getBloodIntensity("Right")
    mdata.ColorH = self.vehicle:getColorHue()
    mdata.ColorS = self.vehicle:getColorSaturation()
    mdata.ColorV = self.vehicle:getColorValue()
    mdata.EngineQuality = self.vehicle:getEngineQuality()
    mdata.Hotwire = self.vehicle:isHotwired()
    mdata.Skin = self.vehicle:getSkinIndex()
    mdata.Rust = self.vehicle:getRust()
    mdata.VehicleId = vehicle_script:getFullName()
    mdata.VehicleName = vehicle_name

    local key = player_inventory:haveThisKeyId(self.vehicle:getKeyId())
    if key then
        mdata.HasKey = true
        key:getContainer():Remove(key)
    end

    mdata.Parts = mdata.Parts or {}
    local pdata = mdata.Parts

    local missing_parts = 0
    local broken_parts = 0
    for i = 1, self.vehicle:getPartCount() do
        -- Breaks are continue here!
        repeat
            local part = self.vehicle:getPartByIndex(i - 1)
            local item = part:getInventoryItem() --[[@as DrainableComboItem]]
            local item_type = part:getItemType()
            local item_condition = item:getCondition()
            local part_id = part:getId()
            local part_condition = part:getCondition()

            if  sbvars.DoIgnoreHiddenParts
            and part:getCategory() ~= "nodisplay"
            and sbvars.DoCompatTsarMod
            and ATA2TuningTable
            and ATA2TuningTable[vehicle_id]
            and ATA2TuningTable[vehicle_id].parts[part_id] then
                break
            end

            -- If the parts have items we can remove.
            if item_type and item_type:isEmpty() == false then
                pdata.partId.Condition = part_condition
                if part_condition < 100 then
                    broken_parts = broken_parts + 1
                end

                break
            end

            -- If part is missing.
            if item == nil then
                missing_parts = missing_parts + 1
                break
            end

            pdata.partId.Condition = item_condition
            pdata.partId.Item = item:getFullType()

            -- The part holds fluids.
            if part:isContainer() and part:getItemContainer() == nil then
                pdata.partId.Content = part:getContainerContentAmount()
            end

            -- The part is a battery.
            if item:IsDrainable() then
                pdata.partId.Delta = item:getUsedDelta()
            end

            -- TsarLib mod support
            local part_mdata = part:getModData()
            if  sbvars.DoCompatTsarMod
            and part_mdata.tuning2
            and part_mdata.tuning2.model then
                pdata.partId.Model = part_mdata.tuning2.model
            end

            -- Count broken parts
            if part_condition < 100 or item_condition < 100 then
                broken_parts = broken_parts + 1
            end
        until true
    end

    mdata.Broken = broken_parts
    mdata.Missing = missing_parts

    -- Give the player the pinkslip.
    player_inventory:AddItem(item)

    -- Remove form item if required.
    if sbvars.DoRequiresForm then
        local form = player_inventory:getFirstTypeRecurse("AutoForm")
        form:getContainer():Remove(form)
    end

    -- Remove the vehicle from the world.
    local args = { vehicle = self.vehicle:getId() }
    sendClientCommand(self.character, "vehicle", "remove", args)

    if UdderlyVehicleRespawn and sbvars.DoCompatUdderlyRespawn then
        -- TODO: Implement.
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
    --- @type CreatePinkslipAction
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
