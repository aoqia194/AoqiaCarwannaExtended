-- -------------------------------------------------------------------------- --
--                       Sandbox Options Blacklist Stuff                      --
-- -------------------------------------------------------------------------- --

-- AoqiaCarwannaExtended requires.
local aq_math = require("AoqiaZomboidUtilsShared/math")
local mod_constants = require("AoqiaCarwannaExtendedShared/mod_constants")

-- std globals.
local math = math
local tostring = tostring
-- TIS globals cache.
local addVehicleDebug = addVehicleDebug
local getCell = getCell
local getScriptManager = getScriptManager
local InventoryItemFactory = InventoryItemFactory
local SandboxVars = SandboxVars
local VehicleUtils = VehicleUtils
local ZombRand = ZombRand

local logger = mod_constants.LOGGER

-- ------------------------------ Module Start ------------------------------ --

local commands = {}

--- @param player IsoPlayer
--- @param args ModDataDummy
function commands.spawn_vehicle(player, args)
    local script_manager = getScriptManager()
    local sbvars = SandboxVars[mod_constants.MOD_ID] --[[@as SandboxVarsDummy]]

    local x = player:getX()
    local y = player:getY()
    local z = player:getZ()

    logger:info_server("Spawning vehicle (%s) at (%f, %f, %f) by (%s).",
        tostring(args.VehicleId),
        x,
        y,
        z,
        player:getUsername())

    if  player:getAccessLevel() ~= "Admin"
    and player:getInventory():containsTypeRecurse("AutoForm") == false then
        logger:info_server("Failed to spawn vehicle as the player does not have an AutoForm.")
        return
    end

    local cell = getCell()
    local square = cell:getGridSquare(x, y, z)
    if square:isVehicleIntersecting() then
        logger:info_server(
            "Failed to spawn vehicle as there is already a vehicle spawned at that location.")
        return
    end

    if args.Dir == nil then
        args.Dir = player and player:getDir() or IsoDirections.S
    end

    if args.Skin == nil then
        args.Skin = -1
    end

    local exp_vehicle = nil
    local exp_target = nil
    if args.Color and sbvars.DoCompatColorExperimental then
        exp_vehicle = script_manager:getVehicle(args.VehicleId)
        exp_target = args.VehicleId:match("[^.]*.(.*)")

        exp_vehicle:Load(exp_target,
            ("{ forcedColor = %f %f %f, }"):format(args.Color.H, args.Color.S, args.Color.V))
    end

    local vehicle = addVehicleDebug(args.VehicleId, args.Dir, args.Skin, square)
    local vehicle_id = vehicle:getId()
    logger:info_server("Vehicle created with name (%s) and ID (%s).",
        tostring(vehicle:getScriptName()), tostring(vehicle_id))

    if args.Color and sbvars.DoCompatColorExperimental == false then
        logger:debug_server("Setting vehicle colour to (%f, %f, %f).", args.Color.H, args.Color.S,
            args.Color.V)
        vehicle:setColorHSV(args.Color.H, args.Color.S, args.Color.V)
        vehicle:transmitColorHSV()
    end

    if exp_vehicle and exp_target then
        exp_vehicle:Load(exp_target, "{ forcedColor = -1 -1 -1, }")
    end

    if args.EngineQuality and args.EngineLoudness and args.EnginePower then
        logger:debug_server("Setting engine to (%d, %d, %d)",
            args.EngineQuality,
            args.EngineLoudness,
            args.EnginePower)
        vehicle:setEngineFeature(args.EngineQuality, args.EngineLoudness, args.EnginePower)
        vehicle:transmitEngine()
    end

    if args.Upgrade then
        vehicle:repair()
    end

    -- Fucking stupid part loop holy shit.
    for i = 1, vehicle:getPartCount() do
        repeat
            -- break is continue here!

            local part = vehicle:getPartByIndex(i - 1)
            local part_cat = part:getCategory()
            local part_id = part:getId()
            local part_type = part:getItemType()

            -- Hidden parts in the mechanic overlay.
            if part_cat == "nodisplay"
            or (sbvars.DoIgnoreHiddenParts and part_cat == "nodisplay")
            or (sbvars.DoCompatTsarMod and ATA2TuningTable and ATA2TuningTable[vehicle_id]) then
                if sbvars.DoFixHiddenParts then
                    logger:debug_server("Fixing hidden part (%s).", part_id)
                    part:setCondition(100)
                    vehicle:transmitPartCondition(part)
                else
                    logger:debug_server("Ignoring part (%s) because nodisplay.", part_id)
                end

                break
            end

            -- If it is a part that cannot be removed.
            if part_type == nil or part_type:isEmpty() then
                if args.Condition then
                    logger:debug_server("Setting condition to (%d).", args.Condition)

                    part:setCondition(args.Condition)
                    vehicle:transmitPartCondition(part)
                elseif args.Parts and args.Parts[part_id] then
                    local new_val = args.Parts[part_id].Condition
                    if new_val then
                        logger:debug_server("Setting part condition to (%d).", new_val)

                        part:setCondition(new_val)
                        vehicle:transmitPartCondition(part)
                    end
                end

                break
            end

            local part_item = part:getInventoryItem() --[[@as DrainableComboItem]]
            local part_container = part:getItemContainer()
            local part_door = part:getDoor()

            if args.Parts == nil then
                -- Process pre-created(?) pinkslips.
                if part_item == nil then break end

                -- Remove items from installed vehicle part if required.
                if  part_container
                and part_container:getItems():size() > 0
                and args.Clear then
                    logger:debug_server("Removing items from part container %s.", part_id)
                    part_container:removeAllItems()
                end

                -- Repair parts if required.
                if args.Condition then
                    logger:debug_server("Repairing part %s.", part_id)

                    part:setCondition(args.Condition)
                    part_item:setCondition(args.Condition)
                    vehicle:transmitPartCondition(part)
                end

                -- Repair door if required.
                if part_door and part_door:isLockBroken() then
                    logger:debug_server("Fixing door for part %s.", part_id)

                    part_door:setLockBroken(false)
                    vehicle:transmitPartDoor(part)
                end

                -- Set the charge on all battery-type items.
                if  part_item:IsDrainable()
                and args.Battery
                and part_id:contains("Battery") then
                    part_item:setUsedDelta(args.Battery)
                end

                if part:isContainer() and part_container == nil then
                    local part_capacity = part:getContainerCapacity()
                    local part_content = part:getContainerContentAmount()

                    local wheel_idx = part:getWheelIndex()
                    if part_id == "GasTank" and args.GasTank then
                        logger:debug_server("Setting gas tank to %d.", args.GasTank)
                        part:setContainerContentAmount(math.min(args.GasTank, part_capacity))
                    elseif wheel_idx ~= -1 and args.TirePsi then
                        logger:debug_server("Setting tire psi to %d.", args.TirePsi)
                        part:setContainerContentAmount(math.min(args.TirePsi, part_capacity))
                        vehicle:setTireInflation(wheel_idx, part_content / part_capacity)
                    elseif args.OtherTank then
                        logger:debug_server("Setting other tank to %d.", args.OtherTank)
                        part:setContainerContentAmount(math.min(args.OtherTank, part_capacity))
                    end
                end

                logger:debug_server("Transmitting part mod data.")
                vehicle:transmitPartModData(part)
                break
            end

            -- Process player-created pinkslips.

            -- Remove part that doesn't exist on pinkslip.
            local pdata = args.Parts[part_id]
            if pdata == nil then
                logger:debug_server("Removing part %s because it does not exist on the pinkslip.",
                    part_id)

                -- TsarATA support
                if  sbvars.DoCompatTsarMod
                and ATA2TuningTable
                and ATA2TuningTable[vehicle_id]
                and ATA2TuningTable[vehicle_id].parts[part_id] then
                    part:getModData().tuning2 = {}
                    ATATuning2Utils.ModelByItemName(vehicle, part)
                end

                -- NOTE: Is this even valid????
                --- @diagnostic disable-next-line
                part:setInventoryItem(nil)

                local tbl = part:getTable("uninstall")
                if tbl and tbl.complete then
                    VehicleUtils.callLua(tbl.complete, vehicle, part)
                end

                vehicle:transmitPartItem(part)
                break
            end

            -- If part not already installed

            local part_item_type = part_item:getFullType()
            if part_item == nil or part_item_type ~= pdata.Item then
                logger:debug_server("Swapping parts (%s) and (%s).", tostring(part_item_type),
                    tostring(pdata.Item))

                --- @diagnostic disable-next-line
                part:setInventoryItem(nil)
                vehicle:transmitPartItem(part)

                local item = InventoryItemFactory.CreateItem(pdata.Item)
                part:setInventoryItem(item)
                if sbvars.DoCompatTsarMod and pdata.Model then
                    logger:debug_server("Attempting to set Tsar model for part (%s).", part_item_type)

                    part:getModData().tuning2.model = pdata.Model
                    -- vehicle:transmitPartModData(part)
                    ATATuning2Utils.ModelByItemName(vehicle, part, part_item)
                end

                local tbl = part:getTable("install")
                if tbl and tbl.complete then
                    VehicleUtils.callLua(tbl.complete, vehicle, part)
                end

                vehicle:transmitPartItem(part)
            end

            part:setCondition(pdata["Condition"])
            vehicle:transmitPartCondition(part)

            -- Directly from original mod author: "fix this bullshit".
            if part_door and part_door:isLockBroken() then
                logger:debug_server("Fixing part door with part id (%s).", part_id)

                part_door:setLockBroken(false)
                --- @diagnostic disable-next-line
                vehicle:transmitPartDoor(part_door)
            end

            -- Parts that hold items usually spawn with stuff.
            -- Thus, we need to clear the items.
            if  part_container
            and part_container:getItems():size() > 0
            and args.Clear then
                part_container:removeAllItems()
            end

            -- Parts can hold things like gas, fire, air(??????)
            local content = pdata.Content
            if content then
                part:setContainerContentAmount(content)

                local wheel_idx = part:getWheelIndex()
                if wheel_idx ~= -1 then
                    logger:debug_server("Setting tire pressure at idx (%d).", wheel_idx)
                    vehicle:setTireInflation(wheel_idx, part:getContainerContentAmount())
                end
            end

            -- Author said batteries only use `delta`.
            local delta = pdata.Delta
            if delta and part_item then
                part_item:setUsedDelta(delta)
                vehicle:transmitPartUsedDelta(part)
            end

            vehicle:transmitPartModData(part)

            break
        until true
    end

    if args.Rust then
        vehicle:setRust(args.Rust)
        vehicle:transmitRust()
    end

    if args.Blood then
        -- NOTE: Original mod checks for 0 here. I think it's not necessary.
        vehicle:setBloodIntensity("Front", args.Blood.F)
        vehicle:setBloodIntensity("Rear", args.Blood.B)
        vehicle:setBloodIntensity("Left", args.Blood.L)
        vehicle:setBloodIntensity("Right", args.Blood.R)
    end

    if args.Hotwire then
        vehicle:setHotwired(true)
    end

    if args.HasKey then
        logger:debug("Setting keys in ignition to true.")
        vehicle:setKeysInIgnition(true)
    end

    -- Give the player a key.
    if args.MakeKey and args.HasKey == false then
        local new_key = vehicle:createVehicleKey()
        if new_key then
            if player then
                player.sendObjectChange("addItem", { item = new_key })
                return
            end

            square:AddWorldInventoryItem(new_key:getType(), ZombRand(1, 5), ZombRand(1, 5), 0)
        end
    end
end

return commands
