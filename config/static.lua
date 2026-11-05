Config = Config or {}

--[[============================================================
    STATIC / CODE CONFIGURATION  (NOT managed by DB / dashboard)

    These are code hooks and adapters. The admin dashboard and the
    database NEVER touch anything in this file — edit it directly.
    Changes take effect on resource restart.
============================================================]]--

----------------------------------------------------------------
-- No longer used. msk_core detects the framework (ESX, QBCore, Qbox or
-- STANDALONE) and this resource asks msk_core about it, so changing the value
-- here has no effect. Pin it in msk_core's config.lua instead.
--
-- The line is kept so that an existing config file does not break.
Config.Framework = 'AUTO'
----------------------------------------------------------------
-- luxu_admin integration (for the admin dashboard access).
-- luxu_admin v2 keeps its staff groups internally, not as FiveM ACE principals,
-- so a normal IsPlayerAceAllowed('group.x') check does not see them. When enabled,
-- the dashboard also resolves a player's group through luxu_admin's export
-- (getPlayerStaffGroup). The resolved group is matched against your dashboard
-- groups by name (group.admin always = full access).
Config.LuxuAdmin = {
    enable = 'auto',          -- 'auto' (on when the resource is started), true, or false
    resource = 'luxu_admin',  -- change if you renamed the resource
    requireDuty = false,      -- true = the staff member must be ON DUTY to be recognized

    -- Optional: map luxu_admin staff group names to your msk_vehiclekeys dashboard
    -- groups. Unmapped groups are matched by their own (lowercased) name.
    -- Example: a luxu_admin 'owner' should get full access -> map it to 'admin'.
    groupMap = {
        -- ['owner'] = 'admin',
        -- ['superadmin'] = 'admin',
    },
}
----------------------------------------------------------------
-- Notification (clientside AND serverside)
-- !!! This function is clientside AND serverside !!!
Config.Notification = function(source, message, typ)
    if IsDuplicityVersion() then -- serverside
        MSK.Notification(source, { title = 'Vehicle Keys', message = message, type = typ, duration = 5000 })
    else -- clientside
        MSK.Notification({ title = 'Vehicle Keys', message = message, type = typ, duration = 5000 })
    end
end
----------------------------------------------------------------
-- TextUI adapter (clientside) used by the Locksmith when
-- Config.Locksmith.defaultTextUI is set to false.
Config.openTextUI = function(coloredText, uncoloredText)
    MSK.TextUI.Show({ key = 'E', text = coloredText })
end

Config.closeTextUI = function()
    MSK.TextUI.Hide()
end
----------------------------------------------------------------
exports('Config', function()
    return Config
end)
