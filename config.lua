Config = {}

-- ====================================================================
-- LANGUAGE
-- Possible values: 'tr', 'en', 'ja', 'ar', 'es', 'fr', 'it', 'pt', 'ru', 'de'
-- UI texts are displayed in the selected language.
--   tr = Turkish
--   en = English
--   ja = Japanese
--   ar = Arabic
--   es = Spanish
--   fr = French
--   it = Italian
--   pt = Portuguese
--   ru = Russian
--   de = German
-- To add a new language, create e.g. locales/XX.lua and set the code here.
-- ====================================================================
Config.Language = 'tr'

-- ====================================================================
-- BLACKLISTED VEHICLES
-- Vehicles in this list cannot be given.
-- Use lowercase codes. Examples: 'rhino', 'tank', 'hydra'
-- ====================================================================
Config.BlacklistedVehicles = {
    'rhino',
    'tank',
    'hydra',
}

-- ====================================================================
-- FRAMEWORK
-- Supported: 'qb' (QBCore), 'esx' (ESX)
-- ====================================================================
Config.Framework = 'qb'

-- ====================================================================
-- DISCORD ID WHITELIST
-- Only the Discord IDs listed here are authorized to use the menu.
-- To get an ID (without a bot): enable Discord developer mode,
-- right-click the user -> Copy ID
-- ====================================================================
Config.AllowedDiscordIds = {
    '768584435721306133',
}

-- ====================================================================
-- COMMAND
-- Command and default key to open the UI
-- ====================================================================
Config.Command = 'givecar'
Config.KeyMapping = 'F6'
Config.KeyMappingDesc = 'Vehicle Give Menu'

-- ====================================================================
-- PLATE SETTINGS
-- ====================================================================
Config.Plate = {
    -- If the plate is left empty, it is generated automatically
    AutoGenerateIfEmpty = true,
    -- Length of the auto-generated plate (max 8)
    Length = 8,
    -- Character pool for the auto-generated plate
    Charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",
    -- When the vehicle is given to the target player, should it be
    -- stored in the garage or spawned in front of them?
    -- 'garage' => only saved to DB (taken out from garage)
    -- 'spawn'  => the vehicle is spawned in front of the selected player
    --             (color + full fuel are applied)
    GiveMode = 'garage',
}

-- ====================================================================
-- LIMITS
-- ====================================================================
Config.Limits = {
    -- Client-side validation so invalid vehicle codes cannot be entered
    ValidateModel = true,
    -- The same plate cannot be given twice
    UniquePlate = true,
}

-- ====================================================================
-- CHARACTER ANIMATION (PAPER - PEN)
-- When the menu is opened the character plays an animation and holds a
-- clipboard. Set Config.PedAnimation = false to disable it.
-- ====================================================================
Config.PedAnimation = true
Config.PedAnimationDict = 'missheistdockssetup1clipboard@idle_a'
Config.PedAnimationName = 'idle_a'
Config.PedProp = 'p_amb_clipboard_01'
