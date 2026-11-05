-- Debug logging wrapper. Only active when Config.Debug = true.
-- (Formerly 'logging' - renamed to 'Log' to avoid namespace pollution.)
Log = function(code, ...)
    if not Config.Debug then return end
    MSK.Logging(code, ...)
end

-- Normalizes any parameter (source, identifier, player object) into a consistent table {source=...} / {identifier=...}.
checkParameter = function(param)
    local data = param

    if type(param) ~= 'table' then
        if tonumber(param) then
            data = {source = param}
        else
            data = {identifier = param}
        end
    end

    return data
end

-- Returns the framework player object from source / identifier / player.
GetPlayerFromData = function(data)
    local Player
    local data = checkParameter(data)

    if data.source then
        Player = GetPlayerFromId(data.source)
    elseif data.identifier then
        Player = GetPlayerFromIdentifier(data.identifier)
    elseif data.player then
        Player = data.player
    end

    return Player
end

----------------------------------------------------------------
-- Key helpers
----------------------------------------------------------------

-- Finds a key by its plate in a key list.
getKeyFromPlate = function(keys, plate)
    for i = 1, #keys do
        if keys[i].plate == plate then
            return keys[i]
        end
    end
    return false
end

----------------------------------------------------------------
-- Entity helpers
----------------------------------------------------------------

-- All vehicles in a specific routing bucket.
GetVehiclesInBucket = function(bucket)
    local vehiclesInBucket = {}
    local vehicles = GetAllVehicles()

    for i = 1, #vehicles do
        if DoesEntityExist(vehicles[i]) and GetEntityRoutingBucket(vehicles[i]) == bucket then
            vehiclesInBucket[#vehiclesInBucket + 1] = vehicles[i]
        end
    end

    return vehiclesInBucket
end
exports('GetVehiclesInBucket', GetVehiclesInBucket)

-- Returns all player peds (isPlayerEntity=true) or all vehicles.
GetEntities = function(isPlayerEntity)
    local entities = {}

    if isPlayerEntity then
        for _, playerId in ipairs(GetPlayers()) do
            local ped = GetPlayerPed(playerId)

            if DoesEntityExist(ped) then
                entities[playerId] = ped
            end
        end
    else
        entities = GetAllVehicles()
    end

    return entities
end

-- Closest entity to coords.
GetClosestEntity = function(isPlayerEntity, coords, entities)
    local closestEntity, closestDistance = -1, -1
    local entites = entities or GetEntities(isPlayerEntity)

    if coords then
        coords = vector3(coords.x, coords.y, coords.z)
    else
        coords = GetEntityCoords(GetPlayerPed(isPlayerEntity))
    end

    for k, entity in pairs(entites) do
        local distance = #(coords - GetEntityCoords(entity))

        if closestDistance == -1 or distance <= closestDistance and (not isPlayerEntity or isPlayerEntity and entity ~= GetPlayerPed(isPlayerEntity)) then
            closestEntity, closestDistance = isPlayerEntity and k or entity, distance
        end
    end

    return closestEntity, closestDistance
end

-- Closest vehicle with a matching plate.
GetClosestEntityWithPlate = function(coords, distance, plate, entities)
    local closestEntity, closestDistance = -1, -1
    local entites = entities or GetEntities(false)
    plate = MSK.String.Trim(plate)

    if coords then
        coords = vector3(coords.x, coords.y, coords.z)
    else
        return closestEntity, closestDistance
    end

    for k, entity in pairs(entites) do
        local distance = #(coords - GetEntityCoords(entity))

        if (closestDistance == -1 or distance <= closestDistance) and plate == MSK.String.Trim(GetVehicleNumberPlateText(entity)) then
            closestEntity, closestDistance = entity, distance
        end
    end

    return closestEntity, closestDistance
end

----------------------------------------------------------------
-- DB helper (owned-vehicle table lookup, not msk_vehiclekeys_keys)
----------------------------------------------------------------

-- Checks whether a vehicle with the given plate exists in the owned-vehicles table.
IsVehicleOwned = function(source, plate)
    local isOwned = MySQL.scalar.await(('SELECT COUNT(plate) FROM %s WHERE plate = @plate'):format(VEHICLE_TABLE_NAME), {
        ['@plate'] = MSK.String.Trim(plate),
    }) > 0

    return isOwned
end
exports('IsVehicleOwned', IsVehicleOwned)
MSK.Register('msk_vehiclekeys:isVehicleOwned', IsVehicleOwned)
