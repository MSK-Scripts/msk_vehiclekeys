-- Framework detection and the player-data mirror that used to sit here are
-- gone. msk_core 4.0.0 keeps that copy itself and hands the data over in one
-- shape, so this block only duplicated it, and nothing in this resource read
-- ESX.PlayerData or QBCore.PlayerData anywhere else. Qbox was missing from it
-- entirely. Use MSK.GetPlayerData() when you need the local player.

LockStatus = {
	Unlocked = 1,
	Locked = 2
}

if Config.Commands.lock.enable then
	RegisterCommand(Config.Commands.lock.command, function(source, args, rawCommand)
		local vehicle = MSK.GetClosestVehicle()
		if not DoesEntityExist(vehicle) then return end
		toggleLock(nil, { metadata = { vehicle = vehicle } })
	end)

	if Config.Hotkeys.lock.enable then
		RegisterKeyMapping(Config.Commands.lock.command, '(Un)Lock Vehicle', 'keyboard', Config.Hotkeys.lock.key)
	end
end

if Config.Commands.keyMenu.enable then
	RegisterCommand(Config.Commands.keyMenu.command, function(source, args, rawCommand)
		openKeysMenu()
	end)

	if Config.Hotkeys.keyMenu.enable then
		RegisterKeyMapping(Config.Commands.keyMenu.command, 'Open Keys Menu', 'keyboard', Config.Hotkeys.keyMenu.key)
	end
end

openDialog = function()
	local vehicle, vehDist = MSK.GetClosestVehicle()

    if vehicle and DoesEntityExist(vehicle) and vehDist <= 5.0 then
		if not IsVehicleOwner(vehicle) then
			Config.Notification(nil, Translation[Config.Locale]['not_vehicle_owner'], 'error')
			return
		end
        local player, plyDist = MSK.GetClosestPlayer()

        if player ~= -1 and plyDist <= 2.0 then
            TransferVehicle(GetPlayerServerId(player), vehicle, true)
        else
            Config.Notification(nil, Translation[Config.Locale]['no_player_nearby'], 'error')
        end
    else
        Config.Notification(nil, Translation[Config.Locale]['no_vehicle_nearby'], 'error')
    end
end
exports('openDialog', openDialog)
RegisterNetEvent('msk_vehiclekeys:openDialog', openDialog)

RegisterNetEvent('msk_vehiclekeys:setVehicleLockState', function(netId, state, adminLock)
	local vehicle = NetworkGetEntityFromNetworkId(netId)
	local vehicleLabel = MSK.GetVehicleLabel(vehicle)
	local plate = GetVehicleNumberPlateText(vehicle)

	playLockAnim(state)
	CloseVehicleDoors(vehicle) 
	SetVehicleLockState(vehicle, state, adminLock)

	if state then
		PlaySoundFromEntity(-1, "Remote_Control_Close", vehicle, "PI_Menu_Sounds", 1, 0)
		Config.Notification(nil, Translation[Config.Locale]['vehicle_lock']:format(vehicleLabel, plate), 'info')
	else
		PlaySoundFromEntity(-1, "Remote_Control_Open", vehicle, "PI_Menu_Sounds", 1, 0)
		Config.Notification(nil, Translation[Config.Locale]['vehicle_unlock']:format(vehicleLabel, plate), 'info')
	end
end)

RegisterNetEvent('msk_vehiclekeys:playDoorLockEffects', function(netId, state)
	if not NetworkDoesEntityExistWithNetworkId(netId) then return end
	local vehicle = NetworkGetEntityFromNetworkId(netId)
	if not DoesEntityExist(vehicle) then return end
	playDoorLockEffects(vehicle, state)
end)

RegisterNetEvent('msk_vehiclekeys:showTransferDialog', function(sellerId, vehicleData)
	local alert = lib.alertDialog({
        header = Translation[Config.Locale]['diablog_buy_title'],
        content = Translation[Config.Locale]['diablog_buy_desc']:format(vehicleData.label, vehicleData.price),
        centered = true,
        cancel = true,
        labels = {
            confirm = Translation[Config.Locale]['dialog_confirm'],
            cancel = Translation[Config.Locale]['dialog_cancel']
        }
    })

	if alert == 'confirm' then
		TriggerServerEvent('msk_vehiclekeys:sellVehicle', sellerId, vehicleData)
	end
end)

-- Locksmith peds/blips. Refactored to be rebuildable so the admin dashboard can
-- push location changes live (msk_vehiclekeys:syncDefinitions -> RebuildLocksmiths).
do
	local isPedLoaded = {}
	local lsBlips = {}
	local shown = false

	local function buildBlips()
		for i = 1, #lsBlips do RemoveBlip(lsBlips[i]) end
		lsBlips = {}
		if not Config.Locksmith.enable or type(Config.Locksmith.locations) ~= 'table' then return end

		for k, mechanic in pairs(Config.Locksmith.locations) do
			for kId, coords in pairs(mechanic.coords) do
				if mechanic.blip and mechanic.blip.enable then
					local blip = AddBlipForCoord(coords.x, coords.y, coords.z)

					SetBlipSprite(blip, mechanic.blip.id)
					SetBlipScale(blip, mechanic.blip.scale)
					SetBlipDisplay(blip, 2)
					SetBlipColour(blip, mechanic.blip.color)
					SetBlipAsShortRange(blip, true)
					BeginTextCommandSetBlipName('STRING')
					AddTextComponentSubstringPlayerName(mechanic.blip.label)
					EndTextCommandSetBlipName(blip)

					lsBlips[#lsBlips + 1] = blip
				end
			end
		end
	end

	local function deletePed(v)
		if v and v.loaded then
			if DoesEntityExist(v.npc) then DeleteEntity(v.npc) end
			if v.hash then SetModelAsNoLongerNeeded(v.hash) end
			if Config.Locksmith.targetSystem and Config.Locksmith.targetSystem.enable then
				unregisterTarget(v.npc, v.coords)
			end
		end
	end

	-- Live rebuild: tear down every ped + blip, then rebuild from the current
	-- Config.Locksmith.locations (updated by client/admin/sync.lua).
	function RebuildLocksmiths()
		for id, v in pairs(isPedLoaded) do deletePed(v) end
		isPedLoaded = {}
		buildBlips()
	end

	buildBlips()

	CreateThread(function()
		while true do
			local sleep = 500

			if Config.Locksmith.enable and type(Config.Locksmith.locations) == 'table' then
				sleep = 250
				currentMechanic = nil
				local seen = {}

				for k, mechanic in pairs(Config.Locksmith.locations) do
					for kId, coords in pairs(mechanic.coords) do
						local vec3 = vec3(coords.x, coords.y, coords.z)
						local distance = #(MSK.Player.coords - vec3)
						local pedmodel = mechanic.pedmodel
						if type(pedmodel) == 'string' then pedmodel = joaat(pedmodel) end
						local npcID = pedmodel .. '-' .. k .. '-' .. kId
						seen[npcID] = true

						if distance <= 50.0 then
							if not isPedLoaded[npcID] or not isPedLoaded[npcID].loaded then
								isPedLoaded[npcID] = {}

								MSK.Request.Model(pedmodel)

								local npc = CreatePed(4, pedmodel, coords.x, coords.y, coords.z - 1.0, coords.w or coords.h, false, true)
                                FreezeEntityPosition(npc, true)
                                SetEntityHeading(npc, coords.w or coords.h)
                                SetEntityInvincible(npc, true)
                                SetBlockingOfNonTemporaryEvents(npc, true)
								SetModelAsNoLongerNeeded(pedmodel)

								isPedLoaded[npcID] = {
									loaded = true,
									inDistance = true,
									hash = pedmodel,
									pedmodel = pedmodel,
									npc = npc,
									npcID = npcID,
									coords = vec3
								}

								if Config.Locksmith.targetSystem.enable then
									registerTarget(mechanic.label, npc, vec3)
								end
							else
								isPedLoaded[npcID].inDistance = true
							end
						else
							if isPedLoaded[npcID] and isPedLoaded[npcID].loaded then
                                isPedLoaded[npcID].inDistance = false
                            end
						end

						if Config.Locksmith.npcVoice.enable then
							for k, v in pairs(isPedLoaded) do
								if isPedLoaded[v.npcID] and isPedLoaded[v.npcID].loaded then
                                    local dist = #(MSK.Player.coords - isPedLoaded[v.npcID].coords)

                                    if dist < Config.Locksmith.npcVoice.inRange and not isPedLoaded[v.npcID].hasSpeak then
                                        PlayPedAmbientSpeechNative(isPedLoaded[v.npcID].npc, 'GENERIC_HI', 'SPEECH_PARAMS_FORCE_NO_REPEAT_FRONTEND')
                                        isPedLoaded[v.npcID].hasSpeak = true
                                    elseif dist > Config.Locksmith.npcVoice.outRange and isPedLoaded[v.npcID].hasSpeak then
                                        PlayPedAmbientSpeechNative(isPedLoaded[v.npcID].npc, 'GENERIC_BYE', 'SPEECH_PARAMS_FORCE_NO_REPEAT_FRONTEND')
                                        isPedLoaded[v.npcID].hasSpeak = false
                                    end
                                end
							end
						end

						if distance <= 2.5 and not Config.Locksmith.targetSystem.enable then
							sleep = 1
							currentMechanic = mechanic

							if not IsPedInAnyVehicle(MSK.Player.ped) and not getIsDead() then
								if not shown then
									if Config.Locksmith.defaultTextUI then
										MSK.HelpNotification(Translation[Config.Locale]['menu_open_locksmith']:format(mechanic.label))
									elseif not Config.Locksmith.defaultTextUI then
										Config.openTextUI(Translation[Config.Locale]['menu_open_locksmith']:format(mechanic.label), Translation[Config.Locale]['menu_open_locksmith_textui']:format(mechanic.label))
										shown = true
									end
								end

								if IsControlJustReleased(0, 38) then
									shown = true
									openLocksmithMenu(mechanic.label)
								end
							end
						end
					end
				end

				if shown and not currentMechanic and not not Config.Locksmith.targetSystem.enable then
					if not Config.Locksmith.defaultTextUI then Config.closeTextUI() end
            		shown = false
				end

				-- Delete peds out of distance OR whose location was removed via the dashboard.
				for id, v in pairs(isPedLoaded) do
					if v.loaded and (not v.inDistance or not seen[id]) then
						deletePed(v)
						isPedLoaded[id] = nil
					end
				end
			end

			Wait(sleep)
		end
	end)
end

CreateThread(function()
	while true do
    local sleep = 100
		local vehicle = GetVehiclePedIsTryingToEnter(MSK.Player.ped)
		local plate = GetVehicleNumberPlateText(vehicle)
		local model = GetEntityModel(vehicle)

			if DoesEntityExist(vehicle) then
				-- This is to lock npc vehicles
				if Config.Settings.lockVehiclesFromNPCs.enable then
					if not GetVehicleLockState(vehicle) and not Entity(vehicle).state.forceLock and not IsVehicleWhitelisted(plate, model) and not (MSK.Trigger('msk_vehiclekeys:isVehicleOwned', plate) or HasPlayerKeyOrIsVehicleOwner(vehicle)) and not IsVehiclePreviouslyOwnedByPlayer(vehicle) then
						local probability = Config.Settings.lockVehiclesFromNPCs.probability
						local percent = math.random(100)
						if percent > probability then
							SetVehicleLockState(vehicle, true)
							SetVehicleLockStatus(vehicle, 6)
							SetVehicleLockStatus(vehicle, 3)
						end
					end
				end

				-- This is only to prevent cheaters from opening the vehicle
				if GetVehicleLockState(vehicle) then
					SetVehicleLockState(vehicle, true)
				end
			end

			Wait(sleep)
    end
end)
