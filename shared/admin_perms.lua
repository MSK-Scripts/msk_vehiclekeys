AdminPerms = AdminPerms or {}

----------------------------------------------------------------
-- Permission keys. Order matters: the NUI renders the matrix in this order.
--   keys.*      -> Players & Keys tab
--   vehicles.*  -> Vehicles / Plates tab
--   locksmith.* -> Locksmith locations tab (spatial CRUD)
--   lists.manage-> Access lists tab (whitelist/blacklist/admin/job)
--   settings.manage / permissions.manage -> management rights
----------------------------------------------------------------
AdminPerms.PERMS = {
    'keys.view', 'keys.manage',
    'vehicles.view', 'vehicles.manage',
    'locksmith.view', 'locksmith.create', 'locksmith.edit', 'locksmith.delete',
    'lists.manage',
    'settings.manage', 'permissions.manage',
}

-- Settings that may be edited from the dashboard (requires `settings.manage`).
-- These are the DB-managed keys (see config/settings.lua). Static code hooks
-- (config/static.lua) are intentionally NOT here. Locksmith LOCATIONS are managed
-- separately via the Locksmith tab (msk_vehiclekeys_locksmiths), only the Locksmith
-- behaviour flags are stored under the 'Locksmith' setting.
AdminPerms.SETTINGS_KEYS = {
    'Locale', 'Debug', 'VersionChecker',
    'Commands', 'Hotkeys', 'VehicleTarget', 'AdminCommand',
    'OnRefreshKeys', 'GivePrimaryKey', 'KeyRingSystem',
    'Settings', 'Locksmith',
    'Whitelist', 'Blacklist', 'AdminVehicles', 'JobVehicles',
    'adminCommand', 'BrandTag', 'Theme',
}

-- Valid vehicle-key types (used by the api sanitiser + UI dropdowns).
AdminPerms.KEY_TYPES = { 'primary', 'secondary', 'temporary' }

-- Selectable script adapters exposed to the dashboard dropdowns. Keep in sync
-- with the adapters implemented in client/target.lua and client/menu.lua.
AdminPerms.TARGET_SCRIPTS = { 'ox_target' }
AdminPerms.MENU_SCRIPTS = { 'nui', 'msk_context', 'msk_menu', 'ox_context', 'ox_menu' }
AdminPerms.INVENTORY_SCRIPTS = { 'ox_inventory', 'jaksam_inventory' }

-- Editable UI colour keys (hex strings) managed via the dashboard's Settings tab.
-- Keep in sync with web/src/lib/theme.ts (DEFAULT_THEME / THEME_KEYS).
AdminPerms.THEME_KEYS = { 'accent', 'bg', 'panel', 'textPrimary', 'textSecondary' }
AdminPerms.DEFAULT_THEME = {
    accent = '#00E676',
    bg = '#0a0b0d',
    panel = '#131317',
    textPrimary = '#f0ede8',
    textSecondary = '#b0adb8',
}

-- Suggested group names shown in the UI when adding a new group.
AdminPerms.SUGGESTED_GROUPS = { 'admin', 'mod', 'dev' }

-- group.admin always has every right and can never be edited.
AdminPerms.PROTECTED_GROUPS = { admin = true }

-- group.user may NEVER open the dashboard and can never be granted rights.
AdminPerms.BLACKLIST_GROUPS = { user = true }

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------
function AdminPerms.AllPerms()
    local t = {}
    for _, p in ipairs(AdminPerms.PERMS) do t[p] = true end
    return t
end

function AdminPerms.IsProtected(group)
    return AdminPerms.PROTECTED_GROUPS[tostring(group):lower()] == true
end

function AdminPerms.IsBlacklisted(group)
    return AdminPerms.BLACKLIST_GROUPS[tostring(group):lower()] == true
end
