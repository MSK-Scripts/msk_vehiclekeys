AdminSeed = AdminSeed or {}

----------------------------------------------------------------
-- vector4 -> plain {x,y,z,w}. The config uses the vector4 type which json.encode
-- can't serialise; client/main.lua reads coords via .x/.y/.z/(.w or .h) so a
-- plain table is a drop-in replacement.
----------------------------------------------------------------
local function vecToTable(v)
    return {
        x = (v.x or 0.0) + 0.0,
        y = (v.y or 0.0) + 0.0,
        z = (v.z or 0.0) + 0.0,
        w = (v.w or v.h or 0.0) + 0.0,
    }
end

local function coordList(list)
    local out = {}
    for i, c in ipairs(list or {}) do out[i] = vecToTable(c) end
    return out
end

-- Locksmith def for storage: coords converted, everything else (label, pedmodel
-- hash, blip table) is vector-free and safe to share.
local function locksmithForStorage(def)
    return {
        label = def.label,
        pedmodel = def.pedmodel,
        blip = def.blip,
        coords = coordList(def.coords),
    }
end

-- Locksmith SETTINGS (behaviour flags) without the locations list — locations
-- live in msk_vehiclekeys_locksmiths.
local function locksmithSettings()
    local src = (type(Config.Locksmith) == 'table') and Config.Locksmith or {}
    local out = {}
    for k, v in pairs(src) do
        if k ~= 'locations' then out[k] = v end
    end
    return out
end

local function isSeeded()
    local row = MySQL.single.await("SELECT `skey` FROM `msk_vehiclekeys_settings` WHERE `skey` = '__seeded__'")
    return row ~= nil
end

local function setSetting(key, value)
    MySQL.insert.await(
        'INSERT INTO `msk_vehiclekeys_settings` (`skey`, `svalue`) VALUES (?, ?) ' ..
        'ON DUPLICATE KEY UPDATE `svalue` = VALUES(`svalue`)',
        { key, json.encode(value) }
    )
end

----------------------------------------------------------------
-- One-time import of the static config into the DB.
----------------------------------------------------------------
function AdminSeed.Run(force)
    if not force and isSeeded() then return false end

    -- Settings (editable whitelist). Locksmith is stored without its locations.
    for _, key in ipairs(AdminPerms.SETTINGS_KEYS) do
        if key == 'Locksmith' then
            setSetting('Locksmith', locksmithSettings())
        elseif Config[key] ~= nil then
            setSetting(key, Config[key])
        end
    end

    -- dashboardGroups is permission-managed but still persisted as a setting.
    setSetting('dashboardGroups', Config.dashboardGroups or {})

    -- Locksmith locations -> own table.
    if type(Config.Locksmith) == 'table' and type(Config.Locksmith.locations) == 'table' then
        for id, def in pairs(Config.Locksmith.locations) do
            MySQL.insert.await(
                'INSERT INTO `msk_vehiclekeys_locksmiths` (`id`, `label`, `data`, `enabled`) VALUES (?, ?, ?, 1) ' ..
                'ON DUPLICATE KEY UPDATE `label` = VALUES(`label`), `data` = VALUES(`data`)',
                { id, def.label, json.encode(locksmithForStorage(def)) }
            )
        end
    end

    -- Default permission groups: admin = all, mod = view-only.
    local adminPerms = AdminPerms.AllPerms()
    local modPerms = { ['keys.view'] = true, ['vehicles.view'] = true }
    MySQL.insert.await(
        'INSERT INTO `msk_vehiclekeys_permissions` (`group_name`, `perms`) VALUES (?, ?) ' ..
        'ON DUPLICATE KEY UPDATE `perms` = VALUES(`perms`)',
        { 'admin', json.encode(adminPerms) }
    )
    MySQL.insert.await(
        'INSERT INTO `msk_vehiclekeys_permissions` (`group_name`, `perms`) VALUES (?, ?) ' ..
        'ON DUPLICATE KEY UPDATE `perms` = VALUES(`perms`)',
        { 'mod', json.encode(modPerms) }
    )

    -- Mark as seeded.
    setSetting('__seeded__', os.time())

    print('^2[msk_vehiclekeys]^0 Admin seed complete (settings/locksmiths/permissions imported into DB).')
    return true
end
