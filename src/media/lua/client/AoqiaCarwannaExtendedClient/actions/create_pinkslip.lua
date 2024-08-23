-- -------------------------------------------------------------------------- --
--                          Vehicle UI tooltip stuff                          --
-- -------------------------------------------------------------------------- --

-- AoqiaCarwannaExtended requires.
local mod_constants = require("AoqiaCarwannaExtendedShared/mod_constants")

-- TIS globals.
local getText = getText
local ISBaseTimedAction = ISBaseTimedAction
local Metabolics = Metabolics
local SandboxVars = SandboxVars
local sendClientCommand = sendClientCommand

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
    mdata.Blood = mdata.Blood or {}
    mdata.Color = mdata.Color or {}
    mdata.Parts = mdata.Parts or {}

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
    mdata.Hotwire = self.vehicle:isHotwired()
    mdata.LockedDoor = self.vehicle:isAnyDoorLocked()
    mdata.LockedTrunk = self.vehicle:isTrunkLocked()
    mdata.Skin = self.vehicle:getSkinIndex()
    mdata.Rust = self.vehicle:getRust()
    mdata.VehicleId = vehicle_script:getFullName()
    mdata.VehicleName = vehicle_name

    local key = player_inventory:haveThisKeyId(self.vehicle:getKeyId())
    if key and mdata.HasKey == false then
        mdata.MakeKey = true
        player_inventory:Remove(key)
    end

    local pdata = mdata.Parts

    local missing_parts = 0
    local broken_parts = 0
    for i = 1, self.vehicle:getPartCount() do
        -- Breaks are continue here!
        repeat
            local part = self.vehicle:getPartByIndex(i - 1)
            local part_id = part:getId()
            local part_condition = part:getCondition()

            local item = part:getInventoryItem() --[[@as DrainableComboItem | nil]]
            if item == nil then
                logger:debug("Item of part %s does not exist or is missing.", part_id)
                missing_parts = missing_parts + 1

                break
            end

            local item_type = part:getItemType()
            local item_condition = item:getCondition()

            if  sbvars.DoIgnoreHiddenParts
            and part:getCategory() ~= "nodisplay"
            and sbvars.DoCompatTsarMod
            and ATA2TuningTable
            and ATA2TuningTable[vehicle_id]
            and ATA2TuningTable[vehicle_id].parts[part_id] then
                break
            end

            --- @diagnostic disable-next-line
            pdata[part_id] = {}
            local piddata = pdata[part_id]

            -- If the part has mod data to sync.
            local part_mdata = part:getModData()
            if part_mdata then piddata.ModData = part_mdata end

            -- If the parts have items we can remove.
            if item_type and item_type:isEmpty() == false then
                piddata.Condition = part_condition
                if part_condition < 100 then
                    broken_parts = broken_parts + 1
                end

                break
            end

            piddata.Condition = item_condition
            piddata.Item = item:getFullType()

            -- The part holds fluids.
            if part:isContainer() and part:getItemContainer() == nil then
                piddata.Content = part:getContainerContentAmount()
            end

            -- The part is a battery.
            if item:IsDrainable() then
                piddata.Delta = item:getUsedDelta()
            end

            -- TsarLib mod support
            -- if  sbvars.DoCompatTsarMod
            -- and part_mdata.tuning2
            -- and part_mdata.tuning2.model then
            --     piddata.Model = part_mdata.tuning2.model
            -- end

            -- Count broken parts
            if part_condition < 100 or item_condition < 100 then
                broken_parts = broken_parts + 1
            end

            break
        until true
    end

    mdata.PartsBroken = broken_parts
    mdata.PartsMissing = missing_parts

    -- Remove form item if required.
    if sbvars.DoRequiresForm and sbvars.DoKeepForm then
        local form = player_inventory:getFirstTypeRecurse("AutoForm")
        form:getContainer():Remove(form)
    end

    -- Give the player the pinkslip.
    --- @diagnostic disable-next-line
    player_inventory:AddItem(pinkslip)

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
