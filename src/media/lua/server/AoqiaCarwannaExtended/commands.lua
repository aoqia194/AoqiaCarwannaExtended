-- -------------------------------------------------------------------------- --
--                       Sandbox Options Blacklist Stuff                      --
-- -------------------------------------------------------------------------- --

-- AoqiaCarwannaExtended requires.
local constants = require("AoqiaZomboidUtils/constants")
local aoqia_math = require("AoqiaZomboidUtils/math")
local mod_constants = require("AoqiaCarwannaExtended/mod_constants")

-- TIS globals cache.
local InventoryItemFactory = InventoryItemFactory
local SandboxVars = SandboxVars
local VehicleUtils = VehicleUtils

local logger = mod_constants.LOGGER

-- Don't load server command stuff on client.
if  constants.IS_CLIENT
and constants.IS_SINGLEPLAYER == false
and constants.IS_COOP == false then
    return
end

-- ------------------------------ Module Start ------------------------------ --

local commands = {}

--- @param vehicle BaseVehicle
--- @param quality integer | int
function commands.set_engine_quality(vehicle, quality)
    quality = aoqia_math.clamp(quality, 0, 100)
    local script = vehicle:getScript()

    local loudness = script:getEngineLoudness()
    local force = script:getEngineForce()

    vehicle:setEngineFeature(quality, loudness, force)
    vehicle:transmitEngine()
end

--- @param player IsoPlayer
--- @param args ModDataDummy
function commands.spawn_vehicle(player, args)
    local script_manager = getScriptManager()
    local sbvars = SandboxVars[mod_constants.MOD_ID] --[[@as SandboxVarsDummy]]

    local x = player:getX()
    local y = player:getY()
    local z = player:getZ()

    logger:info_server("Spawning vehicle (%s) at (%f, %f, %f) by (%s).", args.Type, x, y, z,
        player:getUsername())

    local cell = getCell()
    local square = cell:getGridSquare(x, y, z)

    if args.Dir == nil then
        args.Dir = player and player:getDir() or IsoDirections.S
    end

    if args.Skin == nil then
        args.Skin = -1
    end

    local exp_vehicle = nil
    local exp_target = nil
    if args.Color and sbvars.DoCompatColorExperimental then
        exp_vehicle = script_manager:getVehicle(args.Type)
        exp_target = args.Type:match("[^.]*.(.*)")
        exp_vehicle:Load(exp_target, ("{ forcedColor = }"):format())
    end

    local vehicle = addVehicleDebug(args.Type, args.Dir, args.Skin, square)
    local vehicle_id = vehicle:getId()
    local vehicle_name = vehicle:getScript():getName()
    logger:info_server("Vehicle created with ID (%s).", vehicle_id)

    if args.Color and sbvars.DoCompatColorExperimental == false then
        logger:debug_server("Setting vehicle colour to (%f, %f, %f).", args.Color.H, args.Color.S,
            args.Color.V)
        vehicle:setColorHSV(args.Color.H, args.Color.S, args.Color.V)
        vehicle:transmitColorHSV()
    end

    if exp_vehicle and exp_target then
        exp_vehicle:Load(exp_target, "{ forcedColor = -1 -1 -1, }")
    end

    if args.EngineQuality then
        commands.set_engine_quality(vehicle, args.EngineQuality)
    end

    if args.Upgrade then
        vehicle:repair()
    end

    -- Fucking stupid part loop holy shit
    for i = 1, vehicle:getPartCount() do
        repeat
            -- break is continue here!

            local part = vehicle:getPartByIndex(i - 1)
            local part_cat = part:getCategory()
            local part_id = part:getId()
            local part_type = part:getItemType()

            -- Hidden parts in the mechanic overlay.
            if part_cat == "nodisplay"
            or (part_cat ~= "nodisplay" and sbvars.DoIgnoreHiddenParts)
            or (sbvars.DoCompatTsarMod and ATA2TuningTable and ATA2TuningTable[vehicle_id]) then
                if sbvars.DoFixHiddenParts then
                    part:setCondition(100)
                    vehicle:transmitPartCondition(part)
                end

                logger:debug_server("Skipping part (%s) because nodisplay.")
                break
            end

            if part_type == nil or part_type:isEmpty() then
                if args.Condition then
                    part:setCondition(args.Condition)
                    vehicle:transmitPartCondition(part)
                elseif args.Parts and args.Parts[part_id] then
                    local new_val = args.Parts[part_id]["Condition"]
                    if new_val then
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

                -- Remove items from vehicle if required.
                if  part_container
                and part_container:getItems():size() > 0
                and args.Clear then
                    part_container:removeAllItems()
                end

                -- Repair parts if required.
                if args.Condition then
                    part:setCondition(args.Condition)
                    part_item:setCondition(args.Condition)
                    vehicle:transmitPartCondition(part)
                end

                -- Repair door if required.
                if part_door and part_door:isLockBroken() then
                    logger:debug_server("Fixing door for part (%s)...", part_id)

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
                        part:setContainerContentAmount(aoqia_math.min(args.TirePsi, part_capacity))
                    elseif wheel_idx ~= -1 and args.TirePsi then
                        part:setContainerContentAmount(aoqia_math.min(args.TirePsi, part_capacity))
                        vehicle:setTireInflation(wheel_idx, part_content / part_capacity)
                    elseif args.OtherTank then
                        part:setContainerContentAmount(aoqia_math.min(args.OtherTank, part_capacity))
                    end
                end

                vehicle:transmitPartModData(part)
            else
                -- Process player-created pinkslips.

                local partdata = args.Parts[part_id]
                if partdata == nil then
                    logger:debug_server(
                        "Removing part (%s) because it does not exist on the pinkslip.", part_id)

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

                local part_item_type = part_item:getFullType()
                -- If part not already installed
                if part_item == nil or part_item_type ~= partdata["Item"] then
                    if part_item then
                        logger:debug_server("Swapping parts (%s) and (%s).", part_item_type,
                            partdata["Item"])

                        --- @diagnostic disable-next-line
                        part:setInventoryItem(nil)
                        vehicle:transmitPartItem(part)
                    else
                        logger:debug_server("Installing part (%s).", partdata["Item"])
                    end

                    local item = InventoryItemFactory.CreateItem(partdata["Item"])
                    part:setInventoryItem(item)

                    if sbvars.DoCompatTsarMod and partdata["Model"] then
                        logger:debug_server("Attempting to set Tsar model for part.")

                        local mdata = part:getModData()
                        mdata.tuning2.model = partdata["Model"]
                        -- vehicle:transmitPartModData(part)

                        ATATuning2Utils.ModelByItemName(vehicle, part, part_item)
                    end

                    local tbl = part:getTable("install")
                    if tbl and tbl.complete then
                        VehicleUtils.callLua(tbl.complete, vehicle, part)
                    end

                    vehicle:transmitPartItem(part)
                else
                    logger:debug_server("Part (%s) already installed.", partdata["Item"])
                end

                part:setCondition(partdata["Condition"])
                vehicle:transmitPartCondition(part)

                -- NOTE: Directly from original mod author: "fix this bullshit".
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
                local content = partdata["Content"]
                if content then
                    part:setContainerContentAmount(content)

                    local wheel_idx = part:getWheelIndex()
                    if wheel_idx ~= -1 then
                        logger:debug_server("Setting tire pressure at idx (%d)", wheel_idx)
                        vehicle:setTireInflation(wheel_idx, part:getContainerContentAmount())
                    end
                end

                -- Author said batteries only use delta
                local delta = partdata["Delta"]
                if delta and part_item then
                    part_item:setUsedDelta(delta)
                    vehicle:transmitPartUsedDelta(part)
                end

                vehicle:transmitPartModData(part)
            end
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

    -- Give the player a key
    if args.MakeKey then
        local new_key = vehicle:createVehicleKey()
        if new_key then
            if player then
                player:sendObjectChange("addItem", { item = new_key })
            else
                square:AddWorldInventoryItem(new_key:getType(), ZombRand(1, 5), ZombRand(1, 5), 0)
            end
        end
    end
end

return commands
