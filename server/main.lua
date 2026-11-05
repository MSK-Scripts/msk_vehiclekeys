-- Which tables hold vehicles and characters is a property of the framework, so
-- that is the one thing still worth asking msk_core about. Qbox uses the same
-- layout as QBCore, verified against qbx_core.sql and qbx_vehicles/vehicles.sql.
--
-- The framework detection that used to sit here is gone: msk_core has done it
-- already, and this copy knew nothing about Qbox.
local frameworkTables = {
    ESX = {
        vehicles = 'owned_vehicles',  owner = 'owner',
        users    = 'users',           identifier = 'identifier',
    },
    QBCore = {
        vehicles = 'player_vehicles', owner = 'citizenid',
        users    = 'players',         identifier = 'citizenid',
    },
    Qbox = {
        vehicles = 'player_vehicles', owner = 'citizenid',
        users    = 'players',         identifier = 'citizenid',
    },
}

local tables = frameworkTables[MSK.Bridge.Framework.Type]

VEHICLE_TABLE_NAME = tables and tables.vehicles or ''
OWNER_COLUMN_NAME = tables and tables.owner or ''
USER_TABLE_NAME = tables and tables.users or ''
IDENTIFIER_COLUMN_NAME = tables and tables.identifier or ''

Log('info', ('Framework ^3%s^0 found'):format(MSK.Bridge.Framework.Type))

LockStatus = {
    Unlocked = 1,
    Locked = 2,
}

----------------------------------------------------------------
-- ACE Permissions & Commands
----------------------------------------------------------------

-- Frameworks name their group principals differently: ESX and Qbox use
-- `group.<name>`, QBCore uses `qbcore.<name>` (that is what its AddPermission
-- writes) and never puts qbcore.admin or qbcore.mod into any group.* principal.
-- Granting both spellings keeps the command working on all three.
--
-- Routed through msk_core, because FiveM checks add_ace against the resource that
-- runs it and only msk_core is granted that right (one line in the server.cfg:
-- `add_ace resource.msk_core command.add_ace allow`). Guarded so a missing line
-- does not produce "Access denied for command add_ace" on every start,
-- server/admin/permissions.lua prints what is missing.
if MSK.CanAddAce and MSK.CanAddAce() then
    for i = 1, #Config.AdminCommand.groups do
        local group = Config.AdminCommand.groups[i]
        local ace = ('command.%s'):format(Config.AdminCommand.command)
        MSK.AddRawAce(('group.%s'):format(group), ace, true)
        MSK.AddRawAce(('qbcore.%s'):format(group), ace, true)
    end
end

IsAceAllowed = function(playerId, command)
    if not command then command = Config.AdminCommand.command end
    return IsPlayerAceAllowed(playerId, ('command.%s'):format(command))
end

if Config.Commands.refreshKeys.enable then
    RegisterCommand(Config.Commands.refreshKeys.command, function(source, args)
        local src = source
        if src <= 0 then return end

        RefreshPlayerKeys(src)
        Config.Notification(src, Translation[Config.Locale]['refreshed_keys'], 'info')
    end)
end

if Config.AdminCommand.enable then
    RegisterCommand(Config.AdminCommand.command, function(source, args, rawCommand)
        local src = source

        if not IsAceAllowed(src, Config.AdminCommand.command) then
            return Config.Notification(src, Translation[Config.Locale]['no_permissions'], 'error')
        end

        toggleLockAdmin(src)
    end)
end

----------------------------------------------------------------
-- Usable Items (Keys + Transfer-Contract)
----------------------------------------------------------------

CreateThread(function()
    Wait(500) -- wait until the inventory resource is ready

    if Config.Settings.key.canUseItem then
        Inventory.RegisterUsable(Config.Settings.key.itemName, function(playerId)
            toggleLock(playerId)
        end)
    end
end)

if Config.Settings.transferVehicle and Config.Settings.transfer.canUseItem then
    -- MSK.RegisterItem covers ESX, QBCore and Qbox in a single call.
    MSK.RegisterItem(Config.Settings.transfer.itemName, function(playerId)
        TriggerClientEvent('msk_vehiclekeys:openDialog', playerId)
    end)
end

----------------------------------------------------------------
-- Vehicle sale / transfer between players
-- Security: the server stores the offer initiated by the seller (incl. price) server-side.
-- The buyer cannot spoof seller/price/plate when confirming.
----------------------------------------------------------------

local pendingSales = {} -- [buyerId] = { seller, plate, model, price, label }

RegisterNetEvent('msk_vehiclekeys:showTransferDialog', function(targetId, vehicleData)
    local sellerId = source
    targetId = tonumber(targetId)
    if not targetId or targetId == sellerId then return end
    if type(vehicleData) ~= 'table' or not vehicleData.plate then return end

    local plate = MSK.String.Trim(vehicleData.plate)
    local price = tonumber(vehicleData.price)
    if not price or price < 0 then return end

    -- Only the actual owner may create an offer
    if not IsVehicleOwner({ source = sellerId }, plate) then
        return Config.Notification(sellerId, Translation[Config.Locale]['not_vehicle_owner'], 'error')
    end

    pendingSales[targetId] = {
        seller = sellerId,
        plate = plate,
        model = vehicleData.model,
        price = price,
        label = vehicleData.label,
    }

    TriggerClientEvent('msk_vehiclekeys:showTransferDialog', targetId, sellerId, vehicleData)
end)

RegisterNetEvent('msk_vehiclekeys:sellVehicle', function()
    local buyerId = source
    local offer = pendingSales[buyerId]
    if not offer then return end
    pendingSales[buyerId] = nil -- only redeemable once (no double-click exploit)

    local Buyer = GetPlayerFromData({ source = buyerId })
    if not Buyer then return end

    local Seller = GetPlayerFromData({ source = offer.seller })
    if not Seller then
        return Config.Notification(buyerId, Translation[Config.Locale]['transfer_seller_unavailable'], 'error')
    end

    -- Re-validate ownership server-side (the seller could have sold the vehicle in the meantime)
    if not IsVehicleOwner({ source = offer.seller }, offer.plate) then
        return Config.Notification(offer.seller, Translation[Config.Locale]['not_vehicle_owner'], 'error')
    end

    -- For item-based transfer: check the contract item + proximity of the players
    if Config.Settings.transfer.needItem then
        if Inventory.GetItemCount(offer.seller, Config.Settings.transfer.itemName) < 1 then
            return Config.Notification(offer.seller, Translation[Config.Locale]['no_item_found'], 'error')
        end

        local sellerCoords = MSK.Player[offer.seller] and MSK.Player[offer.seller].coords
        local buyerCoords = MSK.Player[buyerId] and MSK.Player[buyerId].coords

        if not sellerCoords or not buyerCoords or #(sellerCoords - buyerCoords) > 10.0 then
            Config.Notification(offer.seller, Translation[Config.Locale]['transfer_too_far'], 'error')
            Config.Notification(buyerId, Translation[Config.Locale]['transfer_too_far'], 'error')
            return
        end
    end

    local vehicleData = { plate = offer.plate, model = offer.model, price = offer.price }

    -- One version instead of one per framework. The order also changed: the
    -- money is taken FIRST and only then credited. Both old branches credited
    -- the seller before the buyer had actually paid, so a deduction that failed
    -- for any reason created money out of nothing.
    --
    -- RemoveMoney refuses on an insufficient balance and reports it, so the
    -- deduction itself decides, not the check in front of it.
    if Buyer.GetMoney('bank') >= offer.price then
        if Buyer.RemoveMoney('bank', offer.price, 'msk_vehiclekeys: vehicle purchase') then
            Seller.AddMoney('bank', offer.price, 'msk_vehiclekeys: vehicle sale')
            TransferVehicle({ player = Seller }, { player = Buyer }, vehicleData)
            Seller.RemoveItem(Config.Settings.transfer.itemName, 1)
        else
            Config.Notification(offer.seller, Translation[Config.Locale]['dialog_not_enough_money2'], 'info')
            Config.Notification(buyerId, Translation[Config.Locale]['dialog_not_enough_money'], 'info')
        end
    else
        Config.Notification(offer.seller, Translation[Config.Locale]['dialog_not_enough_money2'], 'info')
        Config.Notification(buyerId, Translation[Config.Locale]['dialog_not_enough_money'], 'info')
    end
end)

-- Clean up open offers on disconnect
AddEventHandler('playerDropped', function()
    local playerId = source
    pendingSales[playerId] = nil

    for buyerId, offer in pairs(pendingSales) do
        if offer.seller == playerId then
            pendingSales[buyerId] = nil
        end
    end
end)
