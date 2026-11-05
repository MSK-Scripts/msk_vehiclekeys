----------------------------------------------------------------
-- Supports ONLY ox_inventory and jaksam_inventory.
-- Wraps all exports[...] calls behind a unified interface:
--   Inventory.HasItem(playerId, identifier, plate)        -> boolean[, itemData]
--   Inventory.GiveItem(playerId, identifier, plate, typ[, slot])
--   Inventory.TakeItem(playerId, identifier, plate)
--   Inventory.UpdatePlateOnline(player, oldPlate, newPlate)
--   Inventory.UpdatePlateOffline(identifier, oldPlate, newPlate)
--   Inventory.GetItemCount(playerId, itemName)
--   Inventory.RegisterUsable(itemName, cb)
--   Inventory.AddKeyringItem(playerId)                    (optional)
--   Inventory.GetKeyringContainers(playerId)              (optional)
--   Inventory.IsKeyringContainer(playerId, stashId)       (optional)
--   Inventory.ConvertOldMethod(playerId, identifier)      (optional)
-- Hooks (handing keys over via drag&drop) are registered per system.
----------------------------------------------------------------

local INVENTORY = Config.Settings.key.inventory

Inventory = {}
Hooks = {}

-- Builds the item metadata for a vehicle key.
local function buildMetadata(plate, typ)
    local item = Config.Settings.key
    return {
        plate = plate,
        label = item.itemLabel,
        typ = typ,
        description = ('%s - %s'):format(item.plateLabel:format(tostring(plate)), Translation[Config.Locale][typ]),
    }
end

-- Replaces the plate inside the description string (e.g. "Plate: ABC - Primary").
local function patchDescriptionPlate(description, newPlate)
    if type(description) ~= 'string' then return description end
    return string.gsub(description, "^.- %-", newPlate .. " -")
end

----------------------------------------------------------------
-- ox_inventory
----------------------------------------------------------------

local Ox = {}

-- Adds the keyring item if the player does not already have it.
Ox.AddKeyringItem = function(playerId)
    if not Config.KeyRingSystem.enable then return end
    if not Config.KeyRingSystem.addItem then return end

    local itemCount = exports.ox_inventory:Search(playerId, 'count', Config.KeyRingSystem.item)
    if not itemCount or itemCount == 0 then
        exports.ox_inventory:AddItem(playerId, Config.KeyRingSystem.item, 1)
    end
end

-- Checks whether the given stash is one of the player's keyring containers.
Ox.IsKeyringContainer = function(playerId, stashId)
    if not Config.KeyRingSystem.enable then return false end

    local keyringItems = exports.ox_inventory:Search(playerId, 'slots', Config.KeyRingSystem.item)
    for _, v in pairs(keyringItems or {}) do
        if v.metadata and v.metadata.container and v.metadata.container == stashId then
            return exports.ox_inventory:GetContainerFromSlot(playerId, v.slot)
        end
    end

    return false
end

-- Returns all of the player's keyring containers.
Ox.GetKeyringContainers = function(playerId)
    local containers = {}
    if not Config.KeyRingSystem.enable then return containers end

    local keyringItems = exports.ox_inventory:Search(playerId, 'slots', Config.KeyRingSystem.item)
    for _, v in pairs(keyringItems or {}) do
        if v.metadata and v.metadata.container then
            containers[#containers + 1] = exports.ox_inventory:GetContainerFromSlot(playerId, v.slot)
        end
    end

    return containers
end

-- Migrates the old keyring structure (container without metadata.container) to the new one.
Ox.ConvertOldMethod = function(playerId, identifier)
    if not Config.KeyRingSystem.enable then return end
    Wait(1000) -- Wait until the player's inventory is loaded

    local keyringItems = exports.ox_inventory:Search(playerId, 'slots', Config.KeyRingSystem.item)
    local stashId = 'keyring_' .. identifier
    local selfConverted = false

    for _, v in pairs(keyringItems or {}) do
        if v.metadata and not v.metadata.container then
            if v.metadata.owner then
                stashId = 'keyring_' .. v.metadata.owner
            end

            exports.ox_inventory:RemoveItem(playerId, v.name, 1, nil, v.slot)

            if not selfConverted then
                local success, response = exports.ox_inventory:AddItem(playerId, v.name, 1, nil, v.slot)
                local containerId = nil

                if success and response then
                    local container = exports.ox_inventory:GetContainerFromSlot(playerId, response.slot)
                    containerId = container and container.id
                end

                local stashExists = exports.ox_inventory:GetInventory(stashId, false)
                if not stashExists then
                    exports.ox_inventory:RegisterStash(stashId, Config.KeyRingSystem.label, Config.KeyRingSystem.slots, Config.KeyRingSystem.weight)
                end

                local stash = exports.ox_inventory:GetInventoryItems(stashId)
                for _, data in pairs(stash or {}) do
                    if data.name == Config.Settings.key.itemName and data.metadata then
                        exports.ox_inventory:RemoveItem(stashId, data.name, 1, nil, data.slot)
                        MySQL.query('DELETE FROM ox_inventory WHERE name = ?', { stashId })

                        if containerId and data.metadata.typ ~= 'temporary' then
                            exports.ox_inventory:AddItem(containerId, data.name, 1, data.metadata)
                        else
                            exports.ox_inventory:AddItem(playerId, data.name, 1, data.metadata)
                        end
                    end
                end

                if stashId:find(identifier) or ('keyring_' .. identifier) == stashId then
                    selfConverted = true
                end
            end
        end
    end
end

-- Searches for a matching key inside the keyring. Returns true, {container, data}.
Ox.HasItemInKeyring = function(playerId, plate)
    if not Config.KeyRingSystem.enable then return false end
    local item = Config.Settings.key

    local keyringItems = exports.ox_inventory:Search(playerId, 'slots', Config.KeyRingSystem.item)
    if not keyringItems then return false end

    for _, data in pairs(keyringItems) do
        if data and data.metadata and data.metadata.container then
            local stashId = data.metadata.container
            local container = exports.ox_inventory:GetContainerFromSlot(playerId, data.slot)

            if container then
                local keyItems = exports.ox_inventory:GetInventoryItems(stashId)
                for _, v in pairs(keyItems or {}) do
                    if (not plate and v.name == item.itemName) or (plate and v.name == item.itemName and v.metadata and v.metadata.plate and plate == MSK.String.Trim(v.metadata.plate)) then
                        return true, { container = stashId, data = v }
                    end
                end
            end
        end
    end

    return false
end

Ox.HasItem = function(playerId, identifier, plate)
    local item = Config.Settings.key
    local items = exports.ox_inventory:GetInventoryItems(playerId)

    for _, v in pairs(items or {}) do
        if (not plate and v.name == item.itemName) or (plate and v.name == item.itemName and v.metadata and v.metadata.plate and plate == MSK.String.Trim(v.metadata.plate)) then
            return true, v
        end
    end

    return (Ox.HasItemInKeyring(playerId, plate)) and true or false
end

Ox.GiveItem = function(playerId, identifier, plate, typ, slot)
    exports.ox_inventory:AddItem(playerId, Config.Settings.key.itemName, 1, buildMetadata(plate, typ), slot)
end

Ox.TakeItem = function(playerId, identifier, plate)
    local item = Config.Settings.key
    local items = exports.ox_inventory:GetInventoryItems(playerId)

    for _, v in pairs(items or {}) do
        if v.name == item.itemName and v.metadata and v.metadata.plate and plate == MSK.String.Trim(v.metadata.plate) then
            exports.ox_inventory:RemoveItem(playerId, item.itemName, 1, false, v.slot)
        end
    end

    local inKeyring, keyringData = Ox.HasItemInKeyring(playerId, plate)
    if inKeyring then
        exports.ox_inventory:RemoveItem(keyringData.container, keyringData.data.name, 1, false, keyringData.data.slot)
    end
end

Ox.UpdatePlateOnline = function(player, oldPlate, newPlate)
    local item = Config.Settings.key

    -- Items directly in the player's inventory
    for _, v in pairs(player.GetInventory()) do
        if v.name == item.itemName and v.metadata and v.metadata.plate and oldPlate == MSK.String.Trim(v.metadata.plate) then
            v.metadata.plate = newPlate
            v.metadata.description = patchDescriptionPlate(v.metadata.description, newPlate)
            exports.ox_inventory:SetMetadata(player.source, v.slot, v.metadata)
        end
    end

    -- Items inside the keyring containers
    if Config.KeyRingSystem.enable then
        local containers = Ox.GetKeyringContainers(player.source)
        for i = 1, #containers do
            local container = containers[i]
            if container then
                for _, cItem in pairs(container.items) do
                    if cItem.metadata and oldPlate == MSK.String.Trim(cItem.metadata.plate) then
                        cItem.metadata.plate = newPlate
                        cItem.metadata.description = patchDescriptionPlate(cItem.metadata.description, newPlate)
                        exports.ox_inventory:SetMetadata(container.id, cItem.slot, cItem.metadata)
                    end
                end
            end
        end
    end
end

Ox.UpdatePlateOffline = function(identifier, oldPlate, newPlate)
    local item = Config.Settings.key
    local keyRing = Config.KeyRingSystem

    local result = MySQL.single.await(
        ('SELECT inventory FROM %s WHERE %s = @identifier LIMIT 1'):format(USER_TABLE_NAME, IDENTIFIER_COLUMN_NAME),
        { ['@identifier'] = identifier }
    )
    if not result or not result.inventory then return end

    local inv = json.decode(result.inventory)

    for k, v in pairs(inv) do
        if v.name == item.itemName and v.metadata and v.metadata.plate and oldPlate == MSK.String.Trim(v.metadata.plate) then
            v.metadata.plate = newPlate
            v.metadata.description = patchDescriptionPlate(v.metadata.description, newPlate)
            inv[k] = v
        end

        -- Keyring container (its own ox_inventory row)
        if keyRing.enable and v.name == keyRing.item and v.metadata and v.metadata.container then
            local container = MySQL.single.await('SELECT data FROM ox_inventory WHERE name = @container LIMIT 1', {
                ['@container'] = v.metadata.container,
            })

            if container and container.data then
                local data = json.decode(container.data)
                for ck, dItem in pairs(data) do
                    if dItem.name == item.itemName and dItem.metadata and dItem.metadata.plate and oldPlate == MSK.String.Trim(dItem.metadata.plate) then
                        dItem.metadata.plate = newPlate
                        dItem.metadata.description = patchDescriptionPlate(dItem.metadata.description, newPlate)
                        data[ck] = dItem
                    end
                end

                MySQL.update('UPDATE ox_inventory SET data = @data WHERE name = @container', {
                    ['@container'] = v.metadata.container,
                    ['@data'] = json.encode(data),
                })
            end
        end
    end

    MySQL.update(('UPDATE %s SET inventory = @inventory WHERE %s = @identifier'):format(USER_TABLE_NAME, IDENTIFIER_COLUMN_NAME), {
        ['@identifier'] = identifier,
        ['@inventory'] = json.encode(inv),
    })
end

-- Count of any item in the player's inventory (e.g. for the contract item).
Ox.GetItemCount = function(playerId, itemName)
    return exports.ox_inventory:Search(playerId, 'count', itemName) or 0
end

-- ox_inventory: the keys item is made usable via the client export in the ox items.lua
-- (client = { export = 'msk_vehiclekeys.toggleLock' }). No server-side registration.
Ox.RegisterUsable = function(itemName, cb) end

-- Hook for the keyring item: moves the contained keys along with the container.
Ox.RegisterHooks = function()
    Hooks.Keyring = exports.ox_inventory:registerHook('swapItems', function(payload)
        local playerId = payload.source
        local item = payload.fromSlot
        local fromType, toType = payload.fromType, payload.toType
        local toInventory, fromInventory = payload.toInventory, payload.fromInventory

        local container = exports.ox_inventory:GetContainerFromSlot(fromInventory, item.slot)
        if not container then return end
        local keyItems = container.items

        if fromType == 'player' and toType == 'player' and playerId ~= toInventory then
            for _, v in pairs(keyItems) do
                RemoveKey({ source = playerId }, { plate = v.metadata.plate, type = v.metadata.typ }, true)
                AddKey({ source = toInventory }, { plate = v.metadata.plate, type = v.metadata.typ }, true)
            end
        elseif fromType == 'player' and toType ~= 'player' then
            for _, v in pairs(keyItems) do
                RemoveKey({ source = playerId }, { plate = v.metadata.plate, type = v.metadata.typ }, true)
            end
        elseif fromType ~= 'player' and toType == 'player' then
            for _, v in pairs(keyItems) do
                AddKey({ source = playerId }, { plate = v.metadata.plate, type = v.metadata.typ }, true)
            end
        end
    end, {
        print = Config.Debug,
        itemFilter = { [Config.KeyRingSystem.item] = true },
    })

    -- Hook for the vehicle key item (handing over between players / drop)
    Hooks.Keys = exports.ox_inventory:registerHook('swapItems', function(payload)
        local playerId = payload.source
        local item = payload.fromSlot
        local metadata = item.metadata
        local fromType, toType = payload.fromType, payload.toType
        local toInventory, fromInventory = payload.toInventory, payload.fromInventory

        if not metadata or not metadata.plate or not metadata.typ then return end

        if metadata.typ == 'primary' then
            if fromType == 'player' and toType == 'player' and playerId ~= toInventory then
                if Config.GivePrimaryKey.giveSecondaryKey then
                    AddSecondaryKey({ source = toInventory }, { plate = metadata.plate })
                    Config.Notification(playerId, Translation[Config.Locale]['give_secondary_key']:format(metadata.plate), 'success')
                    return false
                elseif Config.GivePrimaryKey.givePrimaryKey then
                    if Config.GivePrimaryKey.transferOwnership then
                        TransferVehicle({ source = playerId }, { source = toInventory }, { plate = metadata.plate })
                    else
                        AddKey({ source = toInventory }, { plate = metadata.plate, type = metadata.typ }, true)
                        if Config.GivePrimaryKey.removePrimaryKey then
                            RemoveKey({ source = playerId }, { plate = metadata.plate, type = metadata.typ }, true)
                        end
                    end
                end
            elseif fromType == 'player' and toType ~= 'player' then
                if not Ox.IsKeyringContainer(playerId, toInventory) then
                    RemoveKey({ source = playerId }, { plate = metadata.plate, type = metadata.typ }, true)
                end
            elseif fromType ~= 'player' and toType == 'player' then
                if not Ox.IsKeyringContainer(playerId, fromInventory) then
                    AddKey({ source = playerId }, { plate = metadata.plate, type = metadata.typ }, true)
                end
            end
        elseif metadata.typ == 'secondary' then
            if fromType == 'player' and toType == 'player' and playerId ~= toInventory then
                RemoveKey({ source = playerId }, { plate = metadata.plate, type = metadata.typ }, true)
                AddKey({ source = toInventory }, { plate = metadata.plate, type = metadata.typ }, true)
                Config.Notification(playerId, Translation[Config.Locale]['give_key']:format(Translation[Config.Locale]['secondary'], metadata.plate), 'success')
            elseif fromType == 'player' and toType ~= 'player' then
                if not Ox.IsKeyringContainer(playerId, toInventory) then
                    RemoveKey({ source = playerId }, { plate = metadata.plate, type = metadata.typ }, true)
                end
            elseif fromType ~= 'player' and toType == 'player' then
                if not Ox.IsKeyringContainer(playerId, fromInventory) then
                    AddKey({ source = playerId }, { plate = metadata.plate, type = metadata.typ }, true)
                end
            end
        elseif metadata.typ == 'temporary' then
            if fromType == 'player' and toType == 'player' and playerId ~= toInventory then
                RemoveKey({ source = playerId }, { plate = metadata.plate, type = metadata.typ }, true)
                AddKey({ source = toInventory }, { plate = metadata.plate, type = metadata.typ }, true)
                Config.Notification(playerId, Translation[Config.Locale]['give_key']:format(Translation[Config.Locale]['temporary'], metadata.plate), 'success')
            elseif fromType == 'player' and toType ~= 'player' then
                if not Ox.IsKeyringContainer(playerId, toInventory) then
                    RemoveKey({ source = playerId }, { plate = metadata.plate, type = metadata.typ }, true)

                    local inv = toInventory == 'newdrop' and payload.dropId or toInventory

                    CreateThread(function()
                        local data = exports.ox_inventory:Search(inv, 'slots', Config.Settings.key.itemName, metadata)
                        while not data do
                            Wait(100)
                            data = exports.ox_inventory:Search(inv, 'slots', Config.Settings.key.itemName, metadata)
                        end

                        local success = exports.ox_inventory:RemoveItem(inv, Config.Settings.key.itemName, 1, metadata, data.slot)
                        while not success do
                            Wait(100)
                            success = exports.ox_inventory:RemoveItem(inv, Config.Settings.key.itemName, 1, metadata, data.slot)
                        end
                    end)
                end
            end
        end
    end, {
        print = Config.Debug,
        itemFilter = { [Config.Settings.key.itemName] = true },
    })
end

----------------------------------------------------------------
-- jaksam_inventory (native exports + onItemTransferred hook)
----------------------------------------------------------------

local Jaksam = {}

-- Iterates over a jaksam inventory (items keyed by "SLOT-x") and calls cb(item, slotNumber).
local function jaksamForEach(items, cb)
    for slotKey, v in pairs(items or {}) do
        local slot = v.slot or tonumber((tostring(slotKey):gsub("SLOT%-", ""))) or slotKey
        cb(v, slot)
    end
end

Jaksam.AddKeyringItem = function(playerId)
    if not Config.KeyRingSystem.enable then return end
    if not Config.KeyRingSystem.addItem then return end

    local existing = exports['jaksam_inventory']:getItemByName(playerId, Config.KeyRingSystem.item)
    if not existing then
        exports['jaksam_inventory']:addItem(playerId, Config.KeyRingSystem.item, 1)
    end
end

-- jaksam: keyring containers are referenced via metadata.inventoryId.
Jaksam.GetKeyringContainers = function(playerId)
    local containers = {}
    if not Config.KeyRingSystem.enable then return containers end

    local items = exports['jaksam_inventory']:getInventory(playerId)
    jaksamForEach(items.items or items, function(v)
        if v.name == Config.KeyRingSystem.item and v.metadata and v.metadata.inventoryId then
            containers[#containers + 1] = { id = v.metadata.inventoryId }
        end
    end)

    return containers
end

Jaksam.IsKeyringContainer = function(playerId, stashId)
    local containers = Jaksam.GetKeyringContainers(playerId)
    for i = 1, #containers do
        if containers[i].id == stashId then return containers[i] end
    end
    return false
end

-- jaksam does not use the old ox keyring structure -> nothing to convert.
Jaksam.ConvertOldMethod = nil

Jaksam.HasItemInKeyring = function(playerId, plate)
    if not Config.KeyRingSystem.enable then return false end
    local item = Config.Settings.key

    local inv = exports['jaksam_inventory']:getInventory(playerId)
    local found = false
    local result = false

    jaksamForEach(inv.items or inv, function(v)
        if found then return end
        if v.name == Config.KeyRingSystem.item and v.metadata and v.metadata.inventoryId then
            local stashId = v.metadata.inventoryId
            local keyItems = exports['jaksam_inventory']:getInventory(stashId)

            jaksamForEach(keyItems.items or keyItems, function(kv, kslot)
                if found then return end
                if (not plate and kv.name == item.itemName) or (plate and kv.name == item.itemName and kv.metadata and kv.metadata.plate and plate == MSK.String.Trim(kv.metadata.plate)) then
                    found = true
                    result = { container = stashId, slot = kslot, data = kv }
                end
            end)
        end
    end)

    if found then return true, result end
    return false
end

Jaksam.HasItem = function(playerId, identifier, plate)
    local item = Config.Settings.key
    local inv = exports['jaksam_inventory']:getInventory(playerId)
    local found = false

    jaksamForEach(inv.items or inv, function(v)
        if found then return end
        if (not plate and v.name == item.itemName) or (plate and v.name == item.itemName and v.metadata and v.metadata.plate and plate == MSK.String.Trim(v.metadata.plate)) then
            found = true
        end
    end)

    if found then return true end
    return (Jaksam.HasItemInKeyring(playerId, plate)) and true or false
end

Jaksam.GiveItem = function(playerId, identifier, plate, typ, slot)
    exports['jaksam_inventory']:addItem(playerId, Config.Settings.key.itemName, 1, buildMetadata(plate, typ), slot)
end

Jaksam.TakeItem = function(playerId, identifier, plate)
    local item = Config.Settings.key
    local inv = exports['jaksam_inventory']:getInventory(playerId)

    jaksamForEach(inv.items or inv, function(v, slot)
        if v.name == item.itemName and v.metadata and v.metadata.plate and plate == MSK.String.Trim(v.metadata.plate) then
            exports['jaksam_inventory']:removeItem(playerId, item.itemName, 1, v.metadata, slot)
        end
    end)

    local inKeyring, keyringData = Jaksam.HasItemInKeyring(playerId, plate)
    if inKeyring then
        exports['jaksam_inventory']:removeItem(keyringData.container, item.itemName, 1, keyringData.data.metadata, keyringData.slot)
    end
end

Jaksam.UpdatePlateOnline = function(player, oldPlate, newPlate)
    local item = Config.Settings.key
    local inv = player.GetInventory()

    -- Player inventory
    jaksamForEach(inv.items or inv, function(v, slot)
        if v.name == item.itemName and v.metadata and v.metadata.plate and oldPlate == MSK.String.Trim(v.metadata.plate) then
            v.metadata.plate = newPlate
            v.metadata.description = patchDescriptionPlate(v.metadata.description, newPlate)
            exports['jaksam_inventory']:setItemMetadataInSlot(player.source, slot, v.metadata)
        end
    end)

    -- Keyring containers
    if Config.KeyRingSystem.enable then
        jaksamForEach(inv.items or inv, function(v)
            if v.name == Config.KeyRingSystem.item and v.metadata and v.metadata.inventoryId then
                local items = exports['jaksam_inventory']:getInventory(v.metadata.inventoryId)
                jaksamForEach(items.items or items, function(cItem, cslot)
                    if cItem.metadata and oldPlate == MSK.String.Trim(cItem.metadata.plate) then
                        cItem.metadata.plate = newPlate
                        cItem.metadata.description = patchDescriptionPlate(cItem.metadata.description, newPlate)
                        exports['jaksam_inventory']:setItemMetadataInSlot(v.metadata.inventoryId, cslot, cItem.metadata)
                    end
                end)
            end
        end)
    end
end

Jaksam.UpdatePlateOffline = function(identifier, oldPlate, newPlate)
    local item = Config.Settings.key
    local keyRing = Config.KeyRingSystem

    -- jaksam stores inventories in the jaksam_inventory table (column items, id = identifier)
    local result = MySQL.single.await('SELECT items FROM jaksam_inventory WHERE id = @identifier LIMIT 1', {
        ['@identifier'] = identifier,
    })
    if not result or not result.items then return end

    local inv = json.decode(result.items)

    for k, v in pairs(inv) do
        if v.name == item.itemName and v.metadata and v.metadata.plate and oldPlate == MSK.String.Trim(v.metadata.plate) then
            v.metadata.plate = newPlate
            v.metadata.description = patchDescriptionPlate(v.metadata.description, newPlate)
            inv[k] = v
        end

        if keyRing.enable and v.name == keyRing.item and v.metadata and v.metadata.inventoryId then
            local container = MySQL.single.await('SELECT items FROM jaksam_inventory WHERE id = @container LIMIT 1', {
                ['@container'] = v.metadata.inventoryId,
            })

            if container and container.items then
                local data = json.decode(container.items)
                for ck, dItem in pairs(data) do
                    if dItem.name == item.itemName and dItem.metadata and dItem.metadata.plate and oldPlate == MSK.String.Trim(dItem.metadata.plate) then
                        dItem.metadata.plate = newPlate
                        dItem.metadata.description = patchDescriptionPlate(dItem.metadata.description, newPlate)
                        data[ck] = dItem
                    end
                end

                MySQL.update('UPDATE jaksam_inventory SET items = @items WHERE id = @container', {
                    ['@container'] = v.metadata.inventoryId,
                    ['@items'] = json.encode(data),
                })
            end
        end
    end

    MySQL.update('UPDATE jaksam_inventory SET items = @items WHERE id = @identifier', {
        ['@identifier'] = identifier,
        ['@items'] = json.encode(inv),
    })
end

-- Count of any item in the player's inventory (e.g. for the contract item).
Jaksam.GetItemCount = function(playerId, itemName)
    local item = exports['jaksam_inventory']:getItemByName(playerId, itemName)
    return item and item.amount or 0
end

-- jaksam: register the keys item as usable server-side.
-- Callback params (ESX): (playerId, itemName, inventoryItem) / (QBCore): (playerId, item)
Jaksam.RegisterUsable = function(itemName, cb)
    exports['jaksam_inventory']:registerUsableItem(itemName, function(playerId)
        cb(playerId)
    end)
end

-- jaksam transfer hook: uses 'onItemTransferred'.
-- Payload: playerId, inventoryIdFrom, inventoryIdTo, slotIdFrom, slotIdTo, itemName, amount, metadata. Player inventories are strings "player:<id>".
Jaksam.RegisterHooks = function()
    -- Extracts the numeric server id from a player inventory id ("player:1" -> 1).
    local function playerSource(invId)
        local id = tostring(invId):match('^player:(%d+)$')
        return id and tonumber(id) or nil
    end

    Hooks.Keys = exports['jaksam_inventory']:registerHook('onItemTransferred', function(payload)
        local itemName = payload.itemName
        local metadata = payload.metadata
        local fromInv, toInv = payload.inventoryIdFrom, payload.inventoryIdTo
        local fromSource = playerSource(fromInv)
        local toSource = playerSource(toInv)

        -- The whole keyring container was moved -> carry the contained keys along
        if itemName == Config.KeyRingSystem.item then
            if not Config.KeyRingSystem.enable then return end
            if not metadata or not metadata.inventoryId then return end

            local container = exports['jaksam_inventory']:getInventory(metadata.inventoryId)
            jaksamForEach(container and (container.items or container) or {}, function(v)
                if v.name == Config.Settings.key.itemName and v.metadata and v.metadata.plate then
                    if fromSource and toSource and fromSource ~= toSource then
                        RemoveKey({ source = fromSource }, { plate = v.metadata.plate, type = v.metadata.typ }, true)
                        AddKey({ source = toSource }, { plate = v.metadata.plate, type = v.metadata.typ }, true)
                    elseif fromSource and not toSource then
                        RemoveKey({ source = fromSource }, { plate = v.metadata.plate, type = v.metadata.typ }, true)
                    elseif not fromSource and toSource then
                        AddKey({ source = toSource }, { plate = v.metadata.plate, type = v.metadata.typ }, true)
                    end
                end
            end)
            return
        end

        -- A single vehicle key item was moved
        if itemName ~= Config.Settings.key.itemName then return end
        if not metadata or not metadata.plate or not metadata.typ then return end

        if metadata.typ == 'primary' then
            if fromSource and toSource and fromSource ~= toSource then
                if Config.GivePrimaryKey.giveSecondaryKey then
                    AddSecondaryKey({ source = toSource }, { plate = metadata.plate })
                    Config.Notification(fromSource, Translation[Config.Locale]['give_secondary_key']:format(metadata.plate), 'success')
                elseif Config.GivePrimaryKey.givePrimaryKey then
                    if Config.GivePrimaryKey.transferOwnership then
                        TransferVehicle({ source = fromSource }, { source = toSource }, { plate = metadata.plate })
                    else
                        AddKey({ source = toSource }, { plate = metadata.plate, type = metadata.typ }, true)
                        if Config.GivePrimaryKey.removePrimaryKey then
                            RemoveKey({ source = fromSource }, { plate = metadata.plate, type = metadata.typ }, true)
                        end
                    end
                end
            elseif fromSource and not toSource then
                if not Jaksam.IsKeyringContainer(fromSource, toInv) then
                    RemoveKey({ source = fromSource }, { plate = metadata.plate, type = metadata.typ }, true)
                end
            elseif not fromSource and toSource then
                if not Jaksam.IsKeyringContainer(toSource, fromInv) then
                    AddKey({ source = toSource }, { plate = metadata.plate, type = metadata.typ }, true)
                end
            end
        elseif metadata.typ == 'secondary' or metadata.typ == 'temporary' then
            if fromSource and toSource and fromSource ~= toSource then
                RemoveKey({ source = fromSource }, { plate = metadata.plate, type = metadata.typ }, true)
                AddKey({ source = toSource }, { plate = metadata.plate, type = metadata.typ }, true)
                Config.Notification(fromSource, Translation[Config.Locale]['give_key']:format(Translation[Config.Locale][metadata.typ], metadata.plate), 'success')
            elseif fromSource and not toSource then
                if not Jaksam.IsKeyringContainer(fromSource, toInv) then
                    RemoveKey({ source = fromSource }, { plate = metadata.plate, type = metadata.typ }, true)
                end
            elseif not fromSource and toSource then
                if not Jaksam.IsKeyringContainer(toSource, fromInv) then
                    AddKey({ source = toSource }, { plate = metadata.plate, type = metadata.typ }, true)
                end
            end
        end
    end, {
        itemFilter = { [Config.Settings.key.itemName] = true, [Config.KeyRingSystem.item] = true },
    })
end

----------------------------------------------------------------
-- Selection & initialization
----------------------------------------------------------------

if INVENTORY == 'ox_inventory' then
    Inventory = Ox
elseif INVENTORY == 'jaksam_inventory' then
    Inventory = Jaksam
else
    error(('msk_vehiclekeys: unsupported inventory "%s". Allowed: ox_inventory, jaksam_inventory'):format(tostring(INVENTORY)))
end

CreateThread(function()
    Wait(500) -- short wait until the inventory resource is ready
    if Inventory.RegisterHooks then Inventory.RegisterHooks() end
end)
