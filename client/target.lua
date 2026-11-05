if Config.VehicleTarget.enable then
	if Config.VehicleTarget.script == 'ox_target' and GetResourceState(Config.VehicleTarget.script) ~= "missing" then
		exports.ox_target:addGlobalVehicle({
			label = Translation[Config.Locale]['(un)lock_vehicle'],
			name = 'lock_vehicle',
			icon = 'fa-solid fa-key',
			distance = 2.5,
			onSelect = function(data)
				local plate = GetVehicleNumberPlateText(data.entity)
                local model = GetEntityModel(data.entity)

				toggleLock(nil, {metadata = {plate = plate, model = model}})
			end
		})
	end
end

if Config.VehicleTarget.selectSeat then
    if Config.VehicleTarget.script == 'ox_target' and GetResourceState(Config.VehicleTarget.script) ~= "missing" then
        local doorBones = {
            [0] = 'dside_f', -- driver // door left front
            [1] = 'pside_f',  -- passenger // door right front
            [2] = 'dside_r', -- door left back
            [3] = 'pside_r', -- door right back
        }

        local CanInteractWithDoor = function(entity, coords, doorIndex, useOffset)
            if not GetIsDoorValid(entity, doorIndex) or GetVehicleLockState(entity) or IsVehicleDoorDamaged(entity, doorIndex) and (not useOffset and IsVehicleSeatFree(vehicle, doorIndex - 1)) then return end
        
            if useOffset then
                return GetVehicleModelNumberOfSeats(GetEntityModel(entity)) > 4
            end
        
            local boneName = doorBones[doorIndex]
            if not boneName then return false end
        
            local boneId = GetEntityBoneIndexByName(entity, 'door_'..boneName)
        
            if boneId ~= -1 and not GetVehicleLockState(entity) then
                return #(coords - GetEntityBonePosition_2(entity, boneId)) < 0.5 or #(coords - GetEntityBonePosition_2(entity, GetEntityBoneIndexByName(entity, 'seat_'..boneName))) < 0.72
            end
        end

        exports.ox_target:addGlobalVehicle({
            {
                name = 'door_dside_f',
                icon = 'fa-solid fa-caret-up',
                label = Translation[Config.Locale]['seat_dside_f'],
                bones = { 'door_dside_f', 'seat_dside_f' },
                distance = 2.5,
                canInteract = function(entity, distance, coords, name)
                    return CanInteractWithDoor(entity, coords, 0)
                end,
                onSelect = function(data)
                    local vehicle = data.entity
        
                    TaskEnterVehicle(MSK.Player.ped, vehicle, 10000, -1, 1.0, 1, 0)
                end
            },
            {
                name = 'door_pside_f',
                icon = 'fa-solid fa-caret-up',
                label = Translation[Config.Locale]['seat_pside_f'],
                bones = { 'door_pside_f', 'seat_pside_f' },
                distance = 2.5,
                canInteract = function(entity, distance, coords, name)
                    return CanInteractWithDoor(entity, coords, 1)
                end,
                onSelect = function(data)
                    local vehicle = data.entity
        
                    TaskEnterVehicle(MSK.Player.ped, vehicle, 10000, 0, 1.0, 1, 0)
                end
            },
            {
                name = 'door_dside_r',
                icon = 'fa-solid fa-caret-up',
                label = Translation[Config.Locale]['seat_dside_r'],
                bones = { 'door_dside_r', 'seat_dside_r' },
                distance = 2.5,
                canInteract = function(entity, distance, coords, name)
                    return CanInteractWithDoor(entity, coords, 2)
                end,
                onSelect = function(data)
                    local vehicle = data.entity
        
                    TaskEnterVehicle(MSK.Player.ped, vehicle, 10000, 1, 1.0, 1, 0)
                end
            },
            {
                name = 'door_pside_r',
                icon = 'fa-solid fa-caret-up',
                label = Translation[Config.Locale]['seat_pside_r'],
                bones = { 'door_pside_r', 'seat_pside_r' },
                distance = 2.5,
                canInteract = function(entity, distance, coords, name)
                    return CanInteractWithDoor(entity, coords, 3)
                end,
                onSelect = function(data)
                    local vehicle = data.entity
        
                    TaskEnterVehicle(MSK.Player.ped, vehicle, 10000, 2, 1.0, 1, 0)
                end
            },
            {
                name = 'seat_r',
                icon = 'fa-solid fa-caret-up',
                label = Translation[Config.Locale]['seat_r'],
                offset = vec3(0.5, 0, 0.5),
                distance = 2.5,
                canInteract = function(entity, distance, coords, name)
                    return CanInteractWithDoor(entity, coords, 4, true)
                end,
                onSelect = function(data)
                    local vehicle = data.entity
                    local seat = 4
        
                    for i = 1, 4 do
                        local seatIndex = i + 2
        
                        if IsVehicleSeatFree(vehicle, seatIndex) then
                            seat = seatIndex
                            break
                        end
                    end
        
                    TaskEnterVehicle(MSK.Player.ped, vehicle, 10000, seat, 1.0, 1, 0)
                end
            },
        })
    end
end