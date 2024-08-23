-- -------------------------------------------------------------------------- --
--                          Vehicle UI tooltip stuff                          --
-- -------------------------------------------------------------------------- --

-- AoqiaCarwannaExtended requires.
local aoqia_math = require("AoqiaZomboidUtilsShared/math")
local mod_constants = require("AoqiaCarwannaExtendedShared/mod_constants")

-- TIS globals.
local getCore = getCore
local getMouseX = getMouseX
local getMouseY = getMouseY
local getTextManager = getTextManager
local ISContextMenu = ISContextMenu
local ISToolTipInv = ISToolTipInv
local SandboxVars = SandboxVars

local logger = mod_constants.LOGGER

-- ------------------------------ Module Start ------------------------------ --

local tooltip = {}

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

local text_manager = nil

--- @param self self
--- @param hard_width? float
function tooltip.render_override(self, hard_width)
    if ISContextMenu.instance and ISContextMenu.instance.visibleCheck then
        return
    end

    local mx = getMouseX() + 24
    local my = getMouseY() + 24

    if self.followMouse == false then
        mx = self:getX()
        my = self:getY()

        if self.anchorBottomLeft then
            mx = self.anchorBottomLeft.x
            my = self.anchorBottomLeft.y
        end
    end

    self.tooltip:setX(mx + 11)
    self.tooltip:setY(my)
    self.tooltip:setWidth(50)
    self.tooltip:setMeasureOnly(true)
    self.item:DoTooltip(self.tooltip)
    self.tooltip:setMeasureOnly(false)

    local tw = self.tooltip:getWidth()
    local th = self.tooltip:getHeight()

    self.tooltip:setX(aoqia_math.max(0, aoqia_math.min(mx + 11, screen_width - tw - 1)))
    if self.followMouse == false and self.anchorBottomLeft then
        self.tooltip:setY(aoqia_math.max(0, aoqia_math.min(my - th, screen_height - th - 1)))
    else
        self.tooltip:setY(aoqia_math.max(0, aoqia_math.min(my, screen_height - th - 1)))
    end

    self:setX(self.tooltip:getX() - 11)
    self:setY(self.tooltip:getY())
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

tooltip.o_render = ISToolTipInv.render
--- @diagnostic disable-next-line: duplicate-set-field
function ISToolTipInv:render()
    if ISContextMenu.instance and ISContextMenu.instance.visibleCheck then
        return
    end

    local item = self.item
    if item == nil or item:getType() ~= "AutoTitle" then
        tooltip.o_render(self)
        return
    end

    if text_manager == nil then
        text_manager = getTextManager()
    end

    local sbvars = SandboxVars[mod_constants.MOD_ID] --[[@as SandboxVarsDummy]]
    local mdata = item:getModData() --[[@as ModDataDummy]]

    local text = getText("IGUI_AoqiaCarwannaExtended_Tooltip",
        tostring(mdata.EngineQuality),
        tostring(mdata.PartsBroken),
        tostring(mdata.Skin),
        tostring(mdata.HasKey),
        tostring(mdata.Hotwire)
    ) or "NULL_TRANSLATION"

    if sbvars.DoShowAllParts then
        for part, data in pairs(mdata.Parts) do
            text = ("%s%s %s"):format(text, getText("IGUI_VehiclePart" .. part),
                tostring(data.Condition))
        end
    end

    local text_width = aoqia_math.max(
        text_manager:MeasureStringX(font_type, item:getName()),
        text_manager:MeasureStringX(font_type, text))
    local text_height = text_manager:MeasureStringY(font_type, mdata.VehicleName)

    if text then
        text_height = text_height + text_manager:MeasureStringY(font_type, text) + 8
    end

    local tooltip_width = text_width + font_bounds
    tooltip.render_override(self, tooltip_width)

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
        aoqia_math.min(1, col_background.a + 0.4),
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
    local col_font = { a = 1.0, r = 0.9, g = 0.9, b = 0.9 }

    local y = (y_offset + (15 - line_height) / 2)
    self:drawText(mdata.VehicleName, x_offset, y, col_font.r, col_font.g, col_font.b,
        col_font.a, font_type)

    if text then
        y = y + (line_height * 1.5)
        self:drawText(text,
            x + 1,
            y,
            col_font.r,
            col_font.g,
            col_font.b,
            col_font.a,
            font_type)
    end

    y_offset = y_offset + 12
end

return tooltip
