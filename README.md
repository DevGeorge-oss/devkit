# devkit — In-game developer debug menu for Qbox servers

A standalone in-game developer debug and resource management menu for FiveM servers. Scans a configurable resource folder and provides a UI to manage, test and debug resources without leaving the game.

## Features
- Auto-detects all resources inside your configured resource folder
- Start, stop and restart resources per tab
- Quick give items per resource via manifest metadata
- Teleport, coords copy, fix skin
- Live server console log inside the UI
- Run server commands from the UI
- Admin only — ace permission gated
- Fully configurable — set your own resource folder and keybind

## Dependencies
- [ox_lib](https://github.com/overextended/ox_lib)

## Installation
1. Extract to `resources/[your-folder]/devkit`
2. Add to `server.cfg`:
   ```
   ensure devkit
   ```
3. Set your resource folder in `shared/config.lua`:
   ```lua
   Config.ResourceFolder = '[your-folder]'
   ```
4. Make sure your admin ace is set:
   ```
   add_ace group.admin command allow
   add_principal identifier.fivem:YOURFIVEMID group.admin
   ```
5. Press **F9** in game to open (configurable)

## Configuration

All settings are in `shared/config.lua`:

```lua
Config.ResourceFolder = '[YOUR_FOLDER_NAME]'  -- folder to scan CHANGE THIS!!
Config.Keybind        = 'F9'         -- key to open menu
Config.AdminOnly      = true         -- admin only
```

## Declaring Resource Metadata

Resources inside your folder can declare items and commands for quick access in the devkit UI by adding these to their `fxmanifest.lua`:

```lua
-- Items that appear as quick-give buttons
set 'devkit_items' 'item_one,item_two,item_three'

-- Commands that appear as quick-run buttons
set 'devkit_commands' 'commandone,commandtwo'
```

## txAdmin Console Command

Give items to a player directly from txAdmin console:
```
devkit_give [playerid] [item] [amount]
```

## Keybind
Default: **F9** — can be rebound by the player in FiveM keybind settings in game.

<img width="858" height="548" alt="image" src="https://github.com/user-attachments/assets/c85c15da-c87c-4520-b182-7a4210824f0a" />


## Notes
- Designed for development servers, not production
- Admin only by default — players without the `command` ace cannot open the menu
- Console log shows server-side actions triggered from the UI

## Author
**DevGbag** — [GitHub](https://github.com/DevGbag) · [DevGeorge-oss](https://github.com/DevGeorge-oss)

## Licence
MIT — free to use, modify and distribute with attribution.
