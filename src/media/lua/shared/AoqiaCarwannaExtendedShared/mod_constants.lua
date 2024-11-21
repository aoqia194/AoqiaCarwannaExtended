-- -------------------------------------------------------------------------- --
--                   Stores constants to be used everywhere.                  --
-- -------------------------------------------------------------------------- --

local logger = require("AoqiaZomboidUtilsShared/logger")

-- ------------------------------ Module Start ------------------------------ --

local mod_constants = {}

mod_constants.MOD_ID = "AoqiaCarwannaExtended"
mod_constants.MOD_VERSION = "0.4.0"

mod_constants.LOGGER = logger:new(mod_constants.MOD_ID)

mod_constants.FUELTANK_NAMES = { "500FuelTank", "1000FuelTank" }

-- ---------------------------- Class Definitions --------------------------- --

--- @class (exact) PartIdDummy
--- @field Condition int | nil The part's condition. Most parts have this.
--- @field Content float | nil The part container's content amount, like GasTank.
--- @field Delta float | nil The delta for parts like Battery that have % remaining delta.
--- @field EngineLoudnessMultiplier int | nil The muffler's loudness multiplier.
--- @field ItemFullType string | nil The Module.Name string of the part item.
--- @field ItemWeight float The weight of the part item.
--- @field LockBroken boolean | nil If the part can and should have its lock broken.
--- @field Locked boolean | nil If the part can and should be locked.
--- @field MissingItem boolean | nil If the part item is missing.
--- @field ModData table<any, any> | nil The part's mod data table to be replicated.
--- @field NoDisplay boolean | nil If the part is marked as nodisplay.
--- @field Open boolean | nil If the part can and should be opened.
--- @field Temperature int | nil The temperate for the Heater part.
--- @field Type string | nil The Name string of the part.

--- @class (exact) PartsDummy
--- @field index int[] | nil An array of part indexes.
--- @field values PartIdDummy[] | nil An array of part data.

--- The Pinkslip item mod data struct.
--- @class (exact) ModDataDummy
--- @field Blood { F: float, B: float, L: float, R: float }
--- @field Color { H: float, S: float, V: float }
--- @field Dir IsoDirections The direction the vehicle is facing.
--- @field EngineLoudness int
--- @field EnginePower int
--- @field EngineQuality int
--- @field HasKey boolean | nil If true, there is a key in the ignition.
--- @field HeadlightsActive boolean | nil
--- @field HeaterActive boolean | nil
--- @field Hotwired boolean | nil
--- @field FullType string The Module.Name string of the vehicle.
--- @field MakeKey boolean | nil If true, make a key for the player when claiming.
--- @field ModData table<any, any> | nil Mod data table to be replicated to the vehicle object when spawned.
--- @field Name string | nil The legible name of the vehicle.
--- @field Parts PartsDummy | nil
--- @field PartsDamaged int
--- @field PartsMissing int
--- @field PinkslipWeight float | nil The dynamic weight of the pinkslip item.
--- @field Rust float
--- @field Skin int

--- The SandboxVars mod data struct.
--- @class (exact) SandboxVarsDummy
--- Global Toggles
--- @field DoRegistration boolean
--- @field DoAdminOverride boolean
--- Auto Form
--- @field DoRequiresAutoForm boolean
--- @field DoKeepAutoForm boolean
--- @field DoAutoFormLoot boolean
--- @field AutoFormLootChance float
--- Pinkslip
--- @field DoPinkslipLoot boolean
--- @field PinkslipLootChance float
--- @field DoDynamicPinkslipWeight boolean
--- @field PinkslipWeight float
--- @field PinkslipGeneratedBlacklist string
--- @field DoUnassignInterior boolean
--- @field PinkslipGeneratedChances string
--- Main Vehicle Stuff
--- @field DoVehicleLoot boolean
--- @field DoCanHotwire boolean
--- @field DoClearInventory boolean
--- @field DoRequiresUnclaimed boolean
--- @field DoFixHiddenParts boolean
--- @field DoIgnoreHiddenParts boolean
--- @field DoAllowGeneratedPinkslips boolean
--- @field DoRequiresAllParts boolean
--- @field DoRequiresRepairedParts boolean
--- @field MinimumCondition int
--- @field DoRequiresKey boolean
--- @field DoShowAllParts boolean
--- @field PartWhitelist string
--- @field TrailerBlacklist string
--- @field VehicleBlacklist string
--- Safehouse
--- @field DoSafehouseOnly boolean
--- @field SafehouseDistance int
--- Zombie Loot
--- @field DoZedLoot boolean
--- @field ZedLootChance float
--- Mod Compatibility
--- @field DoCompatRvInteriors boolean
--- @field DoCompatTsarMod boolean
--- @field DoCompatUdderlyRespawn boolean
--- @field DoCompatColorExperimental boolean

return mod_constants
