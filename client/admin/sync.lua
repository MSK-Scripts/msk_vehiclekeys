AdminSync = AdminSync or {}

-- Applies DB-authoritative definitions and rebuilds the locksmith world objects.
local function applyDefs(defs)
    if type(defs) ~= 'table' then return end

    -- Settings (incl. Locksmith flags, whitelist/blacklist, etc.) update the
    -- config that the client's matching + interaction logic reads.
    if type(defs.settings) == 'table' then
        for k, v in pairs(defs.settings) do Config[k] = v end
    end

    -- Locksmith locations live in their own payload (settings.Locksmith has none).
    if type(Config.Locksmith) ~= 'table' then Config.Locksmith = {} end
    if type(defs.locksmiths) == 'table' then
        Config.Locksmith.locations = defs.locksmiths
    end

    if RebuildLocksmiths then RebuildLocksmiths() end
end

AdminSync.Apply = applyDefs

-- Server broadcast after any admin mutation.
RegisterNetEvent('msk_vehiclekeys:syncDefinitions', function(defs)
    applyDefs(defs)
end)

-- Pull the authoritative definitions once on join (covers edits made before the
-- player connected; the static client config may otherwise be stale).
CreateThread(function()
    while not (MSK and MSK.Player and MSK.Player.serverId) do Wait(250) end
    Wait(1500) -- let client/main.lua bootstrap build first
    local defs = MSK.Trigger('msk_vehiclekeys:admin:getDefinitions')
    applyDefs(defs)
end)
