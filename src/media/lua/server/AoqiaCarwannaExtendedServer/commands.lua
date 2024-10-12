-- -------------------------------------------------------------------------- --
--                       Sandbox Options Blacklist Stuff                      --
-- -------------------------------------------------------------------------- --

-- AoqiaCarwannaExtended requires.
local aq_math = require("AoqiaZomboidUtilsShared/math")
local mod_constants = require("AoqiaCarwannaExtendedShared/mod_constants")

-- std globals.
local tostring = tostring

-- TIS globals cache.
local addVehicleDebug = addVehicleDebug
local getText = getText
local InventoryItemFactory = InventoryItemFactory
local SandboxVars = SandboxVars
local ScriptManager = ScriptManager.instance
local VehicleUtils = VehicleUtils

local logger = mod_constants.LOGGER

-- ------------------------------ Module Start ------------------------------ --

local commands = {}

--- @param player IsoPlayer
--- @param args ModDataDummy
function commands.spawn_vehicle(player, args)
    local sbvars = SandboxVars[mod_constants.MOD_ID] --[[@as SandboxVarsDummy]]

    local x = player:getX()
    local y = player:getY()
    local z = player:getZ()
    local square = player:getSquare()

    logger:info_server("Spawning vehicle (%s) at (%f, %f, %f).", tostring(args.Id), x, y, z)

    -- Check if vehicle exists
    if ScriptManager:getVehicle(args.Id) == nil then
        logger:info_server("Failed to spawn vehicle as the vehicle does not exist.")
        player:setHaloNote(getText(
            ("IGUI_%s_HaloNote_NilVehicle"):format(mod_constants.MOD_ID)
        ))

        return
    end

    -- Check if player has AutoForm
    if  player:getAccessLevel() ~= "Admin"
    and player:getInventory():containsTypeRecurse("AutoForm") == false then
        logger:info_server("Failed to spawn vehicle as the player does not have an AutoForm.")
        player:setHaloNote(getText(
            ("IGUI_%s_HaloNote_NoAutoForm"):format(mod_constants.MOD_ID)
        ))

        return
    end

    -- Check if vehicle is already in that position.
    if square:isVehicleIntersecting() then
        logger:info_server("Failed to spawn vehicle, there is already a vehicle spawned there.")
        player:setHaloNote(getText(
            ("IGUI_%s_HaloNote_VehicleIntersecting"):format(mod_constants.MOD_ID)
        ))

        return
    end

    if args.Dir == nil then
        args.Dir = player and player:getDir() or IsoDirections.S
    end

    if args.Skin == nil then
        args.Skin = -1
    end

    local exp_vehicle = nil --- @type VehicleScript
    local exp_target = nil  --- @type string
    if args.Color and sbvars.DoCompatColorExperimental then
        exp_vehicle = ScriptManager:getVehicle(args.Id)
        exp_target = args.Id:match("[^.]*.(.*)")

        exp_vehicle:Load(exp_target,
            ("{ forcedColor = %f %f %f, }"):format(args.Color.H, args.Color.S, args.Color.V))
    end

    local vehicle = addVehicleDebug(args.Id, args.Dir, args.Skin, square)
    local vehicle_id = vehicle:getId()
    logger:info_server("Vehicle created with name (%s) and ID (%s).",
        vehicle:getScriptName(),
        tostring(vehicle_id))

    if args.Color and sbvars.DoCompatColorExperimental == false then
        logger:debug_server("Setting vehicle colour to (%f, %f, %f).", args.Color.H, args.Color.S,
            args.Color.V)
        vehicle:setColorHSV(args.Color.H, args.Color.S, args.Color.V)
        vehicle:transmitColorHSV()
    end

    if args.Rust then
        logger:debug_server("Setting rust to (%f).", args.Rust)
        vehicle:setRust(args.Rust)
        vehicle:transmitRust()
    end

    if args.Blood then
        logger:debug_server("Setting blood to (%f, %f, %f, %f).",
            args.Blood.F, args.Blood.B, args.Blood.L, args.Blood.R)
        -- NOTE: Original mod checks for 0 here. I think it's not necessary.
        vehicle:setBloodIntensity("Front", args.Blood.F)
        vehicle:setBloodIntensity("Rear", args.Blood.B)
        vehicle:setBloodIntensity("Left", args.Blood.L)
        vehicle:setBloodIntensity("Right", args.Blood.R)
    end

    if exp_vehicle and exp_target then
        logger:debug_server("Loading vehicle script (%s).", exp_target)
        exp_vehicle:Load(exp_target, "{ forcedColor = -1 -1 -1, }")
    end

    if args.EngineQuality or args.EngineLoudness or args.EnginePower then
        logger:debug_server("Setting engine to (%d, %d, %d)",
            args.EngineQuality,
            args.EngineLoudness,
            args.EnginePower)
        vehicle:setEngineFeature(args.EngineQuality, args.EngineLoudness, args.EnginePower)
        vehicle:transmitEngine()
    end

    if args.Hotwired then
        logger:debug_server("Setting hotwired to true.")
        vehicle:setHotwired(true)
    end

    if args.HasKey then
        logger:debug_server("Setting keys in ignition to true.")
        vehicle:setKeysInIgnition(true)
    end

    -- Give the player a key.
    if args.MakeKey and args.HasKey == nil then
        logger:debug_server("Attempting to give the player a key.")

        local new_key = vehicle:createVehicleKey()
        if new_key == nil then
            logger:warn_server("Failed to create vehicle key.")
        end

        if player then
            -- This might be bugging out. For some reason, it spawns the key in the player's grid square.
            logger:debug_server("Giving the player a key.")
            --- @diagnostic disable-next-line: redundant-parameter
            player:sendObjectChange("addItem", { item = new_key })
        else
            logger:warn_server("Failed to give the player a key as they are nil!")
            --- @diagnostic disable-next-line
            square:AddWorldInventoryItem(new_key, x, y, z)
        end
    end

    -- Clear the vehicle inventory. For some reason, addVehicleDebug
    -- populates the inventory of trunk and glovebox.
    if sbvars.DoVehicleLoot == false then
        local container_count = vehicle:getContainerCount()
        for i = 1, container_count do
            local cont = vehicle:getContainerByIndex(i - 1)
            if cont and cont:isEmpty() == false then
                logger:debug_server("Clearing container (%s) with type (%s).", i, cont:getType())
                cont:clear()
            end
        end
    end

    local parts = args.Parts
    if parts == nil
    or parts.index == nil
    or parts.values == nil then
        logger:debug_server("Parts data was nil.")
        return
    end

    -- Only player-created pinkslips have parts.
    -- Also, this goes 1 -> part_count whereas the mod data stores part id as the part index.
    -- So if we have only 1 part with part index 2, this will not work.
    for i = 1, #parts.index do
        repeat
            -- break is continue here!
            local idx = parts.index[i]

            local part = vehicle:getPartByIndex(idx)
            local part_cat = part:getCategory()
            local part_id = part:getId()
            local part_type = part:getItemType()

            local part_mdata = part:getModData()

            logger:debug_server("Looping through parts with part (%s).", part_id)

            -- Check if it's a hidden part in the mechanic overlay.
            -- NOTE: This check is complex and I dont fully understand it so it's possibly broken.
            if  sbvars.DoIgnoreHiddenParts
            and part_cat == "nodisplay"
            and (sbvars.DoCompatTsarMod == false
                or ATA2TuningTable == nil
                or ATA2TuningTable[vehicle_id] == nil
                or ATA2TuningTable[vehicle_id].parts[part_id] == nil) then
                if sbvars.DoFixHiddenParts then
                    logger:debug_server("Fixing hidden part (%s).", part_id)

                    part:setCondition(100)
                    vehicle:transmitPartCondition(part)
                else
                    logger:debug_server("Ignoring hidden part (%s).", part_id)
                end

                break
            end

            -- If it is a part that cannot be removed.
            if part_type == nil or part_type:isEmpty() then
                if parts and parts.values[i] then
                    local new_val = parts.values[i].Condition
                    if new_val then
                        logger:debug_server("Setting part condition to (%d).", new_val)

                        part:setCondition(new_val)
                        vehicle:transmitPartCondition(part)
                    end
                end

                logger:debug_server("The part is not removable.")
                break
            end

            local part_item = part:getInventoryItem() --[[@as DrainableComboItem]]
            local part_container = part:getItemContainer()

            logger:debug_server("Found part (%s) with item (%s).", part_id, part_item:getName())

            -- Remove part that doesn't exist on pinkslip.
            local pdata = parts.values[i] --[[@as PartIdDummy]]
            if pdata == nil then
                logger:debug_server("Removing part (%s) because it does not exist on the pinkslip.",
                    part_id)

                -- TsarATA support
                if  sbvars.DoCompatTsarMod
                and ATA2TuningTable
                and ATA2TuningTable[vehicle_id]
                and ATA2TuningTable[vehicle_id].parts[part_id] then
                    part_mdata.tuning2 = {}
                    ATATuning2Utils.ModelByItemName(vehicle, part)
                end

                --- @diagnostic disable-next-line
                part:setInventoryItem(nil)

                local tbl = part:getTable("uninstall")
                if tbl and tbl.complete then
                    VehicleUtils.callLua(tbl.complete, vehicle, part)
                end

                logger:debug_server("Transmitting uninstalled part item...")
                vehicle:transmitPartItem(part)
                break
            end

            -- If the part installed is not the expected part, uninstall it and install the expected part.

            local part_item_type = part_item and part_item:getFullType() or nil
            if part_item and part_item_type and part_item_type ~= pdata.FullType then
                logger:debug_server("Swapping parts (%s) and (%s).", tostring(part_item_type),
                    tostring(pdata.FullType))

                --- @diagnostic disable-next-line
                part:setInventoryItem(nil)
                vehicle:transmitPartItem(part)

                local item = InventoryItemFactory.CreateItem(pdata.FullType)
                part:setInventoryItem(item)
                if sbvars.DoCompatTsarMod and pdata.Model then
                    logger:debug_server("Attempting to set Tsar model for part (%s).", part_item_type)

                    part_mdata.tuning2.model = pdata.Model
                    -- vehicle:transmitPartModData(part)
                    ATATuning2Utils.ModelByItemName(vehicle, part, part_item)
                end

                local tbl = part:getTable("install")
                if tbl and tbl.complete then
                    -- FIXME: This when called with radio part raises error.
                    VehicleUtils.callLua(tbl.complete, vehicle, part)
                end

                logger:debug_server("Transmitting installed part item...")
                vehicle:transmitPartItem(part)
            end

            -- Set part condition
            logger:debug_server("Setting part condition to (%d).", pdata.Condition)
            part:setCondition(pdata.Condition)
            vehicle:transmitPartCondition(part)

            -- Directly from original mod author: "fix this bullshit".
            -- If part is a door, fix the lock and set the door lock/door opened.
            local part_door = part:getDoor()
            if part_door then
                if pdata.Open and part_door:isOpen() == false then
                    logger:debug_server("Opening part (%s) door.", part_id)
                    part_door:setOpen(true)
                end

                if pdata.LockBroken and part_door:isLockBroken() == false then
                    logger:debug_server("Fixing part (%s) door.", part_id)
                    part_door:setLockBroken(true)
                end

                if pdata.Locked and part_door:isLocked() == false then
                    logger:debug_server("Locking part (%s) door.", part_id)
                    part_door:setLocked(true)
                end

                vehicle:transmitPartDoor(part)
            end

            -- Parts that hold items usually spawn with stuff.
            if  sbvars.DoClearInventory
            and part_container
            and part_container:getItems():size() > 0 then
                logger:debug_server("Removing all items from part (%s).", part_id)
                part_container:removeAllItems()
            end

            -- Parts can hold things like gas, fire, air(??????)
            local content = pdata.Content
            if content then
                logger:debug_server("Setting part container (%s) content to (%d).", part_id, content)
                part:setContainerContentAmount(content)

                local wheel_idx = part:getWheelIndex()
                if wheel_idx ~= -1 then
                    logger:debug_server("Setting tire pressure at idx (%d).", wheel_idx)
                    vehicle:setTireInflation(wheel_idx, part:getContainerContentAmount())
                end
            end

            -- Author said batteries are the only parts that use `delta`.
            local delta = pdata.Delta
            if delta and part_item then
                logger:debug_server("Setting part delta to (%f).", delta)
                part_item:setUsedDelta(delta)
                vehicle:transmitPartUsedDelta(part)
            end

            vehicle:transmitPartModData(part)

            break
        until true
    end
end

return commands
