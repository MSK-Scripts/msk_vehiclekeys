AdminState = AdminState or {}

-- Opens the admin dashboard NUI when the server grants access.
RegisterNetEvent('msk_vehiclekeys:admin:open', function(payload)
    if AdminState.isNuiOpen then return end
    if KeysNuiState and KeysNuiState.isOpen then return end -- don't open over the player keys UI
    AdminState.isNuiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openAdmin', data = payload })
end)

-- Safety net: on (re)start, force-release any NUI focus left stuck from a
-- previous session so a `restart msk_vehiclekeys` always frees the cursor.
AddEventHandler('onClientResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
    AdminState.isNuiOpen = false
    KeysNuiState = KeysNuiState or {}
    KeysNuiState.isOpen = false
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
end)
