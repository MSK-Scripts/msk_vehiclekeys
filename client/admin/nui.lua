-- NUI callbacks for the admin dashboard. CRUD callbacks forward to the gated
-- server callbacks and return the server response verbatim.
AdminState = AdminState or {}

local function round(n, dp)
    local m = 10 ^ (dp or 2)
    return math.floor(n * m + 0.5) / m
end

local function forward(event)
    return function(data, cb)
        local res = MSK.Trigger(event, data)
        cb(res or { ok = false, err = 'no_response' })
    end
end

-- Capture the player's current position for a locksmith coordinate field.
RegisterNUICallback('admin:getCurrentCoords', function(_data, cb)
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)
    cb({ x = round(c.x, 2), y = round(c.y, 2), z = round(c.z, 2), w = round(h, 2) })
end)

RegisterNUICallback('admin:close', function(_data, cb)
    SetNuiFocus(false, false)
    AdminState.isNuiOpen = false
    cb('ok')
end)

RegisterNUICallback('admin:bootstrap', forward('msk_vehiclekeys:admin:bootstrap'))

-- Players & Keys
RegisterNUICallback('admin:players:list', forward('msk_vehiclekeys:admin:players:list'))
RegisterNUICallback('admin:player:lookup', forward('msk_vehiclekeys:admin:player:lookup'))
RegisterNUICallback('admin:keys:add', forward('msk_vehiclekeys:admin:keys:add'))
RegisterNUICallback('admin:keys:remove', forward('msk_vehiclekeys:admin:keys:remove'))
RegisterNUICallback('admin:keys:giveItem', forward('msk_vehiclekeys:admin:keys:giveItem'))
RegisterNUICallback('admin:keys:takeItem', forward('msk_vehiclekeys:admin:keys:takeItem'))
RegisterNUICallback('admin:keys:refresh', forward('msk_vehiclekeys:admin:keys:refresh'))
RegisterNUICallback('admin:keys:refreshForce', forward('msk_vehiclekeys:admin:keys:refreshForce'))

-- Vehicles / Plates
RegisterNUICallback('admin:plate:lookup', forward('msk_vehiclekeys:admin:plate:lookup'))
RegisterNUICallback('admin:plate:removeAllKeys', forward('msk_vehiclekeys:admin:plate:removeAllKeys'))
RegisterNUICallback('admin:plate:resetLocks', forward('msk_vehiclekeys:admin:plate:resetLocks'))
RegisterNUICallback('admin:plate:changePlate', forward('msk_vehiclekeys:admin:plate:changePlate'))

-- Locksmith
RegisterNUICallback('admin:locksmith:save', forward('msk_vehiclekeys:admin:locksmith:save'))
RegisterNUICallback('admin:locksmith:delete', forward('msk_vehiclekeys:admin:locksmith:delete'))

-- Access lists
RegisterNUICallback('admin:lists:save', forward('msk_vehiclekeys:admin:lists:save'))

-- Settings
RegisterNUICallback('admin:settings:save', forward('msk_vehiclekeys:admin:settings:save'))

-- Permissions
RegisterNUICallback('admin:perms:saveGroup', forward('msk_vehiclekeys:admin:perms:saveGroup'))
RegisterNUICallback('admin:perms:deleteGroup', forward('msk_vehiclekeys:admin:perms:deleteGroup'))
RegisterNUICallback('admin:perms:dashboardGroups', forward('msk_vehiclekeys:admin:perms:dashboardGroups'))
RegisterNUICallback('admin:perms:validateGroup', forward('msk_vehiclekeys:admin:perms:validateGroup'))
