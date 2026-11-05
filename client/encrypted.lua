-- The client no longer reports its own load. msk_core raises the load and
-- logout events on the server too, and server/storage.lua listens there, which
-- does not depend on a client sending anything.
--
-- What used to stand here listened to the two QBCore events, so on ESX nothing
-- was ever reported at all. The msk_vehiclekeys:playerLoaded net event still
-- exists for anything outside this resource that triggers it.

GetKeyCount = function(keys, typ)
    local keyCount = 0

    if not typ then
        return #keys
    end

    for i=1, #keys do
        if typ == keys[i].type then
            keyCount = keyCount + 1
        end
    end

    return keyCount
end
exports('GetKeyCount', GetKeyCount)

hasCorrectItem = function(playerId, item, plate)
    return MSK.Trigger('msk_vehiclekeys:hasCorrectItem', playerId, item, plate)
end
exports('hasCorrectItem', hasCorrectItem)

logging = function(code, ...)
    if not Config.Debug then return end
    MSK.Logging(code, ...)
end