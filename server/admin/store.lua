AdminStore = AdminStore or {}

-- In-memory permission matrix: [group_name] = { [perm] = true }
AdminStore.perms = {}
AdminStore.ready = false

----------------------------------------------------------------
-- JSON helpers
----------------------------------------------------------------
local function jdecode(s)
    if type(s) ~= 'string' then return false end
    local ok, v = pcall(json.decode, s)
    if not ok then return false end
    return true, v
end
AdminStore.Decode = jdecode

local function isEnabled(v)
    return tonumber(v) ~= 0
end

----------------------------------------------------------------
-- Load definitions from the DB into Config.* (the runtime source of truth used
-- by client/main.lua, server/functions.lua — all unchanged).
----------------------------------------------------------------
function AdminStore.LoadSettings()
    local rows = MySQL.query.await('SELECT `skey`, `svalue` FROM `msk_vehiclekeys_settings`') or {}
    for _, row in ipairs(rows) do
        if row.skey ~= '__seeded__' and row.skey ~= 'dashboardGroups' then
            local ok, v = jdecode(row.svalue)
            if ok then
                -- The 'Locksmith' setting only carries the behaviour flags; its
                -- locations live in msk_vehiclekeys_locksmiths. Preserve any
                -- already-loaded locations so a settings/lists reload never wipes them.
                if row.skey == 'Locksmith' and type(v) == 'table' then
                    local locs = (type(Config.Locksmith) == 'table') and Config.Locksmith.locations or nil
                    Config.Locksmith = v
                    Config.Locksmith.locations = locs or {}
                else
                    Config[row.skey] = v
                end
            end
        end
    end

    -- dashboardGroups is permission-managed but persisted as its own setting row.
    for _, row in ipairs(rows) do
        if row.skey == 'dashboardGroups' then
            local ok, v = jdecode(row.svalue)
            if ok and type(v) == 'table' then Config.dashboardGroups = v end
        end
    end
end

-- Locksmith locations live in their own table (spatial CRUD). They are written
-- back onto Config.Locksmith.locations, which client/main.lua reads to build the
-- peds/blips. Must run AFTER LoadSettings (which replaces the Locksmith table).
function AdminStore.LoadLocksmiths()
    if type(Config.Locksmith) ~= 'table' then Config.Locksmith = {} end
    Config.Locksmith.locations = {}

    local rows = MySQL.query.await('SELECT `id`, `label`, `data`, `enabled` FROM `msk_vehiclekeys_locksmiths`') or {}
    for _, row in ipairs(rows) do
        if isEnabled(row.enabled) then
            local ok, def = jdecode(row.data)
            if ok and type(def) == 'table' then
                def.id = row.id
                def.label = row.label or def.label
                Config.Locksmith.locations[row.id] = def
            end
        end
    end
end

function AdminStore.LoadPermissions()
    AdminStore.perms = {}
    local rows = MySQL.query.await('SELECT `group_name`, `perms` FROM `msk_vehiclekeys_permissions`') or {}
    for _, row in ipairs(rows) do
        local ok, p = jdecode(row.perms)
        AdminStore.perms[row.group_name] = (ok and type(p) == 'table') and p or {}
    end
end

function AdminStore.LoadAll()
    AdminStore.LoadSettings()
    AdminStore.LoadLocksmiths()
    AdminStore.LoadPermissions()
    AdminStore.ready = true
end
