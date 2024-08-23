-- -------------------------------------------------------------------------- --
--                   Stores constants to be used everywhere.                  --
-- -------------------------------------------------------------------------- --

local logger = require("AoqiaZomboidUtilsShared/logger")

-- ------------------------------ Module Start ------------------------------ --

local mod_constants = {}

mod_constants.MOD_ID = "AoqiaCarwannaExtended"
mod_constants.MOD_VERSION = "0.0.3"

mod_constants.LOGGER = logger:new(mod_constants.MOD_ID)

mod_constants.FUELTANK_NAMES = { "500FuelTank", "1000FuelTank" }

-- ---------------------------- Class Definitions --------------------------- --

--- @class (exact) PartIdDummy
--- @field Condition integer | int
--- @field Content float
--- @field Delta float
--- @field Item string
--- @field ModData table<any, any>
--- @field Model unknown
mod_constants.PARTID_DUMMY = {}

--- @class (exact) ModDataDummy
--- @field Battery integer | int
--- @field Blood { F: float, B: float, L: float, R: float}
--- @field Clear unknown
--- @field Color { H: float, S: float, V: float}
--- @field Condition integer | int
--- @field Dir IsoDirections
--- @field EngineLoudness integer | int
--- @field EnginePower integer | int
--- @field EngineQuality integer | int
--- @field FuelTank integer | int
--- @field GasTank integer | int
--- @field HasKey boolean
--- @field HeadlightsActive boolean
--- @field HeaterActive boolean
--- @field Hotwire boolean
--- @field IsBlacklisted boolean
--- @field LockedDoor boolean
--- @field LockedTrunk boolean
--- @field LootChance integer
--- @field MakeKey boolean
--- @field OtherTank integer | int
--- @field Parts { [string]: PartIdDummy }
--- @field PartsBroken integer | int
--- @field PartsMissing integer | int
--- @field Rust float
--- @field Skin integer | int
--- @field TirePsi integer
--- @field Upgrade boolean
--- @field VehicleId string
--- @field VehicleName string
mod_constants.MOD_DATA_DUMMY = {}

--- @class (exact) SandboxVarsDummy
--- @field DoAdminOverride boolean
--- @field DoCanHotwire boolean
--- @field DoClearInventory boolean
--- @field DoFixHiddenParts boolean
--- @field DoFormLoot boolean
--- @field DoIgnoreHiddenParts boolean
--- @field DoKeepForm boolean
--- @field DoLootTables boolean
--- @field DoRegistration boolean
--- @field DoRequiresAllParts boolean
--- @field DoRequiresForm boolean
--- @field DoRequiresKey boolean
--- @field DoSafehouseOnly boolean
--- @field DoShowAllParts boolean
--- @field DoZedLoot boolean
--- @field FormLootChance float
--- @field LootBlacklist string
--- @field LootChance float
--- @field MinimumCondition integer
--- @field PartWhitelist string
--- @field SafehouseDistance integer | int
--- @field TrailerBlacklist string
--- @field VehicleBlacklist string
--- @field ZedLootChance float
--- @field DoCompatColorExperimental boolean
--- @field DoCompatTsarMod boolean
--- @field DoCompatUdderlyRespawn boolean
mod_constants.SANDBOX_VARS_DUMMY = {
    DoAdminOverride = false,
    DoCanHotwire = true,
    DoClearInventory = true,
    DoFixHiddenParts = false,
    DoFormLoot = true,
    DoIgnoreHiddenParts = true,
    DoKeepForm = false,
    DoLootTables = true,
    DoRegistration = true,
    DoRequiresAllParts = true,
    DoRequiresForm = true,
    DoRequiresKey = true,
    DoSafehouseOnly = false,
    DoShowAllParts = false,
    DoZedLoot = true,
    FormLootChance = 1.0,
    LootBlacklist = "",
    LootChance = 1.0,
    MinimumCondition = 100,
    PartWhitelist = "",
    SafehouseDistance = 10,
    TrailerBlacklist = "",
    VehicleBlacklist = "",
    ZedLootChance = 0.01,
    -- Mod Compatibility :D
    DoCompatColorExperimental = false,
    DoCompatTsarMod = false,
    DoCompatUdderlyRespawn = false,
}

return mod_constants
