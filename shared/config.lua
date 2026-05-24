--[[
    devkit — Config
    Author:  DevGbag
    GitHub:  https://github.com/DevGbag
    Org:     https://github.com/DevGeorge-oss
    License: MIT
]]

Config = {}

--[[
    ResourceFolder — the bracket folder devkit scans for resources.
    Change this to match your server's resource folder name.
    Examples: '[DevKit]', '[custom]', '[scripts]', '[resources]'
]]
Config.ResourceFolder = '[YOUR_FOLDER_NAME]'

--[[
    Keybind — default key to open the devkit menu in game.
    Can also be rebound by the player in FiveM keybind settings.
]]
Config.Keybind = 'F9'

--[[
    AdminOnly — if true, only players with the 'command' ace
    permission can open the menu. Recommended: true.
]]
Config.AdminOnly = true
