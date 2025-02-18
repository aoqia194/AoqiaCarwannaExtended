local aoqia_table = require("AoqiaZomboidUtilsShared/table")
local mod_constants = require("AoqiaCarwannaExtendedShared/mod_constants")

local getCore = getCore
local getMouseX = getMouseX
local getMouseY = getMouseY
local getText = getText
local getTextManager = getTextManager
local ISContextMenu = ISContextMenu
local SandboxVars = SandboxVars

local logger = mod_constants.LOGGER

-- ------------------------------ Module Start ------------------------------ --

local tooltip = {}

--- @type function
tooltip.o_tooltip_render = nil

-- Font stuff
local font = getCore():getOptionTooltipFont()
local font_type = UIFont.NewMedium
local font_bounds = 32
if font == "Small" then
    font_type = UIFont.NewSmall
    font_bounds = 28
elseif font == "Large" then
    font_type = UIFont.NewLarge
    font_bounds = 42
end

-- Cached locals
local core = getCore()
local screen_width = core:getScreenWidth()
local screen_height = core:getScreenHeight()
local text_manager = getTextManager()

--- A modified version of the original render function.
--- @param self self
--- @param hard_width? float
function tooltip.modified_render(self, hard_width)
    if  ISContextMenu.instance
    and ISContextMenu.instance.visibleCheck then
        return
    end

    local mx = getMouseX() + 24
    local my = getMouseY() + 24

    if self.followMouse == false then
        mx = self.anchorBottomLeft and self.anchorBottomLeft.x or self:getX()
        my = self.anchorBottomLeft and self.anchorBottomLeft.y or self:getY()
    end

    self.tooltip:setX(mx + 11)
    self.tooltip:setY(my)
    self.tooltip:setWidth(50)
    self.tooltip:setMeasureOnly(true)
    self.item:DoTooltip(self.tooltip)
    self.tooltip:setMeasureOnly(false)

    local tw = self.tooltip:getWidth() --[[@as number]]
    local th = self.tooltip:getHeight() --[[@as number]]

    local v1 = mx + 11
    local v2 = (screen_width - tw) - 1
    local v3 = v1 < v2 and v1 or v2
    local x = v3 > 0 and v3 or 0

    v1 = (self.followMouse == false and self.anchorBottomLeft) and my - th or my
    v2 = (screen_height - th) - 1
    v3 = v1 < v2 and v1 or v2
    local y = v3 > 0 and v3 or 0

    self.tooltip:setX(x)
    self.tooltip:setY(y)

    self:setX(x - 11)
    self:setY(y)
    self:setWidth(hard_width or (tw + 11))
    self:setHeight(th)

    if self.followMouse then
        self:adjustPositionToAvoidOverlap({
            x = mx - 24 * 2,
            y = my - 24 * 2,
            width = 24 * 2,
            height = 24 * 2,
        })
    end

    self:drawRect(
        0,
        0,
        self.width,
        self.height,
        self.backgroundColor.a,
        self.backgroundColor.r,
        self.backgroundColor.g,
        self.backgroundColor.b)

    self:drawRectBorder(
        0,
        0,
        self.width,
        self.height,
        self.borderColor.a,
        self.borderColor.r,
        self.borderColor.g,
        self.borderColor.b)

    self.item:DoTooltip(self.tooltip)
end

--- My hooked render function
--- @param self ISToolTipInv
function tooltip.render(self)
    if tooltip.o_tooltip_render == nil
    or (ISContextMenu.instance and ISContextMenu.instance.visibleCheck) then
        return
    end

    local item = self.item --[[@as InventoryItem | nil]]
    if item == nil or item:getFullType() ~= (mod_constants.MOD_ID .. ".Pinkslip") then
        tooltip.o_tooltip_render(self)
        return
    end

    local mdata = aoqia_table.init_mdata(item, mod_constants.MOD_ID) --[[@as ModDataDummy | nil]]
    if mdata == nil or mdata.Name == nil then
        tooltip.o_tooltip_render(self)
        return
    end

    local text = getText(("IGUI_%s_VehicleName"):format(mod_constants.MOD_ID), mdata.Name or "nil")
        .. "\n"
        .. getText(("IGUI_%s_VehicleSkin"):format(mod_constants.MOD_ID), mdata.Skin or "nil")
        .. "\n"
        .. getText(("IGUI_%s_HasKey"):format(mod_constants.MOD_ID), mdata.HasKey and "Yes" or "No")
        .. "\n"
        .. getText(("IGUI_%s_Hotwired"):format(mod_constants.MOD_ID),
            mdata.Hotwired and "Yes" or "No")
        .. "\n"
        .. getText(("IGUI_%s_PartsMissing"):format(mod_constants.MOD_ID), mdata.PartsMissing)
        .. "\n"
        .. getText(("IGUI_%s_PartsDamaged"):format(mod_constants.MOD_ID), mdata.PartsDamaged)

    -- local parts = mdata.Parts
    -- if sbvars.DoShowAllParts and parts then
    --     for i = 1, #parts.index do
    --         local part = parts.index[i]
    --         local data = parts.values[i]

    --         text = text
    --             .. ("%s (%s)%% <LINE> "):format(
    --                 getText("IGUI_VehiclePart" .. part),
    --                 tostring(data.Condition))
    --     end
    -- else
    --     text = text
    --         .. getText(("IGUI_%s_PartsMissing"):format(mod_constants.MOD_ID), mdata.PartsMissing)
    --         .. getText(("IGUI_%s_PartsDamaged"):format(mod_constants.MOD_ID), mdata.PartsDamaged)
    -- end

    local v1 = self.tooltip:getWidth()
    local v2 = text_manager:MeasureStringX(font_type, text)
    local text_width = v1 > v2 and v1 or v2

    local text_height = text_manager:MeasureStringY(font_type, text) + 8
    local tooltip_width = text_width + font_bounds
    tooltip.modified_render(self, tooltip_width)
    local tooltip_height = self.tooltip:getHeight() - 1
    self:setX(self.tooltip:getX() - 11)

    if self.x <= 1 or self.y <= 1 then
        return
    end

    local x_offset = 15
    local y_offset = tooltip_height + 8

    local col_background = self.backgroundColor
    local col_border = self.borderColor

    self:drawRect(0,
        tooltip_height,
        tooltip_width,
        text_height + 8,
        col_background.a,
        col_background.r,
        col_background.g,
        col_background.b)

    self:drawRectBorder(0,
        tooltip_height,
        tooltip_width,
        text_height + 8,
        col_border.a,
        col_border.r,
        col_border.g,
        col_border.b)

    local line_height = text_manager:getFontFromEnum(font_type):getLineHeight()
    local col_font = { r = 0.9, g = 0.9, b = 0.9, a = 1.0 }

    y_offset = (y_offset + (15 - line_height) / 2)
    self:drawText(text,
        x_offset,
        y_offset,
        col_font.r,
        col_font.g,
        col_font.b,
        col_font.a,
        font_type)
end

return tooltip
