getIsDead = function()
    local isPlayerDead = IsPlayerDead(MSK.Player.clientId) or IsEntityDead(MSK.Player.ped) or IsPedFatallyInjured(MSK.Player.ped)

    if GetResourceState("visn_are") ~= "missing" then
        local healthBuffer = exports.visn_are:GetHealthBuffer()
        isPlayerDead = healthBuffer.unconscious
    end

    if GetResourceState("osp_ambulance") ~= "missing" then
        local data = exports.osp_ambulance:GetAmbulanceData(MSK.Player.serverId)
        isPlayerDead = data.isDead or data.inLastStand
    end

    return isPlayerDead
end

showTransferDialog = function(targetId, vehicle)
    local plate
    local label = ''

    if type(vehicle) == 'table' then
        plate = vehicle.plate
        model = vehicle.model
        label = MSK.GetVehicleLabelFromModel(model)

    else
        assert(vehicle and DoesEntityExist(vehicle), 'Parameter "vehicle" is nil or the Vehicle does not exist on function ExchangeVehicleLocks')
        plate = GetVehicleNumberPlateText(vehicle)
        model = GetEntityModel(vehicle)
        label = MSK.GetVehicleLabel(vehicle)
    end

    local input = lib.inputDialog(Translation[Config.Locale]['dialog_title']:format(lable, plate), {
        {type = 'number', label = Translation[Config.Locale]['dialog_price'], description = Translation[Config.Locale]['dialog_price_desc'], required = true},
    })

    if not input then return end
    TriggerServerEvent('msk_vehiclekeys:showTransferDialog', targetId, {label = label, plate = plate, model = model, price = input[1]})
end

-- Model list entries are spawn NAMES (strings), hashed for comparison against
-- the numeric model hash. Numeric entries (legacy) are still accepted as-is.
local function toModelHash(m)
    if type(m) == 'string' then return GetHashKey(m) end
    return m
end

IsVehicleWhitelisted = function(plate, model)
    local models = Config.Whitelist.models
    local plates = Config.Whitelist.plates

    if model then
        for i = 1, #models do
            if toModelHash(models[i]) == model then
                return true
            end
        end
    end

    if plate then
        plate = MSK.String.Trim(plate, true)

        for i = 1, #plates do
            if string.find(plate, MSK.String.Trim(plates[i], true)) then
                return true
            end
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
            if toModelHash(models[i]) == model then
                return true
            end
        end
    end

    if plate then
        plate = MSK.String.Trim(plate, true)

        for i = 1, #plates do
            if string.find(plate, MSK.String.Trim(plates[i], true)) then
                return true
            end
        end
    end

    return false
end
exports('IsVehicleBlacklisted', IsVehicleBlacklisted)

CloseVehicleDoors = function(vehicle)
    assert(vehicle and DoesEntityExist(vehicle), 'Parameter "vehicle" is nil or the Vehicle does not exist on function CloseVehicleDoors')

    for doorIndex = 0, 7 do
		if (DoesVehicleHaveDoor(vehicle, doorIndex) and GetVehicleDoorAngleRatio(vehicle, doorIndex) > 0) then
			SetVehicleDoorShut(vehicle, doorIndex, false)
		end
	end
end
exports('CloseVehicleDoors', CloseVehicleDoors)

playLockAnim = function()
    local playerPed = MSK.Player.ped
    if IsPedInAnyVehicle(playerPed) then return end
    local propHash = Config.Settings.animation.prop
    if type(propHash) == 'string' then propHash = joaat(propHash) end
    local dict = Config.Settings.animation.dict
    local anim = Config.Settings.animation.anim

    CreateThread(function()
        MSK.Request.Model(propHash)
        MSK.Request.AnimDict(dict)

        local object = CreateObjectNoOffset(propHash, GetEntityCoords(playerPed), true, true, false)
        SetEntityCollision(object, false, false)
        SetModelAsNoLongerNeeded(propHash)

        AttachEntityToEntity(object, playerPed, GetEntityBoneIndexByName(playerPed, "IK_R_Hand"), vector3(0.08, 0.025, -0.01), vector3(0, 70, 140), false, false, true, false, 2, true)
        TaskPlayAnim(playerPed, dict, anim, 8.0, 8.0, -1, 48, 1, false, false, false)
        RemoveAnimDict(dict)

        Wait(1500)

        if DoesEntityExist(object) then 
            DeleteEntity(object) 
        end
    end)
end
exports('playLockAnim', playLockAnim)

playDoorLockEffects = function(vehicle, state)
    local _, lightsOn = GetVehicleLightsState(vehicle)

    if state then
        PlayVehicleDoorCloseSound(vehicle, 0)

        CreateThread(function()
			if (lightsOn) then
				SetVehicleLights(vehicle, 1)
				Wait(200)
			end

			SetVehicleLights(vehicle, 2)
			Wait(500)
			SetVehicleLights(vehicle, 1)
			Wait(200)
			SetVehicleLights(vehicle, 0)
		end)
    else
        PlayVehicleDoorOpenSound(vehicle, 0)

        CreateThread(function()
			if (lightsOn) then
				SetVehicleLights(vehicle, 1)
				Wait(100)
			end

			SetVehicleLights(vehicle, 2)
			for i = 1, 5 do
				Wait(100)
				SetVehicleLights(vehicle, 1)
				Wait(100)
				SetVehicleLights(vehicle, 2)
			end

			Wait(200)
			SetVehicleLights(vehicle, 0)
		end)
    end
end
exports('playDoorLockEffects', playDoorLockEffects)

SetVehicleLockState = function(vehicle, state, forceLock)
    assert(vehicle and DoesEntityExist(vehicle), ('Parameter "vehicle" is nil or the Vehicle does not exist on function SetVehicleLockState (reveived %s)'):format(vehicle))

    Entity(vehicle).state:set('isLocked', state, true)
    if state then CloseVehicleDoors(vehicle) end
    SetVehicleLockStatus(vehicle, state and LockStatus.Locked or LockStatus.Unlocked)

    if forceLock then
        Entity(vehicle).state:set('forceLock', true, true)
        return
    end

    local invoke = GetInvokingResource()
    if invoke and invoke ~= GetCurrentResourceName() then
        Entity(vehicle).state:set('forceLock', true, true)
    elseif not invoke or invoke and invoke == GetCurrentResourceName() then
        Entity(vehicle).state:set('forceLock', false, true)
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
    assert(vehicle and DoesEntityExist(vehicle), ('Parameter "vehicle" is nil or the Vehicle does not exist on function GetVehicleLockState (reveived %s)'):format(vehicle))

    if Entity(vehicle).state.isLocked == nil then
        Entity(vehicle).state:set('isLocked', GetVehicleDoorLockStatus(vehicle) == LockStatus.Locked, true)
    end

    return Entity(vehicle).state.isLocked
end
exports('GetVehicleLockState', GetVehicleLockState)

GetVehicleLockStatus = function(vehicle)
    assert(vehicle and DoesEntityExist(vehicle), ('Parameter "vehicle" is nil or the Vehicle does not exist on function GetVehicleLockStatus (reveived %s)'):format(vehicle))

    if Entity(vehicle).state.lockState == nil then
        SetVehicleLockStatus(vehicle, GetVehicleLockState(vehicle) and LockStatus.Locked or LockStatus.Unlocked)
    end

    return Entity(vehicle).state.lockState
end
exports('GetVehicleLockStatus', GetVehicleLockStatus)

toggleLock = function(data, slot)
    local plate = slot?.metadata?.plate
    local model = slot?.metadata?.model
    local vehicle = slot?.metadata?.vehicle

    if vehicle and not DoesEntityExist(vehicle) then return end

    if vehicle and DoesEntityExist(vehicle) then
        plate = MSK.String.Trim(GetVehicleNumberPlateText(vehicle))
        model = GetEntityModel(vehicle)
    end

	TriggerServerEvent('msk_vehiclekeys:toggleLock', MSK.Player.serverId, plate, model)
end
exports('toggleLock', toggleLock)

toggleLockAdmin = function(data)
    if not data or type(data) ~= 'table' then return end
    local plate, model = nil

    if data.vehicle then
        assert(DoesEntityExist(data.vehicle), ('The Vehicle does not exist on function toggleLockAdmin (reveived %s)'):format(data.vehicle))
        plate = GetVehicleNumberPlateText(data.vehicle)
        model = GetEntityModel(data.vehicle)
    end

    if data.plate then
        plate = data.plate
    end

    if data.model then
        assert(IsModelValid(data.model), ('The Model does not exist on function toggleLockAdmin (reveived %s)'):format(data.model))
        model = data.model
    end

    if not plate or not model then
        return error(('expected 2 parameters, received 1 on function toggleLockAdmin (reveived: plate %s - model %s)'):format(plate, model))
    end

	TriggerServerEvent('msk_vehiclekeys:toggleLockAdmin', MSK.Player.serverId, plate, model)
end
exports('toggleLockAdmin', toggleLockAdmin)

RefreshPlayerKeys = function(rtn)
    if rtn then
        return MSK.Trigger('msk_vehiclekeys:RefreshPlayerKeys')
    end
    TriggerServerEvent('msk_vehiclekeys:RefreshPlayerKeys', MSK.Player.serverId)
end
exports('RefreshPlayerKeys', RefreshPlayerKeys)

GetAllVehicleKeys = function()
    return MSK.Trigger('msk_vehiclekeys:GetAllVehicleKeys')
end
exports('GetAllVehicleKeys', GetAllVehicleKeys)

GetPlayerKeys = function(playerId)
    return MSK.Trigger('msk_vehiclekeys:GetPlayerKeys', playerId or MSK.Player.serverId)
end
exports('GetPlayerKeys', GetPlayerKeys)

GetPlayerPrimaryKeys = function(playerId)
    return MSK.Trigger('msk_vehiclekeys:GetPlayerPrimaryKeys', playerId or MSK.Player.serverId)
end
exports('GetPlayerPrimaryKeys', GetPlayerPrimaryKeys)

GetPlayerSecondaryKeys = function(playerId)
    return MSK.Trigger('msk_vehiclekeys:GetPlayerSecondaryKeys', playerId or MSK.Player.serverId)
end
exports('GetPlayerSecondaryKeys', GetPlayerSecondaryKeys)

GetPlayerTempKeys = function(playerId)
    return MSK.Trigger('msk_vehiclekeys:GetPlayerTempKeys', playerId or MSK.Player.serverId)
end
exports('GetPlayerTempKeys', GetPlayerTempKeys)

HasPlayerKey = function(vehicle)
    assert(vehicle and DoesEntityExist(vehicle), ('Parameter "vehicle" is nil or the Vehicle does not exist on function HasPlayerKey (reveived %s)'):format(vehicle))
    return MSK.Trigger('msk_vehiclekeys:HasPlayerKey', {source = MSK.Player.serverId}, GetVehicleNumberPlateText(vehicle), GetEntityModel(vehicle))
end
exports('HasPlayerKey', HasPlayerKey)

HasPlayerPrimaryKey = function(vehicle)
    assert(vehicle and DoesEntityExist(vehicle), ('Parameter "vehicle" is nil or the Vehicle does not exist on function HasPlayerPrimaryKey (reveived %s)'):format(vehicle))
    return MSK.Trigger('msk_vehiclekeys:HasPlayerPrimaryKey', {source = MSK.Player.serverId}, GetVehicleNumberPlateText(vehicle), GetEntityModel(vehicle))
end
exports('HasPlayerPrimaryKey', HasPlayerPrimaryKey)

HasPlayerSecondaryKey = function(vehicle)
    assert(vehicle and DoesEntityExist(vehicle), ('Parameter "vehicle" is nil or the Vehicle does not exist on function HasPlayerSecondaryKey (reveived %s)'):format(vehicle))
    return MSK.Trigger('msk_vehiclekeys:HasPlayerSecondaryKey', {source = MSK.Player.serverId}, GetVehicleNumberPlateText(vehicle), GetEntityModel(vehicle))
end
exports('HasPlayerSecondaryKey', HasPlayerSecondaryKey)

HasPlayerTempKey = function(vehicle)
    assert(vehicle and DoesEntityExist(vehicle), ('Parameter "vehicle" is nil or the Vehicle does not exist on function HasPlayerTempKey (reveived %s)'):format(vehicle))
    return MSK.Trigger('msk_vehiclekeys:HasPlayerTempKey', {source = MSK.Player.serverId}, GetVehicleNumberPlateText(vehicle), GetEntityModel(vehicle))
end
exports('HasPlayerTempKey', HasPlayerTempKey)

GetPlayerVehicles = function(playerId)
    return MSK.Trigger('msk_vehiclekeys:GetPlayerVehicles', playerId or MSK.Player.serverId)
end
exports('GetPlayerVehicles', GetPlayerVehicles)

IsVehicleOwner = function(vehicle)
    assert(vehicle and DoesEntityExist(vehicle), ('Parameter "vehicle" is nil or the Vehicle does not exist on function IsVehicleOwner (reveived %s)'):format(vehicle))
    return MSK.Trigger('msk_vehiclekeys:IsVehicleOwner', {source = MSK.Player.serverId}, GetVehicleNumberPlateText(vehicle))
end
exports('IsVehicleOwner', IsVehicleOwner)

HasPlayerKeyOrIsVehicleOwner = function(vehicle)
    assert(vehicle and DoesEntityExist(vehicle), ('Parameter "vehicle" is nil or the Vehicle does not exist on function HasPlayerKeyOrIsVehicleOwner (reveived %s)'):format(vehicle))
    return MSK.Trigger('msk_vehiclekeys:HasPlayerKeyOrIsVehicleOwner', {source = MSK.Player.serverId}, GetVehicleNumberPlateText(vehicle), GetEntityModel(vehicle))
end
exports('HasPlayerKeyOrIsVehicleOwner', HasPlayerKeyOrIsVehicleOwner)

GetPlayerKeysAndVehicles = function(playerId)
    return MSK.Trigger('msk_vehiclekeys:GetPlayerKeysAndVehicles', playerId or MSK.Player.serverId)
end
exports('GetPlayerKeysAndVehicles', GetPlayerKeysAndVehicles)

AddKey = function(vehicle, typ, playerId)
    assert(vehicle, ('Parameter "vehicle" is nil on function AddKey (reveived %s)'):format(vehicle))
    assert(typ, ('Parameter "type" is nil on function AddKey (reveived %s)'):format(typ))
    local plate, model = nil, nil
    
    if type(vehicle) == 'table' then
        assert(vehicle.plate, ('Parameter "vehicle.plate" is nil on function AddKey (reveived %s - %s)'):format(vehicle, vehicle.plate))
        plate = vehicle.plate
        model = vehicle.model
    else
        assert(DoesEntityExist(vehicle), ('Parameter "vehicle" the Vehicle does not exist on function AddKey (reveived %s)'):format(vehicle))
        plate = GetVehicleNumberPlateText(vehicle)
        model = GetEntityModel(vehicle)
    end
    
    TriggerServerEvent('msk_vehiclekeys:AddKey', playerId or MSK.Player.serverId, {plate = plate, model = model, type = typ})
end
exports('AddKey', AddKey)

AddPrimaryKey = function(vehicle, playerId)
    AddKey(vehicle, 'primary', playerId)
end
exports('AddPrimaryKey', AddPrimaryKey)

AddSecondaryKey = function(vehicle, playerId)
    AddKey(vehicle, 'secondary', playerId)
end
exports('AddSecondaryKey', AddSecondaryKey)

AddTempKey = function(vehicle, playerId)
    AddKey(vehicle, 'temporary', playerId)
end
exports('AddTempKey', AddTempKey)

RemoveKey = function(vehicle, typ, playerId)
    assert(vehicle, ('Parameter "vehicle" is nil on function RemoveKey (reveived %s)'):format(vehicle))
    assert(typ, 'Parameter "type" is nil on function RemoveKey')
    local plate, model = nil, nil
    
    if type(vehicle) == 'table' then
        assert(vehicle.plate, ('Parameter "vehicle.plate" is nil on function RemoveKey (reveived %s - %s)'):format(vehicle, vehicle.plate))
        plate = vehicle.plate
        model = vehicle.model
    else
        assert(DoesEntityExist(vehicle), ('Parameter "vehicle" the Vehicle does not exist on function RemoveKey (reveived %s)'):format(vehicle))
        plate = GetVehicleNumberPlateText(vehicle)
        model = GetEntityModel(vehicle)
    end
    
    TriggerServerEvent('msk_vehiclekeys:RemoveKey', playerId or MSK.Player.serverId, {plate = plate, model = model, type = typ})
end
exports('RemoveKey', RemoveKey)

RemovePrimaryKey = function(vehicle, playerId)
    RemoveKey(vehicle, 'primary', playerId)
end
exports('RemovePrimaryKey', RemovePrimaryKey)

RemoveSecondaryKey = function(vehicle, playerId)
    RemoveKey(vehicle, 'secondary', playerId)
end
exports('RemoveSecondaryKey', RemoveSecondaryKey)

RemoveTempKey = function(vehicle, playerId)
    RemoveKey(vehicle, 'temporary', playerId)
end
exports('RemoveTempKey', RemoveTempKey)

ExchangeVehicleLocks = function(vehicle)
    assert(vehicle, ('Parameter "vehicle" is nil on function ExchangeVehicleLocks (reveived %s)'):format(vehicle))
    local plate, model = nil, nil

    if type(vehicle) == 'table' then
        assert(vehicle.plate, ('Parameter "vehicle.plate" is nil on function ExchangeVehicleLocks (reveived %s - %s)'):format(vehicle, vehicle.plate))
        plate = vehicle.plate
        model = vehicle.model
    else
        assert(DoesEntityExist(vehicle), ('Parameter "vehicle" is nil or the Vehicle does not exist on function ExchangeVehicleLocks (reveived %s)'):format(vehicle))
        plate = GetVehicleNumberPlateText(vehicle)
        model = GetEntityModel(vehicle)
    end

    TriggerServerEvent('msk_vehiclekeys:ExchangeVehicleLocks', {plate = plate, model = model})
end
exports('ExchangeVehicleLocks', ExchangeVehicleLocks)

TransferVehicle = function(targetId, vehicle, showDialog)
    assert(targetId, ('Parameter "targetId" is nil on function TransferVehicle (reveived %s)'):format(targetId))
    assert(vehicle, ('Parameter "vehicle" is nil on function TransferVehicle (reveived %s)'):format(vehicle))

    if Config.Settings.transfer.needItem then
        if not hasCorrectItem(MSK.Player.serverId, Config.Settings.transfer, type(vehicle) == 'table' and vehicle.plate or DoesEntityExist(vehicle) and GetVehicleNumberPlateText(vehicle)) then
            Config.Notification(nil, Translation[Config.Locale]['no_item_found'], 'error')
            return
        end
    end

    if showDialog then
        showTransferDialog(targetId, vehicle)
        return
    end

    local plate, model = nil, nil

    if type(vehicle) == 'table' then
        plate = vehicle.plate
        model = vehicle.model
    else
        plate = GetVehicleNumberPlateText(vehicle)
        model = GetEntityModel(vehicle)
    end

    TriggerServerEvent('msk_vehiclekeys:TransferVehicle', targetId, {plate = plate, model = model})
end
exports('TransferVehicle', TransferVehicle)