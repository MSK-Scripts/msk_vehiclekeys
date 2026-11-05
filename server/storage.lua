VehicleKeys = {}

local VALID_KEY_TYPES = { primary = true, secondary = true, temporary = true }

-- Cleans an imported key table (only used for the JSON migration).
local function validateVehicleKeys(data)
    if type(data) ~= 'table' then
        return {}, 0, false
    end

    local cleaned, removed = {}, 0

    for identifier, keys in pairs(data) do
        if type(identifier) == 'string' and identifier ~= '' and type(keys) == 'table' then
            local validKeys = {}

            for _, key in ipairs(keys) do
                if type(key) == 'table'
                    and type(key.plate) == 'string' and key.plate ~= ''
                    and type(key.type) == 'string' and VALID_KEY_TYPES[key.type]
                    and type(key.model) == 'number'
                then
                    validKeys[#validKeys + 1] = {
                        plate = key.plate,
                        type  = key.type,
                        model = key.model,
                    }
                else
                    removed += 1
                end
            end

            cleaned[identifier] = validKeys
        else
            removed += 1
        end
    end

    return cleaned, removed, true
end

----------------------------------------------------------------
-- Write-Through helpers (called from functions.lua)
----------------------------------------------------------------

Storage = {}

-- Persists a key. Temporary keys are intentionally kept RAM-only.
Storage.SaveKey = function(identifier, plate, typ, model)
    if typ == 'temporary' then return end
    if type(plate) ~= 'string' or plate == '' or type(model) ~= 'number' then return end

    MySQL.insert(
        'INSERT INTO msk_vehiclekeys_keys (identifier, plate, type, model) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE model = VALUES(model)',
        { identifier, plate, typ, model }
    )
end

-- Deletes a key for real from the DB (also for offline players).
-- Without typ, all types for this identifier/plate combination are deleted.
Storage.DeleteKey = function(identifier, plate, typ)
    if typ then
        MySQL.update('DELETE FROM msk_vehiclekeys_keys WHERE identifier = ? AND plate = ? AND type = ?', { identifier, plate, typ })
    else
        MySQL.update('DELETE FROM msk_vehiclekeys_keys WHERE identifier = ? AND plate = ?', { identifier, plate })
    end
end

-- Updates a plate globally (license plate change).
Storage.UpdatePlate = function(oldPlate, newPlate)
    MySQL.update('UPDATE msk_vehiclekeys_keys SET plate = ? WHERE plate = ?', { newPlate, oldPlate })
end

----------------------------------------------------------------
-- Bootstrap: schema, migration, cache load
----------------------------------------------------------------

local function ensureSchema()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `msk_vehiclekeys_keys` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `identifier` VARCHAR(60) NOT NULL,
            `plate` VARCHAR(12) NOT NULL,
            `type` VARCHAR(16) NOT NULL DEFAULT 'primary',
            `model` INT NOT NULL,
            PRIMARY KEY (`id`),
            UNIQUE KEY `uniq_key` (`identifier`, `plate`, `type`),
            INDEX `idx_identifier` (`identifier`)
        )
    ]])
end

-- Loads all keys from the DB into the RAM cache. Returns the count.
local function loadCache()
    VehicleKeys = {}
    local rows = MySQL.query.await('SELECT identifier, plate, type, model FROM msk_vehiclekeys_keys') or {}

    for i = 1, #rows do
        local r = rows[i]
        if not VehicleKeys[r.identifier] then VehicleKeys[r.identifier] = {} end
        VehicleKeys[r.identifier][#VehicleKeys[r.identifier] + 1] = {
            plate = r.plate,
            type  = r.type,
            model = r.model,
        }
    end

    return #rows
end

-- One-time migration of the old vehiclekeys.json into the database.
-- Checks whether the JSON exists/has content -> migrates -> marks as migrated.
local function migrateFromJson()
    local datastring = LoadResourceFile(GetCurrentResourceName(), 'vehiclekeys.json')

    -- Missing / empty / already migrated ({}) -> skip
    if not datastring or datastring == '' or datastring == 'null' or datastring == '{}' then
        return
    end

    local ok, decoded = pcall(json.decode, datastring)
    if not ok or type(decoded) ~= 'table' then
        Log('error', 'vehiclekeys.json is corrupt - migration skipped, file left unchanged')
        return
    end

    local cleaned = validateVehicleKeys(decoded)

    -- Only primary/secondary are persisted (temporary is RAM-only)
    local rows = {}
    for identifier, keys in pairs(cleaned) do
        for i = 1, #keys do
            local k = keys[i]
            if k.type ~= 'temporary' then
                rows[#rows + 1] = { identifier, k.plate, k.type, k.model }
            end
        end
    end

    if #rows == 0 then
        -- Nothing to migrate -> still mark as migrated so it isn't attempted again
        SaveResourceFile(GetCurrentResourceName(), 'vehiclekeys.json', '{}', -1)
        return
    end

    -- INSERT IGNORE makes the migration re-entrant-safe against duplicates
    MySQL.prepare.await('INSERT IGNORE INTO msk_vehiclekeys_keys (identifier, plate, type, model) VALUES (?, ?, ?, ?)', rows)

    -- Back up the old JSON and mark the original as migrated
    -- (FiveM has no real rename/delete API -> marker file + empty JSON)
    SaveResourceFile(GetCurrentResourceName(), 'vehiclekeys.migrated.json', datastring, -1)
    SaveResourceFile(GetCurrentResourceName(), 'vehiclekeys.json', '{}', -1)

    Log('info', ('Migration complete: %s vehicle keys imported from vehiclekeys.json into the database'):format(#rows))
end

CreateThread(function()
    ensureSchema()
    migrateFromJson()
    local count = loadCache()
    Log('info', ('%s vehicle keys loaded from the database'):format(count))
end)

----------------------------------------------------------------
-- Player Lifecycle
----------------------------------------------------------------

playerLoaded = function(playerId, xPlayer)
    Wait(1000)
    local Player = xPlayer or GetPlayerFromData({ source = playerId })
    if not Player then return end
    local identifier = GetPlayerIdentifier({ player = Player })

    if not VehicleKeys[identifier] then VehicleKeys[identifier] = {} end
    local playerKeys = VehicleKeys[identifier]

    -- Collect temporary keys (removed after the loop) and, if needed,
    -- re-add missing secondary key items.
    local tempPlates = {}
    for i = 1, #playerKeys do
        local key = playerKeys[i]

        if key.type == 'temporary' then
            tempPlates[#tempPlates + 1] = key.plate
        elseif key.type == 'secondary' and Config.OnRefreshKeys.OnPlayerLoaded.secondaryKeys then
            if not hasCorrectItem({ player = Player }, Config.Settings.key, key.plate) then
                AddKeyToInv({ player = Player }, key.plate, key.type)
            end
        end
    end

    for i = 1, #tempPlates do
        RemoveKey({ identifier = identifier }, { plate = tempPlates[i], type = 'temporary' })
    end

    -- Owned vehicles -> create missing primary keys (cache + DB)
    local vehicles = GetPlayerVehicles({ identifier = identifier })
    local primaryKeys = GetPlayerPrimaryKeys({ identifier = identifier })

    for i = 1, #vehicles do
        local model = vehicles[i].model
        local plate = MSK.String.Trim(vehicles[i].plate)
        local key = getKeyFromPlate(primaryKeys, plate)

        if not key then
            VehicleKeys[identifier][#VehicleKeys[identifier] + 1] = {
                plate = plate,
                type = 'primary',
                model = model,
            }
            Storage.SaveKey(identifier, plate, 'primary', model)
        end

        if Config.OnRefreshKeys.OnPlayerLoaded.primaryKeys then
            if not hasCorrectItem({ player = Player }, Config.Settings.key, plate) then
                AddKeyToInv({ player = Player }, plate, 'primary')
            end
        end
    end

    -- Inventory-specific init (keyring / migration of the old keyring structure)
    if Inventory.AddKeyringItem then Inventory.AddKeyringItem(playerId) end
    if Inventory.ConvertOldMethod then Inventory.ConvertOldMethod(playerId, identifier) end
end
-- msk_core turns every framework's own load event into this one, so ESX,
-- QBCore and Qbox all arrive here. Listening to esx:playerLoaded directly meant
-- nothing ever ran on the other two.
--
-- AddEventHandler, not RegisterNetEvent: server side this event is local, and
-- registering it as a net event would let any client fire it with an arbitrary
-- player id. The id comes as the first argument, not through `source`.
AddEventHandler('msk_core:playerLoaded', function(playerId)
    playerLoaded(playerId)
end)

RegisterNetEvent('msk_vehiclekeys:playerLoaded', function()
    playerLoaded(source)
end)

playerUnloaded = function(playerId)
    -- Nothing to do here (Write-Through keeps the DB always up to date)
end
AddEventHandler('msk_core:playerLogout', function(playerId)
    playerUnloaded(playerId)
end)
RegisterNetEvent('msk_vehiclekeys:playerUnloaded', playerUnloaded)
