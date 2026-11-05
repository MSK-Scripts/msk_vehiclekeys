AdminCommand = AdminCommand or {}
AdminCommand.registered = {}

-- The command itself is NOT ACE-restricted; access control lives entirely in the
-- callback (AdminPerms.CanOpen) so it respects dashboardGroups + the group.user
-- hard-blacklist. Registering a new name leaves any previously registered name
-- pointing at the same gated handler (harmless) until the next restart.
-- The ace objects the gate relies on (`group.admin` and friends) are registered
-- in server/admin/permissions.lua -> AdminPerms.EnsureAces().
function AdminCommand.Register(name)
    name = name or Config.adminCommand or 'advehiclekeys'
    if AdminCommand.registered[name] then return end
    AdminCommand.registered[name] = true

    MSK.RegisterCommand(name, function(source)
        local src = source
        if src == 0 then
            print('^3[msk_vehiclekeys]^0 The admin dashboard can only be opened in-game.')
            return
        end
        if not AdminPerms.CanOpen(src) then
            Config.Notification(src, Translation[Config.Locale]['no_permissions'] or 'No permission for the admin dashboard.', 'error')
            return
        end
        TriggerClientEvent('msk_vehiclekeys:admin:open', src, AdminApi.BuildBootstrap(src))
    end, {
        help = 'Open the MSK Vehiclekeys admin dashboard',
        restricted = false,
    })
end
