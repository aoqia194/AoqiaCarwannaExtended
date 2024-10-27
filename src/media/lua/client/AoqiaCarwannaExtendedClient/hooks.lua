-- -------------------------------------------------------------------------- --
--                             Hook stuff for fun                             --
-- -------------------------------------------------------------------------- --

local mod_constants = require("AoqiaCarwannaExtendedShared/mod_constants")
local pinkslip = require("AoqiaCarwannaExtendedClient/ui/pinkslip")
local tooltip = require("AoqiaCarwannaExtendedClient/ui/tooltip")

-- TIS globals.
local ISToolTipInv = ISToolTipInv
local ISVehicleMenu = ISVehicleMenu

local logger = mod_constants.LOGGER

-- ------------------------------ Module Start ------------------------------ --

local hooks = {}

hooks.o_fill_menu = nil
hooks.o_tooltip_render = nil

--- @param player_num integer
--- @param context ISContextMenu
--- @param vehicle BaseVehicle
--- @param test boolean
function hooks.fill_menu(player_num, context, vehicle, test)
    hooks.o_fill_menu(player_num, context, vehicle, test)
    pinkslip.add_option_to_menu(getSpecificPlayer(player_num), context, vehicle)
end

function hooks.tooltip_render()
    tooltip.render(ISToolTipInv)
end

function hooks.register()
    logger:debug("Hooking FillMenuOutsideVehicle")
    hooks.o_fill_menu = ISVehicleMenu.FillMenuOutsideVehicle
    ISVehicleMenu.FillMenuOutsideVehicle = hooks.fill_menu

    logger:debug("Hooking ISToolTipInv.render")
    hooks.o_tooltip_render = ISToolTipInv.render
    ISToolTipInv.render = tooltip.render
    tooltip.o_tooltip_render = hooks.o_tooltip_render
end

return hooks
