-- Player-facing NUI for the keys menu (/keyMenu) and the locksmith menu.
-- Selected via Config.Settings.menu.keysMenu = 'nui' / Config.Locksmith.menu = 'nui'.
-- The heavy lifting (labels, categorisation) happens in client/menu.lua; this file
-- only owns the NUI focus, the SendNUIMessage payloads and the RegisterNUICallbacks.
-- The action callbacks reuse the shared helpers from client/menu.lua so the custom
-- UI behaves exactly like the ox_context/ox_menu variants.
KeysNuiState = KeysNuiState or {}

-- Only the handful of strings the player UI needs. translation.lua stays the single
-- source of truth (it already covers every locale) — we just forward the resolved set.
local function keyStrings()
    local T = Translation[Config.Locale]
    return {
        menu_vehicle_keys = T['menu_vehicle_keys'],
        menu_primary_keys = T['menu_primary_keys'],
        menu_secondary_keys = T['menu_secondary_keys'],
        menu_temporary_keys = T['menu_temporary_keys'],
        menu_give_secondary_keys = T['menu_give_secondary_keys'],
        menu_exchange_locks = T['menu_exchange_locks'],
        menu_transfer_vehicle = T['menu_transfer_vehicle'],
        menu_no_keys_available = T['menu_no_keys_available'],
        menu_locksmith_title = T['menu_locksmith_title'],
        menu_locksmith_exchangelocks = T['menu_locksmith_exchangelocks'],
    }
end

local function keyFlags()
    return {
        showSecondaryKeys = Config.Settings.menu.showSecondaryKeys,
        showTempKeys = Config.Settings.menu.showTempKeys,
        showExchangeLocks = Config.Settings.menu.showExchangeLocks,
        showTransferVehicle = Config.Settings.transferVehicle and Config.Settings.menu.showTransferVehicle,
    }
end

-- Refuse to open on top of the admin dashboard (both share the single ui_page).
local function canOpen()
    if KeysNuiState.isOpen then return false end
    if AdminState and AdminState.isNuiOpen then return false end
    return true
end

-- keys = { primary = {...}, secondary = {...}, temporary = {...} }, each entry {label, plate, model}
function OpenKeysNui(keys)
    if not canOpen() then return end
    KeysNuiState.isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openKeys',
        data = {
            locale = Config.Locale,
            theme = Config.Theme,
            brandTag = Config.BrandTag,
            strings = keyStrings(),
            flags = keyFlags(),
            keys = keys,
        }
    })
end

-- vehicles = { {label, plate, model}, ... }
function OpenLocksmithNui(vehicles)
    if not canOpen() then return end
    KeysNuiState.isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openLocksmith',
        data = {
            locale = Config.Locale,
            theme = Config.Theme,
            brandTag = Config.BrandTag,
            strings = keyStrings(),
            vehicles = vehicles,
        }
    })
end

-- Releases focus and unmounts the React view. Called by the close callback AND before
-- every action so any follow-up ox_lib dialog (e.g. the transfer input) grabs focus LAST.
function CloseKeysNui()
    if not KeysNuiState.isOpen then return end
    KeysNuiState.isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeKeys' })
end

-- Close first (release focus + unmount), acknowledge the fetch, THEN run the action.
-- Sequential ordering in this coroutine guarantees a follow-up dialog keeps the cursor.
local function runAction(data, cb, fn)
    CloseKeysNui()
    cb({ ok = true })
    if data and data.plate then fn(data) end
end

RegisterNUICallback('keys:close', function(_data, cb)
    CloseKeysNui()
    cb('ok')
end)

RegisterNUICallback('keys:giveSecondary', function(data, cb)
    runAction(data, cb, GiveSecondaryKeyAction)
end)

RegisterNUICallback('keys:exchangeLocks', function(data, cb)
    runAction(data, cb, ExchangeLocksAction)
end)

RegisterNUICallback('keys:transferVehicle', function(data, cb)
    runAction(data, cb, TransferVehicleAction)
end)

RegisterNUICallback('locksmith:close', function(_data, cb)
    CloseKeysNui()
    cb('ok')
end)

RegisterNUICallback('locksmith:exchange', function(data, cb)
    runAction(data, cb, ExchangeLocksAction)
end)
