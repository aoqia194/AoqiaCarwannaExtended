-- -------------------------------------------------------------------------- --
--                 Registers tweaks using the ItemTweakerAPI.                 --
-- -------------------------------------------------------------------------- --

local getScriptManager = getScriptManager

local mod_constants = require("AoqiaCarwannaExtendedShared/mod_constants")

local logger = mod_constants.LOGGER

-- ------------------------------ Module Start ------------------------------ --

local tweaks = {}

function tweaks.init()
    logger:debug_shared("Applying tweaks...")

    local sbvars = SandboxVars[mod_constants.MOD_ID] --[[@as SandboxVarsDummy]]

    local script_manager = getScriptManager()
    local tweak_table = {
        [mod_constants.MOD_ID .. ".Pinkslip"] = { ["Weight"] = sbvars.PinkslipWeight },
    }

    for tweak_item, data in pairs(tweak_table) do
        for prop, val in pairs(data) do
            local item = script_manager:getItem(tweak_item)
            if item then
                item:DoParam(prop .. " = " .. val)
            end
        end
    end
end

return tweaks
