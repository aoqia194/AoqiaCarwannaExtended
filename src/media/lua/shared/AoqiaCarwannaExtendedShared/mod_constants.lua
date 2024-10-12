-- -------------------------------------------------------------------------- --
--                   Stores constants to be used everywhere.                  --
-- -------------------------------------------------------------------------- --

local logger = require("AoqiaZomboidUtilsShared/logger")

-- ------------------------------ Module Start ------------------------------ --

local mod_constants = {}

mod_constants.MOD_ID = "AoqiaCarwannaExtended"
mod_constants.MOD_VERSION = "0.1.0"

mod_constants.LOGGER = logger:new(mod_constants.MOD_ID)

mod_constants.FUELTANK_NAMES = { "500FuelTank", "1000FuelTank" }

-- ---------------------------- Class Definitions --------------------------- --

--- @class (exact) PartIdDummy
--- @field Condition int The part's condition. Most parts have this.
--- @field Content float The part container's content amount, like GasTank.
--- @field Delta float The delta for parts like Battery that have % remaining delta.
--- @field EngineLoudnessMultiplier int The muffler's loudness multiplier.
--- @field FullType string The full Module.Name string of the part.
--- @field LockBroken boolean If the part can and should have its lock broken.
--- @field Locked boolean If the part can and should be locked.
--- @field ModData table<any, any> The part's mod data.
--- @field Model unknown Some scuffed TsarMod stuff that I don't know about.
--- @field Open boolean If the part can and should be opened.
--- @field Temperature int The temperate for the Heater part.

--- @class (exact) PartsDummy
--- @field index int[] An array of part indexes.
--- @field values PartIdDummy[] An array of part dummy data.

--- The Pinkslip item mod data struct.
--- @class (exact) ModDataDummy
--- @field Blood { F: float, B: float, L: float, R: float}
--- @field Color { H: float, S: float, V: float}
--- @field Dir IsoDirections The direction the vehicle is facing.
--- @field EngineLoudness int
--- @field EnginePower int
--- @field EngineQuality int
--- @field HasKey boolean If true, there is a key in the ignition.
--- @field HeadlightsActive boolean
--- @field HeaterActive boolean
--- @field Hotwired boolean
--- @field Id string The Module.Name string of the vehicle.
--- @field IsBlacklisted boolean
--- @field MakeKey boolean If true, make a key for the player when claiming.
--- @field ModData table<any, any> Mod data table to be replicated to the vehicle when spawned.
--- @field Name string The legible name of the vehicle.
--- @field Parts PartsDummy | nil
--- @field PartsDamaged int
--- @field PartsMissing int
--- @field Rust float
--- @field Skin int
--- @field Weight float | nil The dynamic weight of the pinkslip item.

--- The SandboxVars mod data struct.
--- @class (exact) SandboxVarsDummy
--- @field AutoFormLootChance float
--- @field DoAdminOverride boolean
--- @field DoAutoFormLoot boolean
--- @field DoCanHotwire boolean
--- @field DoClearInventory boolean
--- @field DoFixHiddenParts boolean
--- @field DoIgnoreHiddenParts boolean
--- @field DoKeepForm boolean
--- @field DoPinkslipLoot boolean
--- @field DoDynamicPinkslipWeight boolean
--- @field PinkslipWeight float
--- @field DoRegistration boolean
--- @field DoAllowGeneratedPinkslips boolean
--- @field DoRequiresAllParts boolean
--- @field DoRequiresRepairedParts boolean
--- @field DoRequiresForm boolean
--- @field DoRequiresKey boolean
--- @field DoSafehouseOnly boolean
--- @field DoShowAllParts boolean
--- @field DoZedLoot boolean
--- @field DoVehicleLoot boolean
--- @field MinimumCondition int
--- @field PartWhitelist string
--- @field PinkslipLootBlacklist string
--- @field PinkslipLootChance float
--- @field SafehouseDistance int
--- @field TrailerBlacklist string
--- @field VehicleBlacklist string
--- @field ZedLootChance float
--- @field DoCompatColorExperimental boolean
--- @field DoCompatTsarMod boolean
--- @field DoCompatUdderlyRespawn boolean

return mod_constants
