----------------------------------------------------------------
-- Framework Player Helpers
----------------------------------------------------------------

-- Every helper below used to carry one branch per framework. msk_core 4.0.0
-- answers all of it in one shape, so the branches are gone and Qbox works
-- without a line of its own.

GetPlayerFromId = function(playerId)
    return MSK.GetPlayer(playerId)
end

GetPlayerFromIdentifier = function(identifier)
    return MSK.GetPlayerFromIdentifier(identifier)
end

GetPlayerSource = function(data)
    if data.source then return data.source end

    local Player = GetPlayerFromData(data)
    assert(Player, 'Player not found on function "GetPlayerSource"')

    return Player.source
end

-- ESX identifier, QBCore and Qbox citizenid: one field on every framework.
GetPlayerIdentifier = function(data)
    if data.identifier then return data.identifier end

    local Player = GetPlayerFromData(data)
    assert(Player, 'Player not found on function "GetPlayerIdentifier"')

    return Player.identifier
end

-- The grade name is gradeName on every framework now. It used to be
-- grade_name on ESX and grade.name on QBCore.
GetPlayerJob = function(data)
    local Player = GetPlayerFromData(data)
    assert(Player, 'Player not found on function "GetPlayerJob"')

    local job = Player.job

    if not job then return 'unemployed', 'unemployed' end

    return job.name or 'unemployed', job.gradeName or 'unemployed'
end

GetClosestPlayer = function(coords, players)
    return GetClosestEntity(true, coords, players)
end
exports('GetClosestPlayer', GetClosestPlayer)

GetClosestVehicle = function(coords, vehicles)
    return GetClosestEntity(false, coords, vehicles)
end
exports('GetClosestVehicle', GetClosestVehicle)

GetClosestVehicleWithPlate = function(coords, distance, plate, vehicles)
    return GetClosestEntityWithPlate(coords, distance, plate, vehicles)
end
exports('GetClosestVehicleWithPlate', GetClosestVehicleWithPlate)

----------------------------------------------------------------
-- Inventory (inventory.lua)
----------------------------------------------------------------

-- Checks whether the player has a matching key item (including keyring).
hasCorrectItem = function(data, item, plate)
    if not item then item = Config.Settings.key end
    local Player = GetPlayerFromData(data)
    assert(Player, 'Player not found on function "hasCorrectItem"')
    local identifier = GetPlayerIdentifier({ player = Player })
    local playerId = GetPlayerSource({ player = Player })
    plate = MSK.String.Trim(plate)

    if not item.needItem then return true end

    return Inventory.HasItem(playerId, identifier, plate)
end
exports('hasCorrectItem', hasCorrectItem)

-- Gives the player a key item.
AddKeyToInv = function(data, plate, typ, slot)
    local Player = GetPlayerFromData(data)
    if not Player then return end
    local identifier = GetPlayerIdentifier({ player = Player })
    local playerId = GetPlayerSource({ player = Player })
    plate = MSK.String.Trim(plate)

    Inventory.GiveItem(playerId, identifier, plate, typ, slot)
    Config.Notification(playerId, Translation[Config.Locale]['key_added']:format(plate), 'info')
end
exports('AddKeyToInv', AddKeyToInv)

-- Removes the key item (including keyring) from the player.
RemoveKeyFromInv = function(data, plate, slot)
    local Player = GetPlayerFromData(data)
    if not Player then return end
    local identifier = GetPlayerIdentifier({ player = Player })
    local playerId = GetPlayerSource({ player = Player })
    plate = MSK.String.Trim(plate)

    Inventory.TakeItem(playerId, identifier, plate)
    Config.Notification(playerId, Translation[Config.Locale]['key_removed']:format(plate), 'info')
end
exports('RemoveKeyFromInv', RemoveKeyFromInv)

----------------------------------------------------------------
-- Key Getter / Refresh
----------------------------------------------------------------

-- force = true re-adds ALL missing key items to the inventory regardless of the
-- Config.OnRefreshKeys flags (used by the admin dashboard's "Refresh FORCE").
RefreshPlayerKeys = function(playerId, force)
    local Player = GetPlayerFromData({ source = playerId })
    assert(Player, 'Player not found on function "RefreshPlayerKeys" for PlayerID: ' .. tostring(playerId))
    local identifier = GetPlayerIdentifier({ player = Player })
    local owned_keys, added_primary_keys, added_secondary_keys = 0, 0, 0

    if not VehicleKeys[identifier] then VehicleKeys[identifier] = {} end

    local vehicles = GetPlayerVehicles({ identifier = identifier })
    local primaryKeys = GetPlayerPrimaryKeys({ identifier = identifier })

    for i = 1, #vehicles do
        local model = vehicles[i].model
        local plate = MSK.String.Trim(vehicles[i].plate)
        local key = getKeyFromPlate(primaryKeys, plate)

        if not key then
            owned_keys += 1

            VehicleKeys[identifier][#VehicleKeys[identifier] + 1] = {
                plate = plate,
                type = 'primary',
                model = model,
            }
            Storage.SaveKey(identifier, plate, 'primary', model)
        end

        if force or Config.OnRefreshKeys.OnRefreshKeys.primaryKeys then
            if not hasCorrectItem({ player = Player }, Config.Settings.key, plate) then
                added_primary_keys += 1
                AddKeyToInv({ player = Player }, plate, 'primary')
            end
        end
    end

    if force or Config.OnRefreshKeys.OnRefreshKeys.secondaryKeys then
        local secondaryKeys = GetPlayerSecondaryKeys({ identifier = identifier })

        for i = 1, #secondaryKeys do
            if not hasCorrectItem({ player = Player }, Config.Settings.key, secondaryKeys[i].plate) then
                added_secondary_keys += 1
                AddKeyToInv({ player = Player }, secondaryKeys[i].plate, 'secondary')
            end
        end
    end

    Log('debug', ('PlayerId %s: Added %s Owned Vehicles; Added %s Primary Key; Added %s Secondary Keys'):format(playerId, owned_keys, added_primary_keys, added_secondary_keys))

    return { owned_keys, added_primary_keys, added_secondary_keys }
end
exports('RefreshPlayerKeys', RefreshPlayerKeys)

RegisterNetEvent('msk_vehiclekeys:RefreshPlayerKeys', function()
    RefreshPlayerKeys(source)
end)
MSK.Register('msk_vehiclekeys:RefreshPlayerKeys', function(source)
    return RefreshPlayerKeys(source)
end)

GetAllVehicleKeys = function()
    return VehicleKeys
end
exports('GetAllVehicleKeys', GetAllVehicleKeys)
MSK.Register('msk_vehiclekeys:GetAllVehicleKeys', GetAllVehicleKeys)

GetPlayerKeys = function(data)
    local data = checkParameter(data)
    local identifier = GetPlayerIdentifier(data)
    assert(identifier, 'Player Identifier not found on function "GetPlayerKeys"')

    return VehicleKeys[identifier] or {}
end
exports('GetPlayerKeys', GetPlayerKeys)

GetPlayerPrimaryKeys = function(data)
    local playerKeys = GetPlayerKeys(data)
    local keys = {}

    for i = 1, #playerKeys do
        if playerKeys[i].type == 'primary' then
            keys[#keys + 1] = playerKeys[i]
        end
    end

    return keys
end
exports('GetPlayerPrimaryKeys', GetPlayerPrimaryKeys)

GetPlayerSecondaryKeys = function(data)
    local playerKeys = GetPlayerKeys(data)
    local keys = {}

    for i = 1, #playerKeys do
        if playerKeys[i].type == 'secondary' then
            keys[#keys + 1] = playerKeys[i]
        end
    end

    return keys
end
exports('GetPlayerSecondaryKeys', GetPlayerSecondaryKeys)

GetPlayerTempKeys = function(data)
    local playerKeys = GetPlayerKeys(data)
    local keys = {}

    for i = 1, #playerKeys do
        if playerKeys[i].type == 'temporary' then
            keys[#keys + 1] = playerKeys[i]
        end
    end

    return keys
end
exports('GetPlayerTempKeys', GetPlayerTempKeys)

----------------------------------------------------------------
-- Key Checks
----------------------------------------------------------------

HasPlayerKey = function(data, plate, model, playerKeys)
    local Player = GetPlayerFromData(data)
    assert(Player, 'Player not found on function "HasPlayerKey"')
    local playerId = GetPlayerSource({ player = Player })
    local identifier = GetPlayerIdentifier({ player = Player })
    if plate then plate = MSK.String.Trim(plate) end

    if IsAdminVehicle(plate, model) and IsAceAllowed(playerId) then
        return true
    end

    if IsVehicleBlacklisted(plate, model) then
        return false
    end

    if IsVehicleWhitelisted(plate, model) then
        return true
    end

    if not playerKeys then
        playerKeys = GetPlayerKeys({ identifier = identifier })
    end

    local hasItem = hasCorrectItem({ player = Player }, Config.Settings.key, plate)

    if hasItem then
        return true
    end

    -- Player has the key internally but not the item -> item is required
    if getKeyFromPlate(playerKeys, plate) then
        return hasItem
    end

    local jobName, jobRank = GetPlayerJob({ player = Player })
    if IsJobVehicle(jobName, jobRank, plate, model) then
        return true
    end

    return false
end
exports('HasPlayerKey', HasPlayerKey)

HasPlayerPrimaryKey = function(data, plate, model)
    local Player = GetPlayerFromData(data)
    assert(Player, 'Player not found on function "HasPlayerPrimaryKey"')
    return HasPlayerKey({ player = Player }, plate, model, GetPlayerPrimaryKeys({ player = Player }))
end
exports('HasPlayerPrimaryKey', HasPlayerPrimaryKey)

HasPlayerSecondaryKey = function(data, plate, model)
    local Player = GetPlayerFromData(data)
    assert(Player, 'Player not found on function "HasPlayerSecondaryKey"')
    return HasPlayerKey({ player = Player }, plate, model, GetPlayerSecondaryKeys({ player = Player }))
end
exports('HasPlayerSecondaryKey', HasPlayerSecondaryKey)

HasPlayerTempKey = function(data, plate, model)
    local Player = GetPlayerFromData(data)
    assert(Player, 'Player not found on function "HasPlayerTempKey"')
    return HasPlayerKey({ player = Player }, plate, model, GetPlayerTempKeys({ player = Player }))
end
exports('HasPlayerTempKey', HasPlayerTempKey)

GetPlayerVehicles = function(data)
    local data = checkParameter(data)
    local identifier = GetPlayerIdentifier(data)
    assert(identifier, 'Player Identifier not found on function "GetPlayerVehicles"')
    local vehicles = {}

    local result = MySQL.query.await(('SELECT * FROM %s WHERE %s = @owner'):format(VEHICLE_TABLE_NAME, OWNER_COLUMN_NAME), {
        ['@owner'] = identifier,
    })

    -- Where the model sits is a property of the framework: inside the property
    -- JSON on ESX, in its own `hash` column on QBCore and Qbox.
    --
    -- This asked Config.Framework, which is only ever 'AUTO' now that msk_core
    -- does the detection, so every branch was skipped and the function returned
    -- an empty list on every framework.
    if MSK.Bridge.Framework.Type == 'ESX' then
        for i = 1, #result do
            local ok, props = pcall(json.decode, result[i].vehicle)

            vehicles[i] = {
                plate = result[i].plate,
                model = (ok and type(props) == 'table') and props.model or nil,
            }
        end
    else
        for i = 1, #result do
            vehicles[i] = {
                plate = result[i].plate,
                model = tonumber(result[i].hash) or result[i].vehicle,
            }
        end
    end

    return vehicles
end
exports('GetPlayerVehicles', GetPlayerVehicles)

IsVehicleOwner = function(data, plate)
    local data = checkParameter(data)
    local identifier = GetPlayerIdentifier(data)
    assert(identifier, 'Player Identifier not found on function "IsVehicleOwner"')
    plate = MSK.String.Trim(plate)

    -- TRIM(plate) so a plate stored padded with spaces in owned_vehicles (ESX
    -- default) still matches the trimmed plate the script works with. Without this
    -- the owner check fails for freshly spawned garage vehicles (v3.1.1 fix).
    local isOwned = MySQL.scalar.await(('SELECT COUNT(plate) FROM %s WHERE %s = @owner AND TRIM(plate) = @plate'):format(VEHICLE_TABLE_NAME, OWNER_COLUMN_NAME), {
        ['@owner'] = identifier,
        ['@plate'] = plate,
    }) > 0

    return isOwned
end
exports('IsVehicleOwner', IsVehicleOwner)

HasPlayerKeyOrIsVehicleOwner = function(data, plate, model)
    local Player = GetPlayerFromData(data)
    assert(Player, 'Player not found on function "HasPlayerKeyOrIsVehicleOwner"')

    local hasKey = HasPlayerKey({ player = Player }, plate, model)
    if hasKey then return true end

    local isOwner = IsVehicleOwner({ player = Player }, plate)
    if isOwner then
        -- Config.Settings.key.ownerNeedsItem = true -> the owner must ALSO carry the
        -- key item to (un)lock (strict). Default false keeps the lenient behavior
        -- where ownership alone is enough.
        if Config.Settings.key.ownerNeedsItem then
            return hasCorrectItem({ player = Player }, Config.Settings.key, plate)
        end
        return true
    end

    return false
end
exports('HasPlayerKeyOrIsVehicleOwner', HasPlayerKeyOrIsVehicleOwner)

GetPlayerKeysAndVehicles = function(data)
    local data = checkParameter(data)
    local identifier = GetPlayerIdentifier(data)
    assert(identifier, 'Player Identifier not found on function "GetPlayerKeysAndVehicles"')
    local playerKeys = GetPlayerKeys({ identifier = identifier })
    local vehicles = GetPlayerVehicles({ identifier = identifier })

    return playerKeys, vehicles
end
exports('GetPlayerKeysAndVehicles', GetPlayerKeysAndVehicles)

----------------------------------------------------------------
-- Key (Write-Through: cache + DB are kept in sync)
----------------------------------------------------------------

AddKey = function(data, vehicleData, ignoreInv)
    if not vehicleData or type(vehicleData) ~= 'table' then
        error(('expected parameter "table", received %s on function AddKey'):format(type(vehicleData)))
    end

    local data = checkParameter(data)
    local identifier = GetPlayerIdentifier(data)
    assert(identifier, 'Player Identifier not found on function "AddKey"')
    local Player = GetPlayerFromData({ identifier = identifier })

    if not VehicleKeys[identifier] then VehicleKeys[identifier] = {} end
    local plate, model, typ = nil, nil, 'primary'

    if vehicleData.plate then plate = MSK.String.Trim(vehicleData.plate) end
    if vehicleData.model then model = vehicleData.model end
    if vehicleData.type then typ = vehicleData.type end

    if vehicleData.netId then
        local vehicle = NetworkGetEntityFromNetworkId(vehicleData.netId)
        if DoesEntityExist(vehicle) then
            plate = MSK.String.Trim(GetVehicleNumberPlateText(vehicle))
            model = GetEntityModel(vehicle)
        end
    end

    -- Remove existing keys with the same plate but a different type
    if #VehicleKeys[identifier] > 0 then
        local foundKey = false

        for i = #VehicleKeys[identifier], 1, -1 do
            local key = VehicleKeys[identifier][i]

            if key.plate == plate and key.type ~= typ then
                table.remove(VehicleKeys[identifier], i)
                Storage.DeleteKey(identifier, plate, key.type)

                if Player and typ ~= 'temporary' then
                    RemoveKeyFromInv({ player = Player }, plate)
                end
            elseif key.plate == plate and key.type == typ then
                foundKey = true
            end
        end

        if foundKey then
            -- The key already exists in the cache/DB, so we must NOT write a duplicate
            -- entry. But the player can still be MISSING the inventory item for it
            -- (item lost, inventory wiped, or the DB key predates the current item
            -- system). In that case re-give the item, exactly like RefreshPlayerKeys
            -- does, so garage/shop hand-outs actually give a usable key instead of
            -- silently doing nothing.
            if not ignoreInv and Player and not hasCorrectItem({ player = Player }, Config.Settings.key, plate) then
                AddKeyToInv({ player = Player }, plate, typ)
            end
            return
        end
    end

    if not model then
        local result = MySQL.single.await(('SELECT vehicle FROM %s WHERE plate = @plate LIMIT 1'):format(VEHICLE_TABLE_NAME), {
            ['@plate'] = plate,
        })

        if not result then
            Log('error', ("AddKey aborted: Plate (%s) not found in %s -> Use parameter 'model' or make sure that the vehicle is saved in %s"):format(plate, VEHICLE_TABLE_NAME, VEHICLE_TABLE_NAME))
            return
        end

        model = json.decode(result.vehicle).model

        if not model then
            Log('error', ("AddKey aborted: 'model' for plate (%s) not found in %s"):format(plate, VEHICLE_TABLE_NAME))
            return
        end
    end

    -- Final validation so nil/null never ends up in the cache or DB
    if type(plate) ~= 'string' or plate == '' or type(model) ~= 'number' or type(typ) ~= 'string' or typ == '' then
        Log('error', ('AddKey aborted: invalid data (plate=%s, model=%s, type=%s)'):format(tostring(plate), tostring(model), tostring(typ)))
        return
    end

    VehicleKeys[identifier][#VehicleKeys[identifier] + 1] = {
        plate = plate,
        type = typ,
        model = model,
    }
    Storage.SaveKey(identifier, plate, typ, model)

    if ignoreInv then return end -- Do NOT remove this!
    AddKeyToInv({ identifier = identifier }, plate, typ)
end
exports('AddKey', AddKey)

AddPrimaryKey = function(data, vehicleData, ignoreInv)
    if not vehicleData or type(vehicleData) ~= 'table' then
        error(('expected parameter "table", received %s on function AddPrimaryKey'):format(type(vehicleData)))
    end
    vehicleData.type = 'primary'
    AddKey(data, vehicleData, ignoreInv)
end
exports('AddPrimaryKey', AddPrimaryKey)

AddSecondaryKey = function(data, vehicleData, ignoreInv)
    if not vehicleData or type(vehicleData) ~= 'table' then
        error(('expected parameter "table", received %s on function AddSecondaryKey'):format(type(vehicleData)))
    end
    vehicleData.type = 'secondary'
    AddKey(data, vehicleData, ignoreInv)
end
exports('AddSecondaryKey', AddSecondaryKey)

AddTempKey = function(data, vehicleData, ignoreInv)
    if not vehicleData or type(vehicleData) ~= 'table' then
        error(('expected parameter "table", received %s on function AddTempKey'):format(type(vehicleData)))
    end
    vehicleData.type = 'temporary'
    AddKey(data, vehicleData, ignoreInv)
end
exports('AddTempKey', AddTempKey)

RemoveKey = function(data, vehicleData, ignoreInv)
    if not vehicleData or type(vehicleData) ~= 'table' then
        error(('expected parameter "table", received %s on function RemoveKey'):format(type(vehicleData)))
    end

    local data = checkParameter(data)
    local identifier = GetPlayerIdentifier(data)
    assert(identifier, 'Player Identifier not found on function "RemoveKey"')

    local plate, typ = nil, 'primary'

    if vehicleData.plate then plate = MSK.String.Trim(vehicleData.plate) end
    if vehicleData.type then typ = vehicleData.type end

    if vehicleData.netId then
        local vehicle = NetworkGetEntityFromNetworkId(vehicleData.netId)
        if DoesEntityExist(vehicle) then
            plate = MSK.String.Trim(GetVehicleNumberPlateText(vehicle))
        end
    end

    -- Clean up the cache (if present)
    if VehicleKeys[identifier] then
        for i = #VehicleKeys[identifier], 1, -1 do
            local key = VehicleKeys[identifier][i]
            if key.plate == plate and key.type == typ then
                table.remove(VehicleKeys[identifier], i)
            end
        end
    end

    -- Always update the DB (also for offline players -> real DELETE)
    Storage.DeleteKey(identifier, plate, typ)

    if ignoreInv then return end -- Do NOT remove this!
    RemoveKeyFromInv({ identifier = identifier }, plate)
end
exports('RemoveKey', RemoveKey)

RemoveAllExistingKeys = function(plate)
    plate = MSK.String.Trim(plate)

    for ident, keys in pairs(VehicleKeys) do
        for i = #keys, 1, -1 do
            if keys[i].plate == plate then
                local removedType = keys[i].type
                local Target = GetPlayerFromData({ identifier = ident })

                table.remove(VehicleKeys[ident], i)
                Storage.DeleteKey(ident, plate, removedType)

                if Target then
                    RemoveKeyFromInv({ player = Target }, plate)
                end
            end
        end
    end
end
exports('RemoveAllExistingKeys', RemoveAllExistingKeys)

RemovePrimaryKey = function(data, vehicleData, ignoreInv)
    if not vehicleData or type(vehicleData) ~= 'table' then
        error(('expected parameter "table", received %s on function RemovePrimaryKey'):format(type(vehicleData)))
    end
    vehicleData.type = 'primary'
    RemoveKey(data, vehicleData, ignoreInv)
end
exports('RemovePrimaryKey', RemovePrimaryKey)

RemoveSecondaryKey = function(data, vehicleData, ignoreInv)
    if not vehicleData or type(vehicleData) ~= 'table' then
        error(('expected parameter "table", received %s on function RemoveSecondaryKey'):format(type(vehicleData)))
    end
    vehicleData.type = 'secondary'
    RemoveKey(data, vehicleData, ignoreInv)
end
exports('RemoveSecondaryKey', RemoveSecondaryKey)

RemoveTempKey = function(data, vehicleData, ignoreInv)
    if not vehicleData or type(vehicleData) ~= 'table' then
        error(('expected parameter "table", received %s on function RemoveTempKey'):format(type(vehicleData)))
    end
    vehicleData.type = 'temporary'
    RemoveKey(data, vehicleData, ignoreInv)
end
exports('RemoveTempKey', RemoveTempKey)

ExchangeVehicleLocks = function(data, vehicleData)
    if not vehicleData or type(vehicleData) ~= 'table' then
        vehicleData = { plate = vehicleData }
    end

    local Player = GetPlayerFromData(data)
    assert(Player, 'Player not found on function "ExchangeVehicleLocks"')
    local identifier = GetPlayerIdentifier({ player = Player })
    local playerId = GetPlayerSource({ player = Player })
    local plate = nil

    if vehicleData.plate then plate = MSK.String.Trim(vehicleData.plate) end

    if vehicleData.netId then
        local vehicle = NetworkGetEntityFromNetworkId(vehicleData.netId)
        if DoesEntityExist(vehicle) then
            plate = MSK.String.Trim(GetVehicleNumberPlateText(vehicle))
        end
    end

    -- only the vehicle owner may exchange the locks. Without this check any client could reset the locks of any vehicle and steal it.
    if not IsVehicleOwner({ player = Player }, plate) then
        return Config.Notification(playerId, Translation[Config.Locale]['not_vehicle_owner'], 'error')
    end

    -- Remove all keys of OTHER players for this plate
    for ident, keys in pairs(VehicleKeys) do
        if ident ~= identifier then
            for i = #keys, 1, -1 do
                if keys[i].plate == plate then
                    local removedType = keys[i].type
                    local Target = GetPlayerFromData({ identifier = ident })

                    table.remove(VehicleKeys[ident], i)
                    Storage.DeleteKey(ident, plate, removedType)

                    if Target then
                        RemoveKeyFromInv({ player = Target }, plate)
                    end
                end
            end
        end
    end

    if not hasCorrectItem({ player = Player }, Config.Settings.key, plate) then
        AddKeyToInv({ player = Player }, plate, 'primary')
    end

    Config.Notification(playerId, Translation[Config.Locale]['exchange_success'], 'success')
end
exports('ExchangeVehicleLocks', ExchangeVehicleLocks)

TransferVehicle = function(sellerData, buyerData, vehicleData)
    if not vehicleData or type(vehicleData) ~= 'table' then
        vehicleData = { plate = vehicleData }
    end

    local Seller = GetPlayerFromData(sellerData)
    local sellerIdentifier = GetPlayerIdentifier({ player = Seller })
    local sellerSource = GetPlayerSource({ player = Seller })
    local Buyer = GetPlayerFromData(buyerData)
    local buyerIdentifier = GetPlayerIdentifier({ player = Buyer })
    local plate, model = nil, nil

    if vehicleData.plate then plate = MSK.String.Trim(vehicleData.plate) end
    if vehicleData.model then model = vehicleData.model end

    if vehicleData.netId then
        local vehicle = NetworkGetEntityFromNetworkId(vehicleData.netId)
        if DoesEntityExist(vehicle) then
            plate = MSK.String.Trim(GetVehicleNumberPlateText(vehicle))
            model = GetEntityModel(vehicle)
        end
    end

    if not IsVehicleOwner({ player = Seller }, plate) then
        Config.Notification(sellerSource, Translation[Config.Locale]['not_vehicle_owner'], 'error')
        return
    end

    RemovePrimaryKey({ identifier = sellerIdentifier }, { plate = plate })
    AddPrimaryKey({ identifier = buyerIdentifier }, { plate = plate, model = model })

    MySQL.update(('UPDATE %s SET %s = @newOwner WHERE %s = @oldOwner AND plate = @plate'):format(VEHICLE_TABLE_NAME, OWNER_COLUMN_NAME, OWNER_COLUMN_NAME), {
        ['@oldOwner'] = sellerIdentifier,
        ['@newOwner'] = buyerIdentifier,
        ['@plate'] = plate,
    })
end
exports('TransferVehicle', TransferVehicle)

----------------------------------------------------------------
-- Whitelist / Blacklist / Admin / Job
----------------------------------------------------------------

-- Model list entries are spawn NAMES (strings), hashed for comparison against
-- the numeric model hash returned by GetEntityModel. Numeric entries (legacy
-- backtick hashes) are still accepted as-is for backwards compatibility.
local function toModelHash(m)
    if type(m) == 'string' then return GetHashKey(m) end
    return m
end

IsVehicleWhitelisted = function(plate, model)
    local models = Config.Whitelist.models
    local plates = Config.Whitelist.plates

    if model then
        for i = 1, #models do
            if toModelHash(models[i]) == model then return true end
        end
    end

    if plate then
        plate = MSK.String.Trim(plate, true)
        for i = 1, #plates do
            if string.find(plate, MSK.String.Trim(plates[i], true)) then return true end
        end
    end

    return false
end
exports('IsVehicleWhitelisted', IsVehicleWhitelisted)

IsVehicleBlacklisted = function(plate, model)
    local models = Config.Blacklist.models
    local plates = Config.Blacklist.plates

    if model then
        for i = 1, #models do
            if toModelHash(models[i]) == model then return true end
        end
    end

    if plate then
        plate = MSK.String.Trim(plate, true)
        for i = 1, #plates do
            if string.find(plate, MSK.String.Trim(plates[i], true)) then return true end
        end
    end

    return false
end
exports('IsVehicleBlacklisted', IsVehicleBlacklisted)

IsAdminVehicle = function(plate, model)
    local models = Config.AdminVehicles.models
    local plates = Config.AdminVehicles.plates

    if model then
        for i = 1, #models do
            if toModelHash(models[i]) == model then return true end
        end
    end

    if plate then
        plate = MSK.String.Trim(plate, true)
        for i = 1, #plates do
            if string.find(plate, MSK.String.Trim(plates[i], true)) then return true end
        end
    end

    return false
end
exports('IsAdminVehicle', IsAdminVehicle)

IsAdminVehicleAllowed = function(playerId, plate, model)
    if not IsAceAllowed(playerId) then return false end
    return IsAdminVehicle(plate, model)
end
exports('IsAdminVehicleAllowed', IsAdminVehicleAllowed)

IsJobVehicle = function(jobName, jobRank, plate, model)
    if plate then
        plate = MSK.String.Trim(tostring(plate):upper())

        local isSocietyVehicle = MySQL.scalar.await((
            'SELECT COUNT(plate) FROM %s WHERE (%s = @job OR %s = @society) AND (plate = @plate OR plate = @trimmedPlate)'
        ):format(VEHICLE_TABLE_NAME, OWNER_COLUMN_NAME, OWNER_COLUMN_NAME), {
            ['@job'] = jobName,
            ['@society'] = ("society_%s"):format(jobName),
            ['@plate'] = plate,
            ['@trimmedPlate'] = MSK.String.Trim(plate, true),
        }) > 0

        if isSocietyVehicle then return true end
    end

    if jobName and Config.JobVehicles[jobName] then
        local jobData = Config.JobVehicles[jobName]

        if plate then
            plate = MSK.String.Trim(plate, true)

            if jobData.plates then
                for i = 1, #jobData.plates do
                    local jobPlate = tostring(jobData.plates[i]):upper()
                    if plate == MSK.String.Trim(jobPlate, true) or string.find(plate, MSK.String.Trim(jobPlate, true)) then
                        return true
                    end
                end
            end

            if jobData.ranks and jobData.ranks[jobRank] and jobData.ranks[jobRank].plates then
                local rankData = jobData.ranks[jobRank]
                for i = 1, #rankData.plates do
                    local jobPlate = tostring(rankData.plates[i]):upper()
                    if plate == MSK.String.Trim(jobPlate, true) or string.find(plate, MSK.String.Trim(jobPlate, true)) then
                        return true
                    end
                end
            end
        end

        if model then
            if jobData.models then
                for i = 1, #jobData.models do
                    if model == toModelHash(jobData.models[i]) then return true end
                end
            end

            if jobData.ranks and jobData.ranks[jobRank] and jobData.ranks[jobRank].models then
                local rankData = jobData.ranks[jobRank]
                for i = 1, #rankData.models do
                    if model == toModelHash(rankData.models[i]) then return true end
                end
            end
        end
    end

    return false
end
exports('IsJobVehicle', IsJobVehicle)

GetOwnedVehiclesInRadius = function(playerId, playerCoords, radius)
    local Player = GetPlayerFromData({ source = playerId })
    assert(Player, 'Player not found on function "GetOwnedVehiclesInRadius"')
    local identifier = GetPlayerIdentifier({ player = Player })
    assert(identifier, 'Identifier not found on function "GetOwnedVehiclesInRadius"')

    local toggleWithKey = Config.Settings.key.toggleWithKey
    local plates = {}

    local playerKeys = GetPlayerKeys({ identifier = identifier })
    for i = 1, #playerKeys do
        plates[playerKeys[i].plate] = true
    end

    local jobName, jobRank = GetPlayerJob({ player = Player })
    local vehicles = GetVehiclesInBucket(GetPlayerRoutingBucket(playerId))
    local closestVehicles = {}

    for i = 1, #vehicles do
        if DoesEntityExist(vehicles[i]) and #(playerCoords - GetEntityCoords(vehicles[i])) <= radius then
            local plate = MSK.String.Trim(GetVehicleNumberPlateText(vehicles[i]))
            local model = GetEntityModel(vehicles[i])

            if not IsVehicleBlacklisted(plate, model) then
                local hasKeyItem = hasCorrectItem({ identifier = identifier }, Config.Settings.key, plate)

                if (hasKeyItem and (plates[plate] or toggleWithKey)) or IsVehicleWhitelisted(plate, model) or IsJobVehicle(jobName, jobRank, plate, model) or IsAdminVehicleAllowed(playerId, plate, model) then
                    closestVehicles[#closestVehicles + 1] = vehicles[i]
                end
            else
                Log('debug', 'Plate or Model is blacklisted', plate, model)
            end
        end
    end

    return closestVehicles
end
exports('GetOwnedVehiclesInRadius', GetOwnedVehiclesInRadius)

----------------------------------------------------------------
-- Lock State
----------------------------------------------------------------

SetVehicleLockState = function(vehicle, state, playerId, forceLock)
    assert(vehicle and DoesEntityExist(vehicle), 'Parameter "vehicle" is nil or the Vehicle does not exist on function SetVehicleLockState')

    Entity(vehicle).state:set('isLocked', state, true)
    Entity(vehicle).state:set('lockState', state and LockStatus.Locked or LockStatus.Unlocked, true)
    SetVehicleDoorsLocked(vehicle, state and LockStatus.Locked or LockStatus.Unlocked)

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    TriggerClientEvent('msk_vehiclekeys:setVehicleLockState', playerId, netId, state, forceLock)
    TriggerClientEvent('msk_vehiclekeys:playDoorLockEffects', -1, netId, state)

    if forceLock then
        Entity(vehicle).state:set('forceLock', true, true)
    end
end
exports('SetVehicleLockState', SetVehicleLockState) -- Do NOT use this Export if you don't know what your are doing! You may break the script!

SetVehicleLockStatus = function(vehicle, status)
    SetVehicleDoorsLocked(vehicle, status)
    Entity(vehicle).state:set('lockState', status, true)

    if status == LockStatus.Unlocked then
        Entity(vehicle).state:set('isLocked', false, true)
    elseif status ~= LockStatus.Unlocked then
        Entity(vehicle).state:set('isLocked', true, true)
    end
end
exports('SetVehicleLockStatus', SetVehicleLockStatus) -- Do NOT use this Export if you don't know what your are doing! You may break the script!

GetVehicleLockState = function(vehicle)
    assert(vehicle and DoesEntityExist(vehicle), 'Parameter "vehicle" is nil or the Vehicle does not exist on function GetVehicleLockState')

    if Entity(vehicle).state.isLocked == nil then
        Entity(vehicle).state:set('isLocked', GetVehicleDoorLockStatus(vehicle) ~= LockStatus.Locked, true)
    end

    return Entity(vehicle).state.isLocked
end
exports('GetVehicleLockState', GetVehicleLockState)

GetVehicleLockStatus = function(vehicle)
    assert(vehicle and DoesEntityExist(vehicle), 'Parameter "vehicle" is nil or the Vehicle does not exist on function GetVehicleLockStatus')

    if Entity(vehicle).state.lockState == nil then
        Entity(vehicle).state:set('lockState', GetVehicleLockState(vehicle) and LockStatus.Locked or LockStatus.Unlocked, true)
    end

    return Entity(vehicle).state.lockState
end
exports('GetVehicleLockStatus', GetVehicleLockStatus)

lockCooldown = {}
toggleLock = function(playerId, plate, model)
    if not playerId then return end
    playerId = tonumber(playerId)
    if plate then plate = MSK.String.Trim(plate) end
    local lockDistance = Config.Settings.lockDistance

    -- prevent spamming
    if lockCooldown[playerId] then return end
    lockCooldown[playerId] = true
    SetTimeout(1000, function()
        lockCooldown[playerId] = nil
    end)

    local playerCoords = MSK.Player[playerId] and MSK.Player[playerId].coords or GetEntityCoords(GetPlayerPed(playerId))
    local vehicle

    if not plate then
        vehicle = GetClosestVehicle(playerCoords, GetOwnedVehiclesInRadius(playerId, playerCoords, lockDistance))

        if not vehicle or not DoesEntityExist(vehicle) then
            local veh = GetClosestVehicle(playerCoords)

            if veh and DoesEntityExist(veh) then
                return Config.Notification(playerId, Translation[Config.Locale]['not_has_key'], 'error')
            else
                return Config.Notification(playerId, Translation[Config.Locale]['not_in_distance'], 'error')
            end
        end
    else
        vehicle = GetClosestVehicleWithPlate(playerCoords, lockDistance, plate, GetVehiclesInBucket(GetPlayerRoutingBucket(playerId)))

        if not vehicle or not DoesEntityExist(vehicle) then
            return Config.Notification(playerId, Translation[Config.Locale]['not_in_distance_plate']:format(plate), 'error')
        end

        if not HasPlayerKeyOrIsVehicleOwner({ source = playerId }, plate, model) then
            return Config.Notification(playerId, Translation[Config.Locale]['not_has_key'], 'error')
        end
    end

    local lockState = GetVehicleLockState(vehicle)
    SetVehicleLockState(vehicle, not lockState, playerId)
end
exports('toggleLock', toggleLock)
RegisterNetEvent('msk_vehiclekeys:toggleLock', toggleLock)

lockCooldownAdmin = {}
toggleLockAdmin = function(playerId, plate, model)
    if not playerId then return end
    playerId = tonumber(playerId)
    if not IsAceAllowed(playerId) then return end
    if plate then plate = MSK.String.Trim(plate) end
    local lockDistance = Config.Settings.lockDistance

    -- prevent spamming
    if lockCooldownAdmin[playerId] then return end
    lockCooldownAdmin[playerId] = true
    SetTimeout(1000, function()
        lockCooldownAdmin[playerId] = nil
    end)

    local playerCoords = MSK.Player[playerId] and MSK.Player[playerId].coords or GetEntityCoords(GetPlayerPed(playerId))
    local vehicle

    if not plate then
        vehicle = GetClosestVehicle(playerCoords, GetVehiclesInBucket(GetPlayerRoutingBucket(playerId)))

        if not vehicle or not DoesEntityExist(vehicle) then
            return Config.Notification(playerId, Translation[Config.Locale]['not_in_distance'], 'error')
        end
    else
        vehicle = GetClosestVehicleWithPlate(playerCoords, lockDistance, plate, GetVehiclesInBucket(GetPlayerRoutingBucket(playerId)))

        if not vehicle or not DoesEntityExist(vehicle) then
            return Config.Notification(playerId, Translation[Config.Locale]['not_in_distance_plate']:format(plate), 'error')
        end

        if not HasPlayerKeyOrIsVehicleOwner({ source = playerId }, plate, model) then
            return Config.Notification(playerId, Translation[Config.Locale]['not_has_key'], 'error')
        end
    end

    local lockState = GetVehicleLockState(vehicle)
    SetVehicleLockState(vehicle, not lockState, playerId, lockState)
end
exports('toggleLockAdmin', toggleLockAdmin)
RegisterNetEvent('msk_vehiclekeys:toggleLockAdmin', toggleLockAdmin)

-- Clean up cooldown tables on disconnect (mini memory-leak fix)
AddEventHandler('playerDropped', function()
    local playerId = source
    lockCooldown[playerId] = nil
    lockCooldownAdmin[playerId] = nil
end)

----------------------------------------------------------------
-- License plate change
----------------------------------------------------------------

ChangeNumberPlate = function(oldPlate, newPlate, changeSQL)
    assert(oldPlate, 'oldPlate not found on function "ChangeNumberPlate"')
    assert(newPlate, 'newPlate not found on function "ChangeNumberPlate"')

    oldPlate = MSK.String.Trim(oldPlate)
    newPlate = MSK.String.Trim(newPlate)

    if changeSQL then
        MySQL.update(('UPDATE %s SET plate = @newPlate WHERE plate = @oldPlate'):format(VEHICLE_TABLE_NAME), {
            ['@oldPlate'] = oldPlate,
            ['@newPlate'] = newPlate,
        })
    end

    -- Update cache + msk_vehiclekeys_keys
    local seen, playerIdents = {}, {}

    for ident, keys in pairs(VehicleKeys) do
        for i = 1, #keys do
            if keys[i].plate == oldPlate then
                VehicleKeys[ident][i].plate = newPlate
                if not seen[ident] then
                    seen[ident] = true
                    playerIdents[#playerIdents + 1] = ident
                end
            end
        end
    end

    Storage.UpdatePlate(oldPlate, newPlate)
    Log('debug', ('Plate changed from %s to %s'):format(oldPlate, newPlate))

    -- Update inventory items (online directly, offline via DB)
    local offlineIdents = {}

    for i = 1, #playerIdents do
        local player = MSK.GetPlayer({ identifier = playerIdents[i] })

        if player then
            Inventory.UpdatePlateOnline(player, oldPlate, newPlate)
        else
            offlineIdents[#offlineIdents + 1] = playerIdents[i]
        end
    end

    Log('debug', ('Online Players Plate changed from %s to %s'):format(oldPlate, newPlate))

    for i = 1, #offlineIdents do
        Inventory.UpdatePlateOffline(offlineIdents[i], oldPlate, newPlate)
    end

    Log('debug', ('Offline Players Plate changed from %s to %s'):format(oldPlate, newPlate))
end
exports('ChangeNumberPlate', ChangeNumberPlate)

----------------------------------------------------------------
-- Events & RPC
----------------------------------------------------------------

-- Distance between two online players (server-side coords cache). Returns a large
-- number if either player is not tracked, so proximity checks fail closed.
local function playersDistance(a, b)
    local ca = MSK.Player[a] and MSK.Player[a].coords
    local cb = MSK.Player[b] and MSK.Player[b].coords
    if not ca or not cb then return math.huge end
    return #(ca - cb)
end

-- This is the CLIENT path (client export -> TriggerServerEvent).
RegisterNetEvent('msk_vehiclekeys:AddKey', function(targetId, vehicleData)
    local src = source
    if type(vehicleData) ~= 'table' or type(vehicleData.plate) ~= 'string' then return end

    local plate = MSK.String.Trim(vehicleData.plate)
    targetId = tonumber(targetId) or src

    local typ = vehicleData.type
    if typ ~= 'primary' and typ ~= 'secondary' and typ ~= 'temporary' then typ = 'primary' end

    -- Temporary keys skip the ownership check (RAM-only, cleared on reconnect).
    if typ ~= 'temporary' and not (IsVehicleOwner({ source = src }, plate) or HasPlayerKey({ source = src }, plate, vehicleData.model)) then
        return Config.Notification(src, Translation[Config.Locale]['not_vehicle_owner'], 'error')
    end

    if targetId == src then
        AddKey({ source = src }, { plate = plate, model = vehicleData.model, type = typ })
    else
        if playersDistance(src, targetId) > 10.0 then
            return Config.Notification(src, Translation[Config.Locale]['transfer_too_far'], 'error')
        end
        if typ ~= 'secondary' and typ ~= 'temporary' then typ = 'secondary' end
        AddKey({ source = targetId }, { plate = plate, model = vehicleData.model, type = typ })
    end
end)

RegisterNetEvent('msk_vehiclekeys:RemoveKey', function(targetId, vehicleData)
    local src = source
    if type(vehicleData) ~= 'table' or type(vehicleData.plate) ~= 'string' then return end
    local plate = MSK.String.Trim(vehicleData.plate)
    targetId = tonumber(targetId) or src

    if targetId ~= src and not IsVehicleOwner({ source = src }, plate) then
        return Config.Notification(src, Translation[Config.Locale]['not_vehicle_owner'], 'error')
    end

    RemoveKey({ source = targetId }, { plate = plate, type = vehicleData.type })
end)

RegisterNetEvent('msk_vehiclekeys:ExchangeVehicleLocks', function(vehicleData)
    ExchangeVehicleLocks({ source = source }, vehicleData)
end)

RegisterNetEvent('msk_vehiclekeys:TransferVehicle', function(buyerId, vehicleData)
    local sellerId = source
    buyerId = tonumber(buyerId)
    if not buyerId or buyerId == sellerId then return end
    if type(vehicleData) ~= 'table' or type(vehicleData.plate) ~= 'string' then return end
    local plate = MSK.String.Trim(vehicleData.plate)

    if not IsVehicleOwner({ source = sellerId }, plate) then
        return Config.Notification(sellerId, Translation[Config.Locale]['not_vehicle_owner'], 'error')
    end

    if playersDistance(sellerId, buyerId) > 10.0 then
        return Config.Notification(sellerId, Translation[Config.Locale]['transfer_too_far'], 'error')
    end

    TransferVehicle({ source = sellerId }, { source = buyerId }, { plate = plate, model = vehicleData.model })
end)

MSK.Register('msk_vehiclekeys:GetPlayerKeys', function(source)
    return GetPlayerKeys({ source = source })
end)

MSK.Register('msk_vehiclekeys:GetPlayerPrimaryKeys', function(source)
    return GetPlayerPrimaryKeys({ source = source })
end)

MSK.Register('msk_vehiclekeys:GetPlayerSecondaryKeys', function(source)
    return GetPlayerSecondaryKeys({ source = source })
end)

MSK.Register('msk_vehiclekeys:GetPlayerTempKeys', function(source)
    return GetPlayerTempKeys({ source = source })
end)

MSK.Register('msk_vehiclekeys:HasPlayerKey', function(source, _, plate, model)
    return HasPlayerKey({ source = source }, plate, model)
end)

MSK.Register('msk_vehiclekeys:HasPlayerPrimaryKey', function(source, _, plate, model)
    return HasPlayerPrimaryKey({ source = source }, plate, model)
end)

MSK.Register('msk_vehiclekeys:HasPlayerSecondaryKey', function(source, _, plate, model)
    return HasPlayerSecondaryKey({ source = source }, plate, model)
end)

MSK.Register('msk_vehiclekeys:HasPlayerTempKey', function(source, _, plate, model)
    return HasPlayerTempKey({ source = source }, plate, model)
end)

MSK.Register('msk_vehiclekeys:GetPlayerVehicles', function(source)
    return GetPlayerVehicles({ source = source })
end)

MSK.Register('msk_vehiclekeys:IsVehicleOwner', function(source, _, plate)
    return IsVehicleOwner({ source = source }, plate)
end)

MSK.Register('msk_vehiclekeys:HasPlayerKeyOrIsVehicleOwner', function(source, _, plate, model)
    return HasPlayerKeyOrIsVehicleOwner({ source = source }, plate, model)
end)

MSK.Register('msk_vehiclekeys:GetPlayerKeysAndVehicles', function(source)
    return GetPlayerKeysAndVehicles({ source = source })
end)

MSK.Register('msk_vehiclekeys:hasCorrectItem', function(source, _, item, plate)
    return hasCorrectItem({ source = source }, item, plate)
end)
