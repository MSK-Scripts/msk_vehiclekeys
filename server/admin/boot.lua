-- Admin dashboard boot: create tables, seed once, load DB into Config, register
-- the command. Runs as its own onResourceStart handler AFTER server/storage.lua
-- has ensured the keys table + cache, so oxmysql is ready.

local function createTables()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `msk_vehiclekeys_settings` (
            `skey` varchar(80) NOT NULL,
            `svalue` longtext DEFAULT NULL,
            PRIMARY KEY (`skey`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `msk_vehiclekeys_permissions` (
            `group_name` varchar(80) NOT NULL,
            `perms` longtext DEFAULT NULL,
            PRIMARY KEY (`group_name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `msk_vehiclekeys_locksmiths` (
            `id` varchar(60) NOT NULL,
            `label` varchar(120) DEFAULT NULL,
            `data` longtext NOT NULL,
            `enabled` tinyint(1) NOT NULL DEFAULT 1,
            `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
end

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    createTables()
    AdminSeed.Run(false)
    AdminStore.LoadAll()
    -- Make sure `group.<name>` is a real ace object, otherwise a player that only
    -- has `add_principal ... group.admin` in server.cfg never passes the check.
    AdminPerms.EnsureAces()
    AdminCommand.Register(Config.adminCommand)

    -- On a live restart, push the freshly loaded definitions to everyone already
    -- connected so their config-matching + locksmith peds/blips match the DB.
    AdminApi.Broadcast()

    print(('^2[msk_vehiclekeys]^0 Admin dashboard ready — command: ^5/%s^0'):format(Config.adminCommand or 'advehiclekeys'))
end)
