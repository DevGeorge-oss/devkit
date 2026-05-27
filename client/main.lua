--[[
    devkit — In-game Developer Debug Menu
    Author:  DevGbag
    GitHub:  https://github.com/DevGbag
    Org:     https://github.com/DevGeorge-oss
    License: MIT
]]

--[[
    ██████╗ ███████╗██╗   ██╗ ██████╗ ██████╗  █████╗  ██████╗ 
    ██╔══██╗██╔════╝██║   ██║██╔════╝ ██╔══██╗██╔══██╗██╔════╝ 
    ██║  ██║█████╗  ██║   ██║██║  ███╗██████╔╝███████║██║  ███╗
    ██║  ██║██╔══╝  ╚██╗ ██╔╝██║   ██║██╔══██╗██╔══██║██║   ██║
    ██████╔╝███████╗ ╚████╔╝ ╚██████╔╝██████╔╝██║  ██║╚██████╔╝
    ╚═════╝ ╚══════╝  ╚═══╝   ╚═════╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ 
]]

--[[
    DEVKIT DEBUG — CLIENT
    ─────────────────────────────────────────────────────────────
    Opens/closes the debug UI with F9 (configurable).
    Sends resource list to NUI on open.
    Handles all NUI callbacks for debug actions.
    ─────────────────────────────────────────────────────────────
]]

local isOpen = false

-- ── Open / Close ──────────────────────────────────────────────
local function CloseDebugMenu()
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function OpenDebugMenu()
    isOpen = true
    TriggerServerEvent('devkit:requestResources')
end

-- ── Keybind F9 ────────────────────────────────────────────────
RegisterCommand('devkit', function()
    if isOpen then CloseDebugMenu() else OpenDebugMenu() end
end, false)

RegisterKeyMapping('devkit', 'Open DevKit Menu', 'keyboard', Config.Keybind)

-- ── Receive resource list from server ─────────────────────────
RegisterNetEvent('devkit:receiveResources')
AddEventHandler('devkit:receiveResources', function(resources, playerData)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action    = 'open',
        resources = resources,
        player    = playerData,
    })
end)

-- ── NUI Callbacks ─────────────────────────────────────────────

RegisterNUICallback('close', function(_, cb)
    CloseDebugMenu()
    cb('ok')
end)

RegisterNUICallback('restartResource', function(data, cb)
    TriggerServerEvent('devkit:restartResource', data.resource)
    cb('ok')
end)

RegisterNUICallback('startResource', function(data, cb)
    TriggerServerEvent('devkit:startResource', data.resource)
    cb('ok')
end)

RegisterNUICallback('stopResource', function(data, cb)
    TriggerServerEvent('devkit:stopResource', data.resource)
    cb('ok')
end)

RegisterNUICallback('giveItems', function(data, cb)
    TriggerServerEvent('devkit:giveItems', data.items)
    cb('ok')
end)

RegisterNUICallback('teleport', function(data, cb)
    local x, y, z = tonumber(data.x), tonumber(data.y), tonumber(data.z)
    if x and y and z then
        SetEntityCoords(PlayerPedId(), x, y, z, false, false, false, false)
        lib.notify({ title = 'DevKit', description = ('Teleported to %.1f %.1f %.1f'):format(x, y, z), type = 'success' })
    end
    cb('ok')
end)

RegisterNUICallback('fixSkin', function(_, cb)
    local hash = GetHashKey('mp_m_freemode_01')
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end
    SetPlayerModel(PlayerPedId(), hash)
    SetPedDefaultComponentVariation(PlayerPedId())
    lib.notify({ title = 'Popcorn', description = 'Skin reset to default', type = 'success' })
    cb('ok')
end)

RegisterNUICallback('getCoords', function(_, cb)
    local c = GetEntityCoords(PlayerPedId())
    local h = GetEntityHeading(PlayerPedId())
    cb({
        x = math.floor(c.x * 100) / 100,
        y = math.floor(c.y * 100) / 100,
        z = math.floor(c.z * 100) / 100,
        h = math.floor(h   * 100) / 100,
    })
end)

RegisterNUICallback('refreshResources', function(_, cb)
    TriggerServerEvent('devkit:requestResources')
    cb('ok')
end)

RegisterNUICallback('runCommand', function(data, cb)
    TriggerServerEvent('devkit:runCommand', data.command)
    cb('ok')
end)

-- ── Server → UI log relay ─────────────────────────────────────
RegisterNetEvent('devkit:log')
AddEventHandler('devkit:log', function(msg, level)
    if not isOpen then return end
    SendNUIMessage({ action = 'log', message = msg, level = level or 'info' })
end)

-- ── Resource state update after restart/start/stop ────────────
RegisterNetEvent('devkit:resourceStateUpdate')
AddEventHandler('devkit:resourceStateUpdate', function(resources)
    if not isOpen then return end
    SendNUIMessage({ action = 'updateResources', resources = resources })
end)

-- ── ESC closes UI ─────────────────────────────────────────────
CreateThread(function()
    while true do
        Wait(0)
        if isOpen and IsControlJustPressed(0, 200) then
            CloseDebugMenu()
        end
    end
end)
