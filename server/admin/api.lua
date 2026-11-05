AdminApi = AdminApi or {}

----------------------------------------------------------------
-- Input sanitisation. NEVER trust client structures — every field is coerced
-- and whitelisted before it touches the DB or a mutating function.
----------------------------------------------------------------
local ID_PATTERN = '^[%w_%-]+$'
local MAX_COORDS = 20

local function num(v, default)
    local n = tonumber(v)
    if n == nil then return default end
    return n + 0.0
end

local function int(v, default)
    local n = tonumber(v)
    if n == nil then return default end
    return math.floor(n)
end

local function bool(v) return v == true end

local function str(v, max)
    if type(v) ~= 'string' then return nil end
    if #v > (max or 120) then v = v:sub(1, max or 120) end
    return v
end

-- Returns value if it is in the allowed list, otherwise the fallback.
local function oneOf(value, list, fallback)
    if type(value) == 'string' then
        for _, v in ipairs(list) do
            if v == value then return value end
        end
    end
    return fallback
end

-- Trimmed plate string (max 12). Returns nil for anything invalid.
local function cleanPlate(v)
    if type(v) ~= 'string' then return nil end
    local p = MSK.String.Trim(v)
    if p == '' or #p > 12 then return nil end
    return p
end

local function coord(c)
    if type(c) ~= 'table' then return nil end
    local x, y, z = tonumber(c.x), tonumber(c.y), tonumber(c.z)
    if not (x and y and z) then return nil end
    if math.abs(x) > 30000 or math.abs(y) > 30000 or z < -2000 or z > 20000 then return nil end
    return { x = x + 0.0, y = y + 0.0, z = z + 0.0, w = num(c.w, 0.0) }
end

local function coordList(list)
    if type(list) ~= 'table' then return nil end
    local out = {}
    for i, c in ipairs(list) do
        if i > MAX_COORDS then break end
        local cc = coord(c)
        if not cc then return nil end
        out[#out + 1] = cc
    end
    if #out == 0 then return nil end
    return out
end

-- Vehicle model NAME list (strings). Numeric (legacy hash) entries are kept too.
local function modelNameList(list)
    if type(list) ~= 'table' then return {} end
    local out, seen = {}, {}
    for _, v in ipairs(list) do
        local name
        if type(v) == 'string' then
            name = MSK.String.Trim(v)
            if #name == 0 or #name > 60 then name = nil end
        elseif type(v) == 'number' then
            name = math.floor(v)
        end
        if name ~= nil and not seen[name] then
            seen[name] = true
            out[#out + 1] = name
        end
    end
    return out
end

-- Plate substring list (strings). Empty strings are dropped (would match all).
local function plateList(list)
    if type(list) ~= 'table' then return {} end
    local out, seen = {}, {}
    for _, v in ipairs(list) do
        if type(v) == 'string' then
            local p = MSK.String.Trim(v)
            if #p > 0 and #p <= 12 and not seen[p] then
                seen[p] = true
                out[#out + 1] = p
            end
        end
    end
    return out
end

----------------------------------------------------------------
-- Settings normalisers (nested tables rebuilt from scratch, current config as
-- the fallback base so partial patches and unknown fields are always safe).
----------------------------------------------------------------
local function tbl(v) return type(v) == 'table' and v or {} end

local function normCommands(v, cur)
    v, cur = tbl(v), tbl(cur)
    local out = {}
    for _, name in ipairs({ 'lock', 'keyMenu', 'refreshKeys' }) do
        local iv, ic = tbl(v[name]), tbl(cur[name])
        out[name] = {
            enable = (v[name] ~= nil) and bool(iv.enable) or (ic.enable == true),
            command = str(iv.command, 32) or ic.command or name,
        }
    end
    return out
end

local function normHotkeys(v, cur)
    v, cur = tbl(v), tbl(cur)
    local out = {}
    for _, name in ipairs({ 'lock', 'keyMenu' }) do
        local iv, ic = tbl(v[name]), tbl(cur[name])
        out[name] = {
            enable = (v[name] ~= nil) and bool(iv.enable) or (ic.enable == true),
            key = str(iv.key, 20) or ic.key or '',
        }
    end
    return out
end

local function normVehicleTarget(v, cur)
    v, cur = tbl(v), tbl(cur)
    return {
        enable = bool(v.enable),
        selectSeat = bool(v.selectSeat),
        script = oneOf(v.script, AdminPerms.TARGET_SCRIPTS, cur.script or AdminPerms.TARGET_SCRIPTS[1]),
    }
end

local function normAdminCommand(v, cur)
    v, cur = tbl(v), tbl(cur)
    local groups = {}
    if type(v.groups) == 'table' then
        for _, g in ipairs(v.groups) do
            local gg = str(g, 40)
            if gg then groups[#groups + 1] = gg:lower() end
        end
    else
        groups = cur.groups or {}
    end
    return {
        enable = bool(v.enable),
        command = str(v.command, 32) or cur.command or 'adlock',
        groups = groups,
    }
end

local function normRefreshFlags(v, cur)
    v, cur = tbl(v), tbl(cur)
    local function grp(name)
        local iv, ic = tbl(v[name]), tbl(cur[name])
        return {
            primaryKeys = (v[name] ~= nil) and bool(iv.primaryKeys) or (ic.primaryKeys == true),
            secondaryKeys = (v[name] ~= nil) and bool(iv.secondaryKeys) or (ic.secondaryKeys == true),
        }
    end
    return { OnPlayerLoaded = grp('OnPlayerLoaded'), OnRefreshKeys = grp('OnRefreshKeys') }
end

local function normGivePrimaryKey(v, cur)
    v, cur = tbl(v), tbl(cur)
    local out = {}
    for _, k in ipairs({ 'giveSecondaryKey', 'givePrimaryKey', 'removePrimaryKey', 'transferOwnership' }) do
        out[k] = (v[k] ~= nil) and bool(v[k]) or (cur[k] == true)
    end
    return out
end

local function normKeyRing(v, cur)
    v, cur = tbl(v), tbl(cur)
    return {
        enable = bool(v.enable),
        addItem = bool(v.addItem),
        item = str(v.item, 40) or cur.item or 'keyring',
    }
end

local function normSettingsTable(v, cur)
    v, cur = tbl(v), tbl(cur)
    local vm, cm = tbl(v.menu), tbl(cur.menu)
    local vk, ck = tbl(v.key), tbl(cur.key)
    local vt, ct = tbl(v.transfer), tbl(cur.transfer)
    local vn, cn = tbl(v.lockVehiclesFromNPCs), tbl(cur.lockVehiclesFromNPCs)
    return {
        lockDistance = num(v.lockDistance, cur.lockDistance or 8.0),
        exchangeLocksPrice = math.max(0, int(v.exchangeLocksPrice, cur.exchangeLocksPrice or 0)),
        transferVehicle = (v.transferVehicle ~= nil) and bool(v.transferVehicle) or (cur.transferVehicle == true),
        lockVehiclesFromNPCs = {
            enable = (v.lockVehiclesFromNPCs ~= nil) and bool(vn.enable) or (cn.enable == true),
            probability = math.max(0, math.min(100, int(vn.probability, cn.probability or 0))),
        },
        menu = {
            showSecondaryKeys = (v.menu ~= nil) and bool(vm.showSecondaryKeys) or (cm.showSecondaryKeys == true),
            showTempKeys = (v.menu ~= nil) and bool(vm.showTempKeys) or (cm.showTempKeys == true),
            showExchangeLocks = (v.menu ~= nil) and bool(vm.showExchangeLocks) or (cm.showExchangeLocks == true),
            showTransferVehicle = (v.menu ~= nil) and bool(vm.showTransferVehicle) or (cm.showTransferVehicle == true),
            refreshPlayerKeys = (v.menu ~= nil) and bool(vm.refreshPlayerKeys) or (cm.refreshPlayerKeys == true),
            keysMenu = oneOf(vm.keysMenu, AdminPerms.MENU_SCRIPTS, cm.keysMenu or AdminPerms.MENU_SCRIPTS[1]),
        },
        key = {
            needItem = (v.key ~= nil) and bool(vk.needItem) or (ck.needItem == true),
            canUseItem = (v.key ~= nil) and bool(vk.canUseItem) or (ck.canUseItem == true),
            itemName = str(vk.itemName, 40) or ck.itemName or 'keys',
            uniqueItems = (v.key ~= nil) and bool(vk.uniqueItems) or (ck.uniqueItems == true),
            inventory = oneOf(vk.inventory, AdminPerms.INVENTORY_SCRIPTS, ck.inventory or AdminPerms.INVENTORY_SCRIPTS[1]),
            itemLabel = str(vk.itemLabel, 60) or ck.itemLabel or 'Vehicle Key',
            plateLabel = str(vk.plateLabel, 60) or ck.plateLabel or 'Plate: %s',
            toggleWithKey = (v.key ~= nil) and bool(vk.toggleWithKey) or (ck.toggleWithKey == true),
            ownerNeedsItem = (v.key ~= nil) and bool(vk.ownerNeedsItem) or (ck.ownerNeedsItem == true),
        },
        transfer = {
            needItem = (v.transfer ~= nil) and bool(vt.needItem) or (ct.needItem == true),
            canUseItem = (v.transfer ~= nil) and bool(vt.canUseItem) or (ct.canUseItem == true),
            itemName = str(vt.itemName, 40) or ct.itemName or 'contract',
        },
        animation = {
            dict = str(tbl(v.animation).dict, 100) or tbl(cur.animation).dict or 'anim@mp_player_intmenu@key_fob@',
            anim = str(tbl(v.animation).anim, 100) or tbl(cur.animation).anim or 'fob_click_fp',
            -- prop is a spawn NAME (string); hashed at runtime in client/functions.lua.
            prop = str(tbl(v.animation).prop, 60) or tbl(cur.animation).prop or 'lr_prop_carkey_fob',
        },
    }
end

local function normLocksmithFlags(v, cur)
    v, cur = tbl(v), tbl(cur)
    local vts, cts = tbl(v.targetSystem), tbl(cur.targetSystem)
    local vnv, cnv = tbl(v.npcVoice), tbl(cur.npcVoice)
    return {
        enable = bool(v.enable),
        defaultTextUI = bool(v.defaultTextUI),
        menu = oneOf(v.menu, AdminPerms.MENU_SCRIPTS, cur.menu or AdminPerms.MENU_SCRIPTS[1]),
        targetSystem = {
            enable = (v.targetSystem ~= nil) and bool(vts.enable) or (cts.enable == true),
            script = oneOf(vts.script, AdminPerms.TARGET_SCRIPTS, cts.script or AdminPerms.TARGET_SCRIPTS[1]),
        },
        npcVoice = {
            enable = (v.npcVoice ~= nil) and bool(vnv.enable) or (cnv.enable == true),
            inRange = num(vnv.inRange, cnv.inRange or 5.0),
            outRange = num(vnv.outRange, cnv.outRange or 5.0),
        },
    }
end

local function normTheme(v, cur)
    v = tbl(v)
    cur = (type(cur) == 'table') and cur or AdminPerms.DEFAULT_THEME
    local theme = {}
    for _, ck in ipairs(AdminPerms.THEME_KEYS) do
        local hex = type(v[ck]) == 'string' and v[ck]:match('^#%x%x%x%x%x%x$')
        theme[ck] = hex or cur[ck] or AdminPerms.DEFAULT_THEME[ck]
    end
    return theme
end

-- Validates a settings patch against the editable whitelist. The four access-list
-- keys are intentionally NOT handled here (managed via the Lists tab / lists:save).

-- A locale is valid iff translation.lua actually ships it. Deriving this from the
-- Translation global means adding a language there is enough — no second list to
-- keep in sync (drift-proof).
local function isLocale(v)
    return type(v) == 'string' and type(Translation) == 'table' and Translation[v] ~= nil
end

function AdminApi.SanitizeSettings(patch)
    local out = {}
    if type(patch) ~= 'table' then return out end

    for _, key in ipairs(AdminPerms.SETTINGS_KEYS) do
        local v = patch[key]
        if v ~= nil then
            if key == 'Locale' then
                if isLocale(v) then out[key] = v end
            elseif key == 'Debug' or key == 'VersionChecker' then
                out[key] = bool(v)
            elseif key == 'adminCommand' then
                local cmd = str(v, 32)
                if cmd and cmd:match('^[%w_]+$') then out[key] = cmd end
            elseif key == 'BrandTag' then
                local tag = str(v, 16)
                if tag ~= nil then out[key] = tag:gsub('[%c]', '') end
            elseif key == 'Theme' then
                out[key] = normTheme(v, Config.Theme)
            elseif key == 'Commands' then
                out[key] = normCommands(v, Config.Commands)
            elseif key == 'Hotkeys' then
                out[key] = normHotkeys(v, Config.Hotkeys)
            elseif key == 'VehicleTarget' then
                out[key] = normVehicleTarget(v, Config.VehicleTarget)
            elseif key == 'AdminCommand' then
                out[key] = normAdminCommand(v, Config.AdminCommand)
            elseif key == 'OnRefreshKeys' then
                out[key] = normRefreshFlags(v, Config.OnRefreshKeys)
            elseif key == 'GivePrimaryKey' then
                out[key] = normGivePrimaryKey(v, Config.GivePrimaryKey)
            elseif key == 'KeyRingSystem' then
                out[key] = normKeyRing(v, Config.KeyRingSystem)
            elseif key == 'Settings' then
                out[key] = normSettingsTable(v, Config.Settings)
            elseif key == 'Locksmith' then
                out[key] = normLocksmithFlags(v, Config.Locksmith)
            end
            -- Whitelist / Blacklist / AdminVehicles / JobVehicles: handled by lists:save
        end
    end
    return out
end

-- Access lists ---------------------------------------------------
local function normJobVehicles(v)
    if type(v) ~= 'table' then return {} end
    local out = {}
    for job, def in pairs(v) do
        if type(job) == 'string' and #job > 0 and #job <= 50 and type(def) == 'table' then
            local entry = {
                models = modelNameList(def.models),
                plates = plateList(def.plates),
            }
            if type(def.ranks) == 'table' then
                local ranks = {}
                for rank, rdef in pairs(def.ranks) do
                    if type(rank) == 'string' and #rank > 0 and #rank <= 50 and type(rdef) == 'table' then
                        ranks[rank] = {
                            models = modelNameList(rdef.models),
                            plates = plateList(rdef.plates),
                        }
                    end
                end
                if next(ranks) ~= nil then entry.ranks = ranks end
            end
            out[job:lower()] = entry
        end
    end
    return out
end

function AdminApi.SanitizeLists(patch)
    local out = {}
    if type(patch) ~= 'table' then return out end
    for _, key in ipairs({ 'Whitelist', 'Blacklist', 'AdminVehicles' }) do
        local v = patch[key]
        if v ~= nil then
            out[key] = { models = modelNameList(tbl(v).models), plates = plateList(tbl(v).plates) }
        end
    end
    if patch.JobVehicles ~= nil then
        out.JobVehicles = normJobVehicles(patch.JobVehicles)
    end
    return out
end

-- Locksmith locations -------------------------------------------
local function blipTable(b)
    if type(b) ~= 'table' then return { enable = false, label = 'Locksmith Service', id = 134, scale = 1.0, color = 0 } end
    return {
        enable = bool(b.enable),
        label = str(b.label, 80) or 'Locksmith Service',
        id = int(b.id, 134),
        scale = num(b.scale, 1.0),
        color = int(b.color, 0),
    }
end

function AdminApi.SanitizeLocksmith(input)
    if type(input) ~= 'table' then return nil, 'bad_input' end
    local id = input.id
    if type(id) ~= 'string' or #id == 0 or #id > 60 or not id:match(ID_PATTERN) then return nil, 'bad_id' end
    local coords = coordList(input.coords); if not coords then return nil, 'bad_coords' end
    return {
        id = id,
        label = str(input.label, 120) or id,
        pedmodel = str(input.pedmodel, 60) or 's_m_m_autoshop_01',
        blip = blipTable(input.blip),
        coords = coords,
    }
end

----------------------------------------------------------------
-- Player / plate helpers (dynamic data, not part of the bootstrap)
----------------------------------------------------------------
function AdminApi.ResolveName(identifier)
    identifier = tostring(identifier)
    local Player = GetPlayerFromData({ identifier = identifier })
    if Player then
        local src = GetPlayerSource({ player = Player })
        if src then return GetPlayerName(src) or identifier end
    end

    -- ESX keeps first and last name in their own columns, QBCore and Qbox keep
    -- them as JSON in `charinfo`.
    --
    -- This asked Config.Framework, which is only ever 'AUTO' now that msk_core
    -- does the detection, so both branches were skipped and an offline player
    -- was always shown as their raw identifier.
    if MSK.Bridge.Framework.Type == 'ESX' then
        local row = MySQL.single.await(('SELECT firstname, lastname FROM %s WHERE %s = ? LIMIT 1'):format(USER_TABLE_NAME, IDENTIFIER_COLUMN_NAME), { identifier })
        if row then
            local name = ('%s %s'):format(row.firstname or '', row.lastname or '')
            name = name:gsub('^%s+', ''):gsub('%s+$', '')
            if #name > 0 then return name end
        end
    else
        local row = MySQL.single.await(('SELECT charinfo FROM %s WHERE %s = ? LIMIT 1'):format(USER_TABLE_NAME, IDENTIFIER_COLUMN_NAME), { identifier })
        if row and row.charinfo then
            local ok, ci = pcall(json.decode, row.charinfo)
            if ok and type(ci) == 'table' then
                local name = ('%s %s'):format(ci.firstname or '', ci.lastname or '')
                name = name:gsub('^%s+', ''):gsub('%s+$', '')
                if #name > 0 then return name end
            end
        end
    end

    return identifier
end

function AdminApi.PlayerLookup(identifier)
    if type(identifier) ~= 'string' or #identifier == 0 then return nil end
    local Player = GetPlayerFromData({ identifier = identifier })
    local online = Player ~= nil
    local serverId = online and GetPlayerSource({ player = Player }) or nil

    local keys = {}
    for _, k in ipairs(VehicleKeys[identifier] or {}) do
        keys[#keys + 1] = { plate = k.plate, type = k.type, model = k.model }
    end

    return {
        identifier = identifier,
        name = AdminApi.ResolveName(identifier),
        online = online,
        serverId = serverId,
        keys = keys,
        vehicles = GetPlayerVehicles({ identifier = identifier }),
    }
end

function AdminApi.PlateLookup(plate)
    plate = cleanPlate(plate)
    if not plate then return nil end

    local owners = {}
    local rows = MySQL.query.await(('SELECT %s AS owner FROM %s WHERE TRIM(plate) = ?'):format(OWNER_COLUMN_NAME, VEHICLE_TABLE_NAME), { plate }) or {}
    for _, r in ipairs(rows) do
        if r.owner then
            owners[#owners + 1] = {
                identifier = r.owner,
                name = AdminApi.ResolveName(r.owner),
                online = GetPlayerFromData({ identifier = r.owner }) ~= nil,
            }
        end
    end

    local holders = {}
    for ident, keys in pairs(VehicleKeys) do
        for i = 1, #keys do
            if keys[i].plate == plate then
                holders[#holders + 1] = {
                    identifier = ident,
                    name = AdminApi.ResolveName(ident),
                    type = keys[i].type,
                    model = keys[i].model,
                    online = GetPlayerFromData({ identifier = ident }) ~= nil,
                }
            end
        end
    end

    return { plate = plate, owners = owners, holders = holders }
end

function AdminApi.OnlinePlayers()
    local out = {}
    for _, pid in ipairs(GetPlayers()) do
        pid = tonumber(pid)
        local Player = GetPlayerFromData({ source = pid })
        if Player then
            local jobName = GetPlayerJob({ player = Player })
            out[#out + 1] = {
                serverId = pid,
                identifier = GetPlayerIdentifier({ player = Player }),
                name = GetPlayerName(pid),
                job = jobName,
            }
        end
    end
    table.sort(out, function(a, b) return a.serverId < b.serverId end)
    return out
end

----------------------------------------------------------------
-- Bootstrap / sync payloads
----------------------------------------------------------------
function AdminApi.SettingsPayload()
    local out = {}
    for _, key in ipairs(AdminPerms.SETTINGS_KEYS) do out[key] = Config[key] end
    -- Locksmith locations are managed separately -> strip from the settings payload.
    if type(out.Locksmith) == 'table' then
        local ls = {}
        for k, v in pairs(out.Locksmith) do
            if k ~= 'locations' then ls[k] = v end
        end
        out.Locksmith = ls
    end
    out.dashboardGroups = Config.dashboardGroups or {}
    return out
end

function AdminApi.LocksmithsArray()
    local out = {}
    local locs = (type(Config.Locksmith) == 'table' and type(Config.Locksmith.locations) == 'table') and Config.Locksmith.locations or {}
    for id, def in pairs(locs) do
        local c = {}
        for k, v in pairs(def) do c[k] = v end
        c.id = id
        out[#out + 1] = c
    end
    table.sort(out, function(a, b) return tostring(a.id) < tostring(b.id) end)
    return out
end

function AdminApi.GroupsArray()
    local out = {}
    out[#out + 1] = { name = 'admin', protected = true, perms = AdminPerms.AllPerms() }
    for name, matrix in pairs(AdminStore.perms) do
        if name ~= 'admin' then
            out[#out + 1] = { name = name, protected = false, perms = matrix }
        end
    end
    return out
end

-- Locale codes shipped by translation.lua, sorted. Feeds the language dropdown so
-- every translated language is selectable (no hardcoded frontend list).
function AdminApi.LocalesArray()
    local out = {}
    if type(Translation) == 'table' then
        for code in pairs(Translation) do
            if type(code) == 'string' then out[#out + 1] = code end
        end
    end
    table.sort(out)
    return out
end

-- msk_core 4.0.0 answers this for every framework and hands the grades over
-- already normalised and sorted, so the per-framework grade handling that used
-- to sit here is gone. It knew ESX and QBCore only, and read the grade number
-- from a different place in each: on Qbox the list stayed empty.
function AdminApi.JobsList()
    local out = {}

    for name, job in pairs(MSK.GetJobs() or {}) do
        out[#out + 1] = { name = name, label = job.label or name, grades = job.grades or {} }
    end
    table.sort(out, function(a, b) return (a.label or a.name):lower() < (b.label or b.name):lower() end)
    return out
end

function AdminApi.BuildBootstrap(src)
    return {
        locale = Config.Locale,
        perms = AdminPerms.GetPlayerPerms(src),
        permKeys = AdminPerms.PERMS,
        settings = AdminApi.SettingsPayload(),
        locksmiths = AdminApi.LocksmithsArray(),
        groups = AdminApi.GroupsArray(),
        suggestedGroups = AdminPerms.SUGGESTED_GROUPS,
        keyTypes = AdminPerms.KEY_TYPES,
        locales = AdminApi.LocalesArray(),
        jobsList = AdminApi.JobsList(),
        players = AdminApi.OnlinePlayers(),
        scripts = {
            target = AdminPerms.TARGET_SCRIPTS,
            menu = AdminPerms.MENU_SCRIPTS,
            inventory = AdminPerms.INVENTORY_SCRIPTS,
        },
    }
end

-- Push settings + locksmith locations to all clients so their config-driven
-- matching (whitelist/blacklist) and locksmith peds/blips update live.
function AdminApi.Broadcast()
    TriggerClientEvent('msk_vehiclekeys:syncDefinitions', -1, {
        settings = AdminApi.SettingsPayload(),
        locksmiths = (type(Config.Locksmith) == 'table' and Config.Locksmith.locations) or {},
    })
end

local function ok(src) return { ok = true, data = AdminApi.BuildBootstrap(src) } end
local function fail(err) return { ok = false, err = err } end

local function setSetting(key, value)
    MySQL.insert.await(
        'INSERT INTO `msk_vehiclekeys_settings` (`skey`, `svalue`) VALUES (?, ?) ' ..
        'ON DUPLICATE KEY UPDATE `svalue` = VALUES(`svalue`)',
        { key, json.encode(value) }
    )
end

----------------------------------------------------------------
-- Callbacks (client -> server via MSK.Trigger). Every mutation is gated.
----------------------------------------------------------------

-- Public: client pulls the authoritative definitions on join (settings +
-- locksmith locations — the same config the client already ships).
MSK.Register('msk_vehiclekeys:admin:getDefinitions', function(_src)
    return {
        settings = AdminApi.SettingsPayload(),
        locksmiths = (type(Config.Locksmith) == 'table' and Config.Locksmith.locations) or {},
    }
end)

MSK.Register('msk_vehiclekeys:admin:bootstrap', function(src)
    if not AdminPerms.CanOpen(src) then return fail('no_permission') end
    return ok(src)
end)

-- Players & Keys ------------------------------------------------
MSK.Register('msk_vehiclekeys:admin:players:list', function(src)
    if not AdminPerms.Has(src, 'keys.view') and not AdminPerms.Has(src, 'vehicles.view') then return fail('no_permission') end
    return { ok = true, players = AdminApi.OnlinePlayers() }
end)

MSK.Register('msk_vehiclekeys:admin:player:lookup', function(src, data)
    if not AdminPerms.Has(src, 'keys.view') then return fail('no_permission') end
    local identifier = type(data) == 'table' and data.identifier or nil
    if type(identifier) ~= 'string' or #identifier == 0 or #identifier > 60 then return fail('bad_input') end
    local player = AdminApi.PlayerLookup(identifier)
    if not player then return fail('not_found') end
    return { ok = true, player = player }
end)

MSK.Register('msk_vehiclekeys:admin:keys:add', function(src, data)
    if not AdminPerms.Has(src, 'keys.manage') then return fail('no_permission') end
    if type(data) ~= 'table' then return fail('bad_input') end
    local identifier = type(data.identifier) == 'string' and data.identifier or nil
    local plate = cleanPlate(data.plate)
    local typ = oneOf(data.type, AdminPerms.KEY_TYPES, 'primary')
    if not identifier or #identifier > 60 or not plate then return fail('bad_input') end

    local vehicleData = { plate = plate, type = typ }
    if data.model ~= nil then vehicleData.model = int(data.model, nil) end
    AddKey({ identifier = identifier }, vehicleData, not bool(data.giveItem))
    return { ok = true, player = AdminApi.PlayerLookup(identifier) }
end)

MSK.Register('msk_vehiclekeys:admin:keys:remove', function(src, data)
    if not AdminPerms.Has(src, 'keys.manage') then return fail('no_permission') end
    if type(data) ~= 'table' then return fail('bad_input') end
    local identifier = type(data.identifier) == 'string' and data.identifier or nil
    local plate = cleanPlate(data.plate)
    local typ = oneOf(data.type, AdminPerms.KEY_TYPES, 'primary')
    if not identifier or #identifier > 60 or not plate then return fail('bad_input') end

    RemoveKey({ identifier = identifier }, { plate = plate, type = typ })
    return { ok = true, player = AdminApi.PlayerLookup(identifier) }
end)

MSK.Register('msk_vehiclekeys:admin:keys:giveItem', function(src, data)
    if not AdminPerms.Has(src, 'keys.manage') then return fail('no_permission') end
    if type(data) ~= 'table' then return fail('bad_input') end
    local identifier = type(data.identifier) == 'string' and data.identifier or nil
    local plate = cleanPlate(data.plate)
    local typ = oneOf(data.type, AdminPerms.KEY_TYPES, 'primary')
    if not identifier or #identifier > 60 or not plate then return fail('bad_input') end
    if not GetPlayerFromData({ identifier = identifier }) then return fail('player_offline') end

    AddKeyToInv({ identifier = identifier }, plate, typ)
    return { ok = true, player = AdminApi.PlayerLookup(identifier) }
end)

MSK.Register('msk_vehiclekeys:admin:keys:takeItem', function(src, data)
    if not AdminPerms.Has(src, 'keys.manage') then return fail('no_permission') end
    if type(data) ~= 'table' then return fail('bad_input') end
    local identifier = type(data.identifier) == 'string' and data.identifier or nil
    local plate = cleanPlate(data.plate)
    if not identifier or #identifier > 60 or not plate then return fail('bad_input') end
    if not GetPlayerFromData({ identifier = identifier }) then return fail('player_offline') end

    RemoveKeyFromInv({ identifier = identifier }, plate)
    return { ok = true, player = AdminApi.PlayerLookup(identifier) }
end)

-- Normal refresh (respects Config.OnRefreshKeys) and FORCE refresh (re-adds ALL
-- missing key items regardless of the config flags). Both require the player online.
local function doRefresh(src, data, force)
    if not AdminPerms.Has(src, 'keys.manage') then return fail('no_permission') end
    local identifier = type(data) == 'table' and type(data.identifier) == 'string' and data.identifier or nil
    if not identifier or #identifier > 60 then return fail('bad_input') end
    local Player = GetPlayerFromData({ identifier = identifier })
    if not Player then return fail('player_offline') end
    RefreshPlayerKeys(GetPlayerSource({ player = Player }), force)
    return { ok = true, player = AdminApi.PlayerLookup(identifier) }
end

MSK.Register('msk_vehiclekeys:admin:keys:refresh', function(src, data)
    return doRefresh(src, data, false)
end)

MSK.Register('msk_vehiclekeys:admin:keys:refreshForce', function(src, data)
    return doRefresh(src, data, true)
end)

-- Vehicles / Plates ---------------------------------------------
MSK.Register('msk_vehiclekeys:admin:plate:lookup', function(src, data)
    if not AdminPerms.Has(src, 'vehicles.view') then return fail('no_permission') end
    local plate = cleanPlate(type(data) == 'table' and data.plate or nil)
    if not plate then return fail('bad_input') end
    return { ok = true, plate = AdminApi.PlateLookup(plate) }
end)

MSK.Register('msk_vehiclekeys:admin:plate:removeAllKeys', function(src, data)
    if not AdminPerms.Has(src, 'vehicles.manage') then return fail('no_permission') end
    local plate = cleanPlate(type(data) == 'table' and data.plate or nil)
    if not plate then return fail('bad_input') end
    RemoveAllExistingKeys(plate)
    return { ok = true, plate = AdminApi.PlateLookup(plate) }
end)

-- Reset locks (admin): remove every key for the plate that is NOT an owner's
-- primary key. Keeps the legit owner able to use their vehicle, revokes shared /
-- secondary / temporary / foreign keys.
MSK.Register('msk_vehiclekeys:admin:plate:resetLocks', function(src, data)
    if not AdminPerms.Has(src, 'vehicles.manage') then return fail('no_permission') end
    local plate = cleanPlate(type(data) == 'table' and data.plate or nil)
    if not plate then return fail('bad_input') end

    -- Owner identifiers for this plate.
    local owners = {}
    local rows = MySQL.query.await(('SELECT %s AS owner FROM %s WHERE TRIM(plate) = ?'):format(OWNER_COLUMN_NAME, VEHICLE_TABLE_NAME), { plate }) or {}
    for _, r in ipairs(rows) do if r.owner then owners[r.owner] = true end end

    for ident, keys in pairs(VehicleKeys) do
        for i = #keys, 1, -1 do
            if keys[i].plate == plate then
                local isOwnerPrimary = owners[ident] and keys[i].type == 'primary'
                if not isOwnerPrimary then
                    RemoveKey({ identifier = ident }, { plate = plate, type = keys[i].type })
                end
            end
        end
    end
    return { ok = true, plate = AdminApi.PlateLookup(plate) }
end)

MSK.Register('msk_vehiclekeys:admin:plate:changePlate', function(src, data)
    if not AdminPerms.Has(src, 'vehicles.manage') then return fail('no_permission') end
    if type(data) ~= 'table' then return fail('bad_input') end
    local oldPlate = cleanPlate(data.oldPlate)
    local newPlate = cleanPlate(data.newPlate)
    if not oldPlate or not newPlate then return fail('bad_input') end
    if oldPlate == newPlate then return fail('same_plate') end

    ChangeNumberPlate(oldPlate, newPlate, true)
    return { ok = true, plate = AdminApi.PlateLookup(newPlate) }
end)

-- Locksmith locations -------------------------------------------
MSK.Register('msk_vehiclekeys:admin:locksmith:save', function(src, data)
    local def, err = AdminApi.SanitizeLocksmith(type(data) == 'table' and data.locksmith or nil)
    if not def then return fail(err or 'bad_input') end

    local locs = (type(Config.Locksmith) == 'table' and Config.Locksmith.locations) or {}
    local existing = locs[def.id] ~= nil
    if not AdminPerms.Has(src, existing and 'locksmith.edit' or 'locksmith.create') then return fail('no_permission') end

    MySQL.insert.await(
        'INSERT INTO `msk_vehiclekeys_locksmiths` (`id`, `label`, `data`, `enabled`) VALUES (?, ?, ?, 1) ' ..
        'ON DUPLICATE KEY UPDATE `label` = VALUES(`label`), `data` = VALUES(`data`)',
        { def.id, def.label, json.encode({ label = def.label, pedmodel = def.pedmodel, blip = def.blip, coords = def.coords }) }
    )
    AdminStore.LoadLocksmiths()
    AdminApi.Broadcast()
    return ok(src)
end)

MSK.Register('msk_vehiclekeys:admin:locksmith:delete', function(src, data)
    if not AdminPerms.Has(src, 'locksmith.delete') then return fail('no_permission') end
    local id = type(data) == 'table' and data.id or nil
    local locs = (type(Config.Locksmith) == 'table' and Config.Locksmith.locations) or {}
    if type(id) ~= 'string' or not locs[id] then return fail('not_found') end

    MySQL.query.await('DELETE FROM `msk_vehiclekeys_locksmiths` WHERE `id` = ?', { id })
    AdminStore.LoadLocksmiths()
    AdminApi.Broadcast()
    return ok(src)
end)

-- Access lists --------------------------------------------------
MSK.Register('msk_vehiclekeys:admin:lists:save', function(src, data)
    if not AdminPerms.Has(src, 'lists.manage') then return fail('no_permission') end
    if type(data) ~= 'table' or type(data.lists) ~= 'table' then return fail('bad_input') end

    local clean = AdminApi.SanitizeLists(data.lists)
    for k, v in pairs(clean) do
        setSetting(k, v)
    end
    AdminStore.LoadSettings()
    AdminApi.Broadcast()
    return ok(src)
end)

-- Settings ------------------------------------------------------
MSK.Register('msk_vehiclekeys:admin:settings:save', function(src, data)
    if not AdminPerms.Has(src, 'settings.manage') then return fail('no_permission') end
    if type(data) ~= 'table' or type(data.settings) ~= 'table' then return fail('bad_input') end

    local clean = AdminApi.SanitizeSettings(data.settings)
    for k, v in pairs(clean) do
        setSetting(k, v)
    end

    local oldCmd = Config.adminCommand
    AdminStore.LoadSettings()
    AdminStore.LoadLocksmiths() -- LoadSettings replaces Config.Locksmith -> restore locations
    if Config.adminCommand ~= oldCmd then AdminCommand.Register(Config.adminCommand) end
    AdminApi.Broadcast()
    return ok(src)
end)

-- Permissions ---------------------------------------------------
local function normGroup(name)
    if type(name) ~= 'string' then return nil end
    name = name:lower():gsub('^group%.', '')
    if not name:match(ID_PATTERN) then return nil end
    return name
end

MSK.Register('msk_vehiclekeys:admin:perms:saveGroup', function(src, data)
    if not AdminPerms.Has(src, 'permissions.manage') then return fail('no_permission') end
    local name = normGroup(type(data) == 'table' and data.name or nil)
    if not name then return fail('bad_name') end
    if AdminPerms.IsProtected(name) then return fail('protected') end
    if AdminPerms.IsBlacklisted(name) then return fail('blacklisted') end

    local matrix = {}
    local incoming = type(data) == 'table' and type(data.perms) == 'table' and data.perms or {}
    for _, key in ipairs(AdminPerms.PERMS) do
        matrix[key] = incoming[key] == true
    end

    MySQL.insert.await(
        'INSERT INTO `msk_vehiclekeys_permissions` (`group_name`, `perms`) VALUES (?, ?) ' ..
        'ON DUPLICATE KEY UPDATE `perms` = VALUES(`perms`)',
        { name, json.encode(matrix) }
    )
    AdminStore.LoadPermissions()
    AdminPerms.EnsureAces()
    AdminPerms.Invalidate()
    return ok(src)
end)

MSK.Register('msk_vehiclekeys:admin:perms:deleteGroup', function(src, data)
    if not AdminPerms.Has(src, 'permissions.manage') then return fail('no_permission') end
    local name = normGroup(type(data) == 'table' and data.name or nil)
    if not name then return fail('bad_name') end
    if AdminPerms.IsProtected(name) then return fail('protected') end

    MySQL.query.await('DELETE FROM `msk_vehiclekeys_permissions` WHERE `group_name` = ?', { name })
    AdminStore.LoadPermissions()
    AdminPerms.Invalidate()
    return ok(src)
end)

MSK.Register('msk_vehiclekeys:admin:perms:dashboardGroups', function(src, data)
    if not AdminPerms.Has(src, 'permissions.manage') then return fail('no_permission') end
    local list, seen = {}, {}
    if type(data) == 'table' and type(data.groups) == 'table' then
        for _, g in ipairs(data.groups) do
            local name = normGroup(g)
            if name and not AdminPerms.IsBlacklisted(name) and not AdminPerms.IsProtected(name) and not seen[name] then
                seen[name] = true
                list[#list + 1] = name
            end
        end
    end
    setSetting('dashboardGroups', list)
    AdminStore.LoadSettings()
    AdminPerms.EnsureAces()
    AdminPerms.Invalidate()
    return ok(src)
end)

MSK.Register('msk_vehiclekeys:admin:perms:validateGroup', function(src, data)
    if not AdminPerms.Has(src, 'permissions.manage') then return fail('no_permission') end
    local name = normGroup(type(data) == 'table' and data.name or nil)
    if not name then return { ok = true, valid = false } end
    if AdminPerms.IsBlacklisted(name) then return { ok = true, valid = false, blacklisted = true } end

    -- A group that was never used before has no `group.<name>` ace object yet, so
    -- the membership check below would come back empty for everyone. Register it
    -- first and give the command buffer a frame to catch up.
    AdminPerms.EnsureAce(name)
    Wait(0)

    local found = false
    for _, pid in ipairs(GetPlayers()) do
        if AdminPerms.PlayerInGroup(tonumber(pid), name) then found = true; break end
    end
    return { ok = true, valid = true, exists = found }
end)
