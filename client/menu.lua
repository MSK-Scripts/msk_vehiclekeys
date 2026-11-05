registerTarget = function(label, modelHash, coords)
    if not Config.Locksmith.targetSystem.enable then return end

    if Config.Locksmith.targetSystem.script == 'ox_target' then
        exports.ox_target:addLocalEntity(modelHash, {
            label = label,
            distance = 2.5,
            onSelect = function(data)
                openLocksmithMenu()
            end
        })
    else
        -- Add your own target system
    end
end

unregisterTarget = function(modelHash, coords)
    if Config.Locksmith.targetSystem.script == 'ox_target' then
        exports.ox_target:removeLocalEntity(modelHash, false)
    else
        -- Add your own target system
    end
end

openLocksmithMenu = function()
    local vehicles = GetPlayerVehicles()
    local options = {}

    if Config.Locksmith.menu == 'msk_context' then
        for i = 1, #vehicles do
            if IsModelValid(vehicles[i].model) then
                local label = MSK.GetVehicleLabelFromModel(vehicles[i].model)
                local veh = {label = label, plate = vehicles[i].plate, model = vehicles[i].model}

                options[#options + 1] = {
                    title = ('%s - %s'):format(label, veh.plate),
                    icon = 'car',
                    description = Translation[Config.Locale]['menu_locksmith_exchangelocks'],
                    onSelect = function()
                        ExchangeVehicleLocks(veh)
                    end
                }
            end
        end

        MSK.Context.Register('msk_vehiclekeys:LocksmithMenu', {
            title = Translation[Config.Locale]['menu_locksmith_title'],
            position = 'top-left',
            options = options,
        })

        MSK.Context.Show('msk_vehiclekeys:LocksmithMenu')
    elseif Config.Locksmith.menu == 'msk_menu' then
        for i = 1, #vehicles do
            if IsModelValid(vehicles[i].model) then
                local label = MSK.GetVehicleLabelFromModel(vehicles[i].model)
                local veh = {label = label, plate = vehicles[i].plate, model = vehicles[i].model}

                options[#options + 1] = {
                    label = ('%s - %s'):format(label, veh.plate),
                    icon = 'car',
                    description = Translation[Config.Locale]['menu_locksmith_exchangelocks'],
                    onSelect = function()
                        ExchangeVehicleLocks(veh)
                    end
                }
            end
        end

        MSK.Menu.Show({
            id = 'msk_vehiclekeys:LocksmithMenu',
            title = Translation[Config.Locale]['menu_locksmith_title'],
            position = 'top-left',
            items = options,
        })
    elseif Config.Locksmith.menu == 'ox_context' then
        for i = 1, #vehicles do
            if IsModelValid(vehicles[i].model) then
                local label = MSK.GetVehicleLabelFromModel(vehicles[i].model)

                options[#options + 1] = {
                    title = ('%s - %s'):format(label, vehicles[i].plate), 
                    icon = 'car', 
                    description = Translation[Config.Locale]['menu_locksmith_exchangelocks'],
                    onSelect = function()
                        ExchangeVehicleLocks({label = label, plate = vehicles[i].plate, model = vehicles[i].model})
                    end
                }
            end
        end

        lib.registerContext({
            id = 'msk_vehiclekeys:LocksmithMenu',
            title = Translation[Config.Locale]['menu_locksmith_title'],
            options = options,
        })

        lib.showContext('msk_vehiclekeys:LocksmithMenu')
    elseif Config.Locksmith.menu == 'ox_menu' then
        for i = 1, #vehicles do
            if IsModelValid(vehicles[i].model) then
                local label = MSK.GetVehicleLabelFromModel(vehicles[i].model)

                options[#options + 1] = {
                    label = ('%s - %s'):format(label, vehicles[i].plate), 
                    icon = 'car', 
                    description = Translation[Config.Locale]['menu_locksmith_exchangelocks'],
                    args = {label = label, plate = vehicles[i].plate, model = vehicles[i].model},
                    close = true
                }
            end
        end

        lib.registerMenu({
            id = 'msk_vehiclekeys:LocksmithMenu',
            title = Translation[Config.Locale]['menu_locksmith_title'],
            position = 'top-left',
            options = options,
        }, function(selected, scrollIndex, args)
            ExchangeVehicleLocks({label = args.label, plate = args.plate, model = args.model})
        end)

        lib.showMenu('msk_vehiclekeys:LocksmithMenu')
    elseif Config.Locksmith.menu == 'nui' then
        local list = {}

        for i = 1, #vehicles do
            if IsModelValid(vehicles[i].model) then
                list[#list + 1] = {
                    label = MSK.GetVehicleLabelFromModel(vehicles[i].model),
                    plate = vehicles[i].plate,
                    model = vehicles[i].model,
                }
            end
        end

        OpenLocksmithNui(list)
    else
        -- Add your own Menu
    end
end
exports('openLocksmithMenu', openLocksmithMenu)

-- Shared key actions. Extracted so the ox_context/ox_menu menus AND the custom
-- NUI (client/nui.lua) trigger the exact same behaviour. `veh` = {label, plate, model}.
-- Each returns true on success, false otherwise.
GiveSecondaryKeyAction = function(veh)
    local player, distance = MSK.GetClosestPlayer()

    if player ~= -1 and distance <= 2.0 then
        AddSecondaryKey({label = veh.label, plate = veh.plate, model = veh.model}, GetPlayerServerId(player))
        Config.Notification(nil, Translation[Config.Locale]['give_secondary_key']:format(veh.plate), 'success')
        return true
    else
        Config.Notification(nil, Translation[Config.Locale]['no_player_nearby'], 'error')
        return false
    end
end

ExchangeLocksAction = function(veh)
    ExchangeVehicleLocks({label = veh.label, plate = veh.plate, model = veh.model})
    return true
end

TransferVehicleAction = function(veh)
    local player, distance = MSK.GetClosestPlayer()

    if player ~= -1 and distance <= 2.0 then
        if Config.Settings.transfer.needItem then
            local hasItem = MSK.Trigger('msk_vehiclekeys:hasCorrectItem', MSK.Player.serverId, Config.Settings.transfer.itemName)

            if not hasItem then
                Config.Notification(nil, Translation[Config.Locale]['no_item_found'], 'error')
                return false
            end
        end

        TransferVehicle(GetPlayerServerId(player), {label = veh.label, plate = veh.plate, model = veh.model}, true)
        return true
    else
        Config.Notification(nil, Translation[Config.Locale]['no_player_nearby'], 'error')
        return false
    end
end

-- Action list for a primary key, shared by the msk_context and msk_menu variants.
-- Each entry: { label = <string>, fn = <action from above> }
local function buildKeyActions()
    local actions = {
        {label = Translation[Config.Locale]['menu_give_secondary_keys'], fn = GiveSecondaryKeyAction},
    }

    if Config.Settings.menu.showExchangeLocks then
        actions[#actions + 1] = {label = Translation[Config.Locale]['menu_exchange_locks'], fn = ExchangeLocksAction}
    end

    if Config.Settings.transferVehicle and Config.Settings.menu.showTransferVehicle then
        actions[#actions + 1] = {label = Translation[Config.Locale]['menu_transfer_vehicle'], fn = TransferVehicleAction}
    end

    return actions
end

RegisterNetEvent('msk_vehiclekeys:KeysActionsMenu', function(args)
    local keyOptions = {}

    keyOptions[#keyOptions + 1] = {
        title = Translation[Config.Locale]['menu_give_secondary_keys'],
        icon = 'key',
        onSelect = function()
            GiveSecondaryKeyAction(args)
        end
    }

    if Config.Settings.menu.showExchangeLocks then
        keyOptions[#keyOptions + 1] = {
            title = Translation[Config.Locale]['menu_exchange_locks'],
            icon = 'key',
            onSelect = function()
                ExchangeLocksAction(args)
            end
        }
    end

    if Config.Settings.transferVehicle and Config.Settings.menu.showTransferVehicle then
        keyOptions[#keyOptions + 1] = {
            title = Translation[Config.Locale]['menu_transfer_vehicle'],
            icon = 'key',
            onSelect = function()
                TransferVehicleAction(args)
            end
        }
    end

    lib.registerContext({
        id = 'msk_vehiclekeys:KeysActionsMenu',
        title = Translation[Config.Locale]['menu_vehicle_keys'],
        menu = 'msk_vehiclekeys:KeysPrimaryMenu',
        options = keyOptions,
    })

    lib.showContext('msk_vehiclekeys:KeysActionsMenu')
end)

openKeysMenu = function()
    logging('debug', 'openKeysMenu')
    if Config.Settings.menu.refreshPlayerKeys then
        local result = RefreshPlayerKeys(true)
    end
    local mainOptions = {}

    if Config.Settings.menu.keysMenu == 'msk_context' then
        local keys = GetPlayerKeys()

        -- Sub-context with the actions for one primary key. `menu` points back to
        -- the primary list, so the NUI shows a back arrow.
        local function actionsContext(veh)
            local options = {}

            for _, action in ipairs(buildKeyActions()) do
                options[#options + 1] = {
                    title = action.label,
                    icon = 'key',
                    onSelect = function()
                        action.fn(veh)
                    end
                }
            end

            return {
                id = 'msk_vehiclekeys:KeysActionsMenu',
                title = Translation[Config.Locale]['menu_vehicle_keys'],
                menu = 'msk_vehiclekeys:KeysPrimaryMenu',
                options = options,
            }
        end

        -- Builds a read-only or drilldown list for one key type.
        local function keyList(typ)
            local options = {}

            for i = 1, #keys do
                if keys[i].type == typ and IsModelValid(keys[i].model) then
                    local label = MSK.GetVehicleLabelFromModel(keys[i].model)
                    local veh = {label = label, plate = keys[i].plate, model = keys[i].model, type = typ}

                    if typ == 'primary' then
                        options[#options + 1] = {
                            title = ('%s - %s'):format(label, veh.plate),
                            icon = 'car',
                            arrow = true,
                            menu = actionsContext(veh),
                        }
                    else
                        options[#options + 1] = {
                            title = ('%s - %s'):format(label, veh.plate),
                            icon = 'car',
                            readOnly = true,
                        }
                    end
                end
            end

            if #options == 0 then
                options[1] = {title = Translation[Config.Locale]['menu_no_keys_available'], readOnly = true}
            end

            return options
        end

        MSK.Context.Register('msk_vehiclekeys:KeysPrimaryMenu', {
            title = Translation[Config.Locale]['menu_vehicle_keys'],
            menu = 'msk_vehiclekeys:KeysMenu',
            options = keyList('primary'),
        })

        mainOptions[#mainOptions + 1] = {
            title = Translation[Config.Locale]['menu_primary_keys'],
            icon = 'key',
            arrow = true,
            menu = 'msk_vehiclekeys:KeysPrimaryMenu'
        }

        if Config.Settings.menu.showSecondaryKeys then
            MSK.Context.Register('msk_vehiclekeys:KeysSecondaryMenu', {
                title = Translation[Config.Locale]['menu_vehicle_keys'],
                menu = 'msk_vehiclekeys:KeysMenu',
                options = keyList('secondary'),
            })

            mainOptions[#mainOptions + 1] = {
                title = Translation[Config.Locale]['menu_secondary_keys'],
                icon = 'key',
                arrow = true,
                menu = 'msk_vehiclekeys:KeysSecondaryMenu'
            }
        end

        if Config.Settings.menu.showTempKeys then
            MSK.Context.Register('msk_vehiclekeys:KeysTempMenu', {
                title = Translation[Config.Locale]['menu_vehicle_keys'],
                menu = 'msk_vehiclekeys:KeysMenu',
                options = keyList('temporary'),
            })

            mainOptions[#mainOptions + 1] = {
                title = Translation[Config.Locale]['menu_temporary_keys'],
                icon = 'key',
                arrow = true,
                menu = 'msk_vehiclekeys:KeysTempMenu'
            }
        end

        MSK.Context.Register('msk_vehiclekeys:KeysMenu', {
            title = Translation[Config.Locale]['menu_vehicle_keys'],
            position = 'top-right',
            options = mainOptions,
        })

        MSK.Context.Show('msk_vehiclekeys:KeysMenu')
    elseif Config.Settings.menu.keysMenu == 'msk_menu' then
        -- Opens the key list for one type. Primary keys carry the actions as
        -- side-scroll values (left/right), everything else is a plain list.
        local function showTypeMenu(typ)
            local keys = GetPlayerKeys()
            local actions = typ == 'primary' and buildKeyActions() or nil
            local scrollIndex = {} -- item index -> selected value index
            local items = {}

            for i = 1, #keys do
                if keys[i].type == typ and IsModelValid(keys[i].model) then
                    local label = MSK.GetVehicleLabelFromModel(keys[i].model)
                    local values

                    if actions then
                        values = {}
                        for ai = 1, #actions do values[ai] = actions[ai].label end
                    end

                    items[#items + 1] = {
                        label = ('%s - %s'):format(label, keys[i].plate),
                        icon = 'car',
                        values = values,
                        args = {
                            index = #items + 1,
                            label = label,
                            plate = keys[i].plate,
                            model = keys[i].model,
                            type = typ,
                        },
                        close = actions ~= nil,
                        onSelect = actions and function(args)
                            local action = actions[scrollIndex[args.index] or 1]
                            if action then action.fn(args) end
                        end or nil,
                    }
                end
            end

            if #items == 0 then
                items[1] = {label = Translation[Config.Locale]['menu_no_keys_available'], disabled = true}
            end

            local title = Translation[Config.Locale]['menu_primary_keys']
            if typ == 'secondary' then title = Translation[Config.Locale]['menu_secondary_keys']
            elseif typ == 'temporary' then title = Translation[Config.Locale]['menu_temporary_keys'] end

            MSK.Menu.Show({
                id = 'msk_vehiclekeys:KeysMenuSpecific',
                title = title,
                position = 'top-right',
                items = items,
                onSideScroll = function(index, valueIndex)
                    scrollIndex[index] = valueIndex
                end,
            })
        end

        -- close = false: the sub menu is opened inside onSelect, closing afterwards
        -- would immediately hide it again.
        mainOptions[#mainOptions + 1] = {
            label = Translation[Config.Locale]['menu_primary_keys'],
            icon = 'key',
            close = false,
            onSelect = function() showTypeMenu('primary') end,
        }

        if Config.Settings.menu.showSecondaryKeys then
            mainOptions[#mainOptions + 1] = {
                label = Translation[Config.Locale]['menu_secondary_keys'],
                icon = 'key',
                close = false,
                onSelect = function() showTypeMenu('secondary') end,
            }
        end

        if Config.Settings.menu.showTempKeys then
            mainOptions[#mainOptions + 1] = {
                label = Translation[Config.Locale]['menu_temporary_keys'],
                icon = 'key',
                close = false,
                onSelect = function() showTypeMenu('temporary') end,
            }
        end

        MSK.Menu.Show({
            id = 'msk_vehiclekeys:KeysMenu',
            title = Translation[Config.Locale]['menu_vehicle_keys'],
            position = 'top-right',
            items = mainOptions,
        })
    elseif Config.Settings.menu.keysMenu == 'ox_context' then
        local keys = GetPlayerKeys()
        local options = {}

        for i=1, #keys do
            local typ = keys[i].type

            if typ == 'primary' then
                local plate = keys[i].plate
                local model = keys[i].model
                if IsModelValid(model) then
                    local label = MSK.GetVehicleLabelFromModel(model)

                    options[#options + 1] = {
                        title = ('%s - %s'):format(label, plate), 
                        icon = 'car',
                        arrow = true,
                        args = {label = label, plate = plate, type = typ, model = model},
                        event = 'msk_vehiclekeys:KeysActionsMenu'
                    }
                end
            end
        end

        lib.registerContext({
            id = 'msk_vehiclekeys:KeysPrimaryMenu',
            title = Translation[Config.Locale]['menu_vehicle_keys'],
            menu = 'msk_vehiclekeys:KeysMenu',
            options = #options > 0 and options or {{title = Translation[Config.Locale]['menu_no_keys_available'], readOnly = true}},
        })

        mainOptions[#mainOptions + 1] = {
            title = Translation[Config.Locale]['menu_primary_keys'], 
            icon = 'key', 
            arrow = true,
            menu = 'msk_vehiclekeys:KeysPrimaryMenu'
        }

        if Config.Settings.menu.showSecondaryKeys then
            local options = {}

            for i=1, #keys do
                local typ = keys[i].type

                if typ == 'secondary' then
                    local plate = keys[i].plate
                    local model = keys[i].model
                    if IsModelValid(model) then
                        local label = MSK.GetVehicleLabelFromModel(model)

                        options[#options + 1] = {
                            title = ('%s - %s'):format(label, plate), 
                            icon = 'car', 
                            readOnly = true
                        }
                    end
                end
            end

            lib.registerContext({
                id = 'msk_vehiclekeys:KeysSecondaryMenu',
                title = Translation[Config.Locale]['menu_vehicle_keys'],
                menu = 'msk_vehiclekeys:KeysMenu',
                options = #options > 0 and options or {{title = Translation[Config.Locale]['menu_no_keys_available'], readOnly = true}},
            })

            mainOptions[#mainOptions + 1] = {
                title = Translation[Config.Locale]['menu_secondary_keys'], 
                icon = 'key', 
                arrow = true,
                menu = 'msk_vehiclekeys:KeysSecondaryMenu'
            }
        end

        if Config.Settings.menu.showTempKeys then
            local options = {}

            for i=1, #keys do
                local typ = keys[i].type

                if typ == 'temporary' then
                    local plate = keys[i].plate
                    local model = keys[i].model
                    if IsModelValid(model) then
                        local label = MSK.GetVehicleLabelFromModel(model)

                        options[#options + 1] = {
                            title = ('%s - %s'):format(label, plate), 
                            icon = 'car', 
                            readOnly = true
                        }
                    end
                end
            end

            lib.registerContext({
                id = 'msk_vehiclekeys:KeysTempMenu',
                title = Translation[Config.Locale]['menu_vehicle_keys'],
                menu = 'msk_vehiclekeys:KeysMenu',
                options = #options > 0 and options or {{title = Translation[Config.Locale]['menu_no_keys_available'], readOnly = true}},
            })

            mainOptions[#mainOptions + 1] = {
                title = Translation[Config.Locale]['menu_temporary_keys'], 
                icon = 'key', 
                arrow = true,
                menu = 'msk_vehiclekeys:KeysTempMenu'
            }
        end

        lib.registerContext({
            id = 'msk_vehiclekeys:KeysMenu',
            title = Translation[Config.Locale]['menu_vehicle_keys'],
            options = mainOptions,
        })

        lib.showContext('msk_vehiclekeys:KeysMenu')
    elseif Config.Settings.menu.keysMenu == 'ox_menu' then
        mainOptions[#mainOptions + 1] = {
            label = Translation[Config.Locale]['menu_primary_keys'], 
            icon = 'key', 
            args = {type = 'primary'},
        }

        if Config.Settings.menu.showSecondaryKeys then
            mainOptions[#mainOptions + 1] = {
                label = Translation[Config.Locale]['menu_secondary_keys'], 
                icon = 'key', 
                args = {type = 'secondary'},
            }
        end

        if Config.Settings.menu.showTempKeys then
            mainOptions[#mainOptions + 1] = {
                label = Translation[Config.Locale]['menu_temporary_keys'], 
                icon = 'key', 
                args = {type = 'temporary'},
            }
        end

        lib.registerMenu({
            id = 'msk_vehiclekeys:KeysMenu',
            title = Translation[Config.Locale]['menu_vehicle_keys'],
            position = 'top-left',
            options = mainOptions,
        }, function(selected, scrollIndex, args)
            local playerKeys = GetPlayerKeys()
            local options = {}

            for i=1, #playerKeys do
                local plate = playerKeys[i].plate
                local typ = playerKeys[i].type
                local model = playerKeys[i].model
                
                if args.type == typ and IsModelValid(model) then
                    local label = MSK.GetVehicleLabelFromModel(model)
                    local values = nil

                    if args.type == 'primary' then
                        values = {}
                        values[#values + 1] = Translation[Config.Locale]['menu_give_secondary_keys']

                        if Config.Settings.menu.showExchangeLocks then
                            values[#values + 1] = Translation[Config.Locale]['menu_exchange_locks']
                        end

                        if Config.Settings.transferVehicle and Config.Settings.menu.showTransferVehicle then
                            values[#values + 1] = Translation[Config.Locale]['menu_transfer_vehicle']
                        end
                    end

                    options[#options + 1] = {
                        label = ('%s - %s'):format(label, plate), 
                        icon = 'car', 
                        args = {label = label, plate = plate, type = typ, model = model},
                        values = values,
                    }
                end
            end

            local title = Translation[Config.Locale]['menu_primary_keys']
            if args.type == 'secondary' then title = Translation[Config.Locale]['menu_secondary_keys']
            elseif args.type == 'temporary' then title = Translation[Config.Locale]['menu_temporary_keys'] end

            lib.registerMenu({
                id = 'msk_vehiclekeys:KeysMenuSpecific',
                title = title,
                position = 'top-left',
                options = #options > 0 and options or {{label = Translation[Config.Locale]['menu_no_keys_available']}},
            }, function(selected, scrollIndex, args)
                if args.type ~= 'primary' then return end
                print(selected, scrollIndex, args)

                if scrollIndex == 1 then
                    local player, distance = MSK.GetClosestPlayer()

                    if player ~= -1 and distance <= 2.0 then
                        AddSecondaryKey({label = args.label, plate = args.plate, model = args.model}, GetPlayerServerId(player))
                        Config.Notification(nil, Translation[Config.Locale]['give_secondary_key']:format(args.plate), 'success')
                    else
                        Config.Notification(nil, Translation[Config.Locale]['no_player_nearby'], 'error')
                    end
                elseif scrollIndex == 2 then
                    if Config.Settings.menu.showExchangeLocks then
                        ExchangeVehicleLocks({label = args.label, plate = args.plate, model = args.model})
                    else
                        local player, distance = MSK.GetClosestPlayer()

                        if player ~= -1 and distance <= 2.0 then
                            if Config.Settings.transfer.needItem then
                                local hasItem = MSK.Trigger('msk_vehiclekeys:hasCorrectItem', MSK.Player.serverId, Config.Settings.transfer.itemName)

                                if not hasItem then 
                                    Config.Notification(nil, Translation[Config.Locale]['no_item_found'], 'error')
                                    return
                                end
                            end

                            TransferVehicle(GetPlayerServerId(player), {label = args.label, plate = args.plate, model = args.model}, true)
                        else
                            Config.Notification(nil, Translation[Config.Locale]['no_player_nearby'], 'error')
                        end
                    end
                elseif scrollIndex == 3 then
                    local player, distance = MSK.GetClosestPlayer()

                    if player ~= -1 and distance <= 2.0 then
                        if Config.Settings.transfer.needItem then
                            local hasItem = MSK.Trigger('msk_vehiclekeys:hasCorrectItem', MSK.Player.serverId, Config.Settings.transfer)

                            if not hasItem then 
                                Config.Notification(nil, Translation[Config.Locale]['no_item_found'], 'error')
                                return
                            end
                        end

                        TransferVehicle(GetPlayerServerId(player), {label = args.label, plate = args.plate, model = args.model}, true)
                    else
                        Config.Notification(nil, Translation[Config.Locale]['no_player_nearby'], 'error')
                    end
                end
            end)

            lib.showMenu('msk_vehiclekeys:KeysMenuSpecific')
        end)

        lib.showMenu('msk_vehiclekeys:KeysMenu')
    elseif Config.Settings.menu.keysMenu == 'nui' then
        local keys = GetPlayerKeys()
        local payload = { primary = {}, secondary = {}, temporary = {} }

        for i = 1, #keys do
            local typ = keys[i].type
            local model = keys[i].model

            if payload[typ] and IsModelValid(model) then
                payload[typ][#payload[typ] + 1] = {
                    label = MSK.GetVehicleLabelFromModel(model),
                    plate = keys[i].plate,
                    model = model,
                }
            end
        end

        OpenKeysNui(payload)
    else
        -- Add your own Menu
    end
end
exports('openKeysMenu', openKeysMenu)
