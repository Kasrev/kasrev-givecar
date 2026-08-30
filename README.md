# kasrev-givecar

A FiveM admin menu to give vehicles to players. Opens a clean NUI panel where you enter the
target player ID, vehicle code, plate and colors, then the vehicle is given to the selected
player (saved to their garage or spawned in front of them).

## Features

- NUI panel opened with **F6** or the **/givecar** command
- Fields: target player ID, vehicle code, plate, plate color, vehicle RGB color
- **Full fuel** on the given vehicle
- **Blacklist** for forbidden vehicles
- **Discord ID whitelist** authorization (only whitelisted Discord IDs can use the menu)
- **5 second cooldown** per admin to prevent spam
- **Language support**: `tr`, `en`, `ja`, `ar`, `es`, `fr`, `it`, `pt`, `ru`, `de`
- Character plays a paper/pen (clipboard) animation while the menu is open
- Sound on/off toggle in the top-right corner
- `ox_lib` notifications for invalid vehicle codes and missing player ID
- Configurable give mode: store in garage or spawn in front of the player

## Requirements

- A supported framework: **QBCore** (`qb-core`) or **ESX** (`es_extended`)
- **oxmysql** (database access)
- **ox_lib** (used for notifications; falls back to framework notifications if missing)

## Installation

1. Drop the `kasrev-givecar` folder into your server's `resources` directory.
2. Add `ensure kasrev-givecar` to your `server.cfg` (after `qb-core`/`es_extended` and `oxmysql`).
3. Restart the server.

## Configuration

All settings are in `config.lua`.

### Language

```lua
Config.Language = 'en' -- tr, en, ja, ar, es, fr, it, pt, ru, de
```

To add a new language, create `locales/XX.lua` returning the same keys and set the code here.

### Authorization (Discord ID only)

Only the Discord IDs listed below are allowed to use the menu.

```lua
Config.AllowedDiscordIds = {
    '768584435721306133',
}
```

To get a Discord ID: enable Discord **Developer Mode**, right-click the user -> **Copy ID**.

> Admin groups were removed; authorization is handled exclusively through this whitelist.

### Framework

```lua
Config.Framework = 'qb' -- 'qb' or 'esx'
```

### Blacklisted vehicles

```lua
Config.BlacklistedVehicles = {
    'rhino',
    'tank',
    'hydra',
}
```

### Command & key

```lua
Config.Command = 'givecar'
Config.KeyMapping = 'F6'
Config.KeyMappingDesc = 'Vehicle Give Menu'
```

### Plate settings

```lua
Config.Plate = {
    AutoGenerateIfEmpty = true, -- generate a plate if left empty
    Length = 8,                -- max 8
    Charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",
    GiveMode = 'garage',       -- 'garage' = save to DB, 'spawn' = spawn in front of player
}
```

- `GiveMode = 'garage'` saves the vehicle to the player's garage only.
- `GiveMode = 'spawn'` spawns the vehicle in front of the selected player with the chosen
  RGB color and full fuel applied.

### Limits

```lua
Config.Limits = {
    ValidateModel = true,  -- reject invalid vehicle codes client-side
    UniquePlate = true,    -- reject already-used plates
}
```

### Character animation

```lua
Config.PedAnimation = true
Config.PedAnimationDict = 'missheistdockssetup1clipboard@idle_a'
Config.PedAnimationName = 'idle_a'
Config.PedProp = 'p_amb_clipboard_01'
```

Set `Config.PedAnimation = false` to disable the clipboard animation.

## Usage

1. Press **F6** (or type `/givecar`) as a whitelisted Discord user.
2. Fill in the **player ID**, **vehicle code** (e.g. `adder`, `zentorno`), and optionally a **plate**.
3. Pick a **plate color** and a **vehicle RGB color** (round color swatch).
4. Click **GIVE VEHICLE**. The menu closes automatically on success.

## Notes

- The vehicle RGB color is stored as `customPrimaryColor` / `customSecondaryColor` in the
  vehicle properties. When `GiveMode = 'spawn'` the color and full fuel are applied directly.
- For `garage` mode, the color is saved with the vehicle data; whether it renders depends on
  the garage system reading those fields.
