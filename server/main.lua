--[[
    devkit — In-game Developer Debug Menu
    Author:  DevGbag
    GitHub:  https://github.com/DevGbag
    Org:     https://github.com/DevGeorge-oss
    License: MIT
]]

--[[
    DEVKIT — SERVER
    ─────────────────────────────────────────────────────────────
    Scans Config.ResourceFolder for resources.
    Handles restart/start/stop/give item commands from the UI.
    Only accessible to players with the admin ace permission.
    ─────────────────────────────────────────────────────────────
]]

-- ── Admin check ───────────────────────────────────────────────
local function IsAdmin(src)
    return IsPlayerAceAllowed(src, 'command')
end

local function Log(src, msg, level)
    print(('^3[devkit]^7 %s'):format(msg))
    TriggerClientEvent('devkit:log', src, msg, level or 'info')
end

-- ── Get resource state label ──────────────────────────────────
local function GetStateLabel(name)
    local state = GetResourceState(name)
    if state == 'started'  then return 'running' end
    if state == 'stopped'  then return 'stopped' end
    if state == 'starting' then return 'starting' end
    if state == 'stopping' then return 'stopping' end
    return 'missing'
end

-- ── Scan Config.ResourceFolder for resources ─────────────────
--[[
    We iterate all running/known resources and filter to those
    whose path contains Config.ResourceFolder
    by checking GetResourcePath.

    FiveM doesn't give us a direct folder listing API so we
    iterate GetNumResources() / GetResourceByFindIndex()
    and check each resource's path.
]]
local function GetDevkitResources()
    local results = {}
    local count   = GetNumResources()

    for i = 0, count - 1 do
        local name = GetResourceByFindIndex(i)
        if name and name ~= '' and name ~= 'devkit' then
            local path = GetResourcePath(name)
            -- Check if resource lives inside Config.ResourceFolder
            local folderPattern = Config.ResourceFolder:gsub('[%[%]]', '%%%1')
            if path and path:find(folderPattern) then
                -- Build resource metadata
                local state = GetStateLabel(name)

                -- Try to read fxmanifest description
                local description = GetResourceMetadata(name, 'description', 0) or ''
                local version     = GetResourceMetadata(name, 'version', 0)     or '?'

                -- Build debug commands list from resource metadata
                -- Resources can declare debug commands in metadata:
                -- set devkit_commands "giveall,reset,test"
                local cmdStr   = GetResourceMetadata(name, 'devkit_commands', 0) or ''
                local commands = {}
                for cmd in cmdStr:gmatch('[^,]+') do
                    table.insert(commands, cmd:match('^%s*(.-)%s*$'))
                end

                -- Build item list from metadata:
                -- set devkit_items "pl_hackingdevice,pl_drill,pl_rope"
                local itemStr = GetResourceMetadata(name, 'devkit_items', 0) or ''
                local items   = {}
                for item in itemStr:gmatch('[^,]+') do
                    table.insert(items, item:match('^%s*(.-)%s*$'))
                end

                table.insert(results, {
                    name        = name,
                    state       = state,
                    description = description,
                    version     = version,
                    commands    = commands,
                    items       = items,
                    path        = path,
                })
            end
        end
    end

    -- Sort alphabetically
    table.sort(results, function(a, b) return a.name < b.name end)
    return results
end

-- ── Player data for UI header ─────────────────────────────────
local function GetPlayerData(src)
    local name = GetPlayerName(src) or 'Unknown'
    local ids  = GetPlayerIdentifiers(src)
    local id   = ids and ids[1] or 'unknown'
    return { name = name, id = id, source = src }
end

-- ── Events ────────────────────────────────────────────────────

RegisterNetEvent('devkit:requestResources')
AddEventHandler('devkit:requestResources', function()
    local src = source
    if not IsAdmin(src) then
        TriggerClientEvent('devkit:log', src, 'Access denied — admin only', 'error')
        return
    end
    local resources  = GetDevkitResources()
    local playerData = GetPlayerData(src)
    TriggerClientEvent('devkit:receiveResources', src, resources, playerData)
end)

RegisterNetEvent('devkit:restartResource')
AddEventHandler('devkit:restartResource', function(name)
    local src = source
    if not IsAdmin(src) then return end
    if not name or name == '' then return end

    Log(src, ('Restarting resource: %s'):format(name), 'warn')
    StopResource(name)
    Wait(500)
    StartResource(name)
    Wait(300)

    -- Send updated resource list back
    TriggerClientEvent('devkit:resourceStateUpdate', src, GetDevkitResources())
    Log(src, ('Resource restarted: %s [%s]'):format(name, GetStateLabel(name)), 'success')
end)

RegisterNetEvent('devkit:startResource')
AddEventHandler('devkit:startResource', function(name)
    local src = source
    if not IsAdmin(src) then return end
    if not name or name == '' then return end

    Log(src, ('Starting resource: %s'):format(name), 'info')
    StartResource(name)
    Wait(300)

    TriggerClientEvent('devkit:resourceStateUpdate', src, GetDevkitResources())
    Log(src, ('Resource started: %s [%s]'):format(name, GetStateLabel(name)), 'success')
end)

RegisterNetEvent('devkit:stopResource')
AddEventHandler('devkit:stopResource', function(name)
    local src = source
    if not IsAdmin(src) then return end
    if not name or name == '' then return end
    if name == 'devkit' then
        Log(src, 'Cannot stop devkit from within itself', 'error')
        return
    end

    Log(src, ('Stopping resource: %s'):format(name), 'warn')
    StopResource(name)
    Wait(300)

    TriggerClientEvent('devkit:resourceStateUpdate', src, GetDevkitResources())
    Log(src, ('Resource stopped: %s'):format(name), 'success')
end)

RegisterNetEvent('devkit:giveItems')
AddEventHandler('devkit:giveItems', function(items)
    local src = source
    if not IsAdmin(src) then return end
    if type(items) ~= 'table' then return end

    for _, item in pairs(items) do
        local name   = item.name
        local amount = tonumber(item.amount) or 1
        if name and name ~= '' then
            local ok = exports.ox_inventory:AddItem(src, name, amount)
            if ok then
                Log(src, ('Gave %dx %s'):format(amount, name), 'success')
            else
                Log(src, ('Failed to give %s — item not registered?'):format(name), 'error')
            end
        end
    end
end)

RegisterNetEvent('devkit:runCommand')
AddEventHandler('devkit:runCommand', function(command)
    local src = source
    if not IsAdmin(src) then return end
    if not command or command == '' then return end

    Log(src, ('Running command: /%s'):format(command), 'info')
    -- Execute as if the player typed it in chat
    ExecuteCommand(('invoke-direct %s %s'):format(src, command))
end)

-- ── Server console give command ───────────────────────────────
-- Usage in txAdmin: devkit_give [playerid] [item] [amount]
RegisterCommand('devkit_give', function(source, args)
    local targetId = tonumber(args[1])
    local item     = args[2]
    local amount   = tonumber(args[3]) or 1
    if not targetId or not item then
        print('^1[devkit] Usage: devkit_give [playerid] [item] [amount]^7')
        return
    end
    exports.ox_inventory:AddItem(targetId, item, amount)
    print(('^2[devkit] Gave %dx %s to player %s^7'):format(amount, item, targetId))
end, true)

print('^2[devkit] Server ready. Admin only — press F9 in game.^7')
