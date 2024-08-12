-- -------------------------------------------------------------------------- --
--                   Stores constants to be used everywhere.                  --
-- -------------------------------------------------------------------------- --

local logger = require("AoqiaZomboidUtils/logger")

-- ------------------------------ Module Start ------------------------------ --

local mod_constants = {}

mod_constants.MOD_ID = "AoqiaCarwannaExtended"
mod_constants.MOD_VERSION = "0.0.1"

mod_constants.LOGGER = logger:new(mod_constants.MOD_ID)

mod_constants.FUELTANK_NAMES = { "500FuelTank", "1000FuelTank" }

--- @class ModDataDummy
--- @field Battery unknown
--- @field Blood {}
--- @field BloodF unknown
--- @field BloodB unknown
--- @field BloodL unknown
--- @field BloodR unknown
--- @field Broken unknown
--- @field Clear unknown
--- @field Color { H: float, S: float, V: float}
--- @field ColorH float
--- @field ColorS float
--- @field ColorV float
--- @field Condition integer
--- @field Dir IsoDirections
--- @field EngineQuality unknown
--- @field FuelTank integer
--- @field GasTank unknown
--- @field HasKey boolean
--- @field Hotwire boolean
--- @field IsBlacklisted boolean
--- @field LootChance integer
--- @field MakeKey boolean
--- @field Missing unknown
--- @field OtherTank unknown
--- @field Parts unknown
--- @field Rust unknown
--- @field Skin unknown
--- @field TirePsi integer
--- @field Type string
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
--- @field DoLootTables boolean
--- @field DoRegistration boolean
--- @field DoRequiresAllParts boolean
--- @field DoRequiresForm boolean
--- @field DoRequiresKey boolean
--- @field DoShowAllParts boolean
--- @field DoZedLoot boolean
--- @field FormLootChance float
--- @field LootBlacklist string
--- @field LootChance float
--- @field MinimumCondition integer
--- @field PartWhitelist string
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
    DoLootTables = true,
    DoRegistration = true,
    DoRequiresAllParts = true,
    DoRequiresForm = true,
    DoRequiresKey = true,
    DoShowAllParts = false,
    DoZedLoot = true,
    FormLootChance = 1.0,
    LootBlacklist = "",
    LootChance = 1.0,
    MinimumCondition = 100,
    PartWhitelist = "",
    TrailerBlacklist = "",
    VehicleBlacklist = "",
    ZedLootChance = 0.01,
    -- Mod Compatibility :D
    DoCompatColorExperimental = false,
    DoCompatTsarMod = false,
    DoCompatUdderlyRespawn = false,
}

return mod_constants
