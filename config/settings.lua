Config = Config or {}

--[[============================================================
    DASHBOARD-MANAGED SETTINGS  (seed defaults only)

    Everything in THIS file is imported into the database on the
    very first start and is afterwards managed from the in-game
    admin dashboard (/advehiclekeys). The database is
    authoritative at runtime — editing values here only changes
    the defaults for a FRESH install (empty DB).

    Code hooks (Notification, TextUI adapters) that the dashboard
    and DB never touch live in `config/static.lua`.
============================================================]]--

----------------------------------------------------------------
Config.Locale = 'de'
Config.Debug = true
Config.VersionChecker = true
----------------------------------------------------------------
-- (Config.Framework lives in config/static.lua — it is auto-detected code
--  configuration, not a dashboard-managed setting.)
Config.Commands = {
    -- If you set to false then the Hotkey won't work !!!
    lock = {enable = true, command = 'lock'},
    keyMenu = {enable = true, command = 'keyMenu'},

    -- Command for Players to refresh the Owned Vehicles
    -- It will add not existing permanent keys to the player
    refreshKeys = {enable = true, command = 'refreshKeys'}
}

Config.VehicleTarget = {
    enable = true, -- (Un)lock a vehicle with a target system
    selectSeat = true, -- Select the seat you want to sit in

    -- Supported Target: ox_target
    -- You can add your own target in client/target.lua
    script = 'ox_target'
}

Config.Hotkeys = {
    lock = {enable = true, key = 'L'},
    keyMenu = {enable = true, key = 'U'},
}

-- This works with Ace Permissions (add_ace group.? command.? allow)
-- Admins can use the Hotkey to (un)lock a vehicle if it's added to Config.AdminVehicles below, otherwise use the AdminCommand
Config.AdminCommand = {
    enable = true, -- (Un)locks the vehicle if you don't have a key
    command = 'adlock',
    groups = {'superadmin', 'admin'}
}

-- Gives the key item to the player if the player does not have the item for the plate in his inventory
-- For realism, I recommend to set all options to false (keys will be refreshed internal anyway but the player won't get items)
Config.OnRefreshKeys = {
    OnPlayerLoaded = {
        primaryKeys = false, -- Recommended to set true if Config.GivePrimaryKey.givePrimaryKey or Config.GivePrimaryKey.transferOwnership is set to false
        secondaryKeys = false, -- For realism, I recommend to set to false
    },
    OnRefreshKeys = {
        primaryKeys = false, -- For realism, I recommend to set to false
        secondaryKeys = false, -- For realism, I recommend to set to false
    },
}
----------------------------------------------------------------
-- Config.GivePrimaryKey is for giving the primary key to another player
-- !!! ox_inventory and jaksam_inventory ONLY !!!
Config.GivePrimaryKey = {
    -- Please do NOT use all 4 options together!
    -- If you set giveSecondaryKey = true then the last 3 options will be ignored
    -- If you set givePrimaryKey = true then set giveSecondaryKey = false

    -- Use this option
    giveSecondaryKey = true, -- If a player gives his primary key to another player, the other player gets a secondary key

    -- Or use this options
    givePrimaryKey = false, -- If a player gives his primary key to another player, the other player gets the primary key
    removePrimaryKey = false, -- If a player gives his primary key to another player, the primary key of the player will be removed
    transferOwnership = false, -- If a player gives his primary key to another player, the other player is the owner of the vehicle

    -- If you set transferOwnership = true then the Primary Key will always be removed from the player
}

-- Config.KeyRingSystem is for a Keyring System to save all keys in a second inventory
-- ATTENTION: https://docu.msk-scripts.de/vehiclekeys/guides/installation#ox_inventory
-- !!! ox_inventory and jaksam_inventory ONLY !!!
Config.KeyRingSystem = {
    enable = true,
    addItem = true, -- Set false if you don't want that the item will be added to the players inventory on player joining if he has not already the item

    item = 'keyring', -- This item is needed to open the Keyring Inventory // Set the same name as in ox_inventory/data/items.lua
}
----------------------------------------------------------------
Config.Settings = {
    lockDistance = 8.0, -- maximum distance to lock/unlock a vehicle
    exchangeLocksPrice = 5000, -- Price for exchanging the Vehicle Locks
    transferVehicle = true, -- Allow transfer the vehicle to another player

    lockVehiclesFromNPCs = {
        enable = true, -- True NPC vehicles locked, set to false to unlock NPC vehicles.
        probability = 25 -- Probability whether a vehicle is open // Set to 0 then npc vehicles are always locked
    },

    menu = {
        showSecondaryKeys = true, -- Show Secondary Keys in Keys Menu
        showTempKeys = true, -- Show Temp Keys in Keys Menu
        showExchangeLocks = true, -- Show Exchange Vehicle Locks in Keys Menu
        showTransferVehicle = true, -- Show transfer vehicle to another player

        refreshPlayerKeys = true, -- Refresh Player Keys when opening the keys menu

        -- Supported Menus: nui (own UI), msk_context, msk_menu, ox_context, ox_menu
        -- You can add your own Menu in client/menu.lua
        keysMenu = 'msk_menu'
    },

    key = {
        -- ATTENTION: https://docu.msk-scripts.de/vehiclekeys/guides/installation
        needItem = true, -- Need an item to (un)lock the vehicle // With uniqueItems you always need the item
        canUseItem = true, -- Registers the Item as usable
        itemName = 'keys',

        -- Metadata-based inventories only.
        -- Supported inventories: ox_inventory, jaksam_inventory
        -- (uniqueItems is always treated as true for these inventories)
        uniqueItems = true,
        inventory = 'ox_inventory',
        itemLabel = 'Vehicle Key',
        plateLabel = 'Plate: %s',

        -- This option is for uniqueItems ONLY
        -- If set to true, the player with a key item can (un)lock the vehicle even though the player hasn't a key internal
        -- Example: Player A steals the vehicle key from Player B then Player A can (un)lock the vehicle
        toggleWithKey = true,

        -- Strict item enforcement for the vehicle OWNER (only relevant when needItem = true).
        -- false (default): the owner can (un)lock WITHOUT the key item in their inventory (lenient).
        -- true: the owner ALSO needs the key item to (un)lock (strict, no free lock/unlock without the item).
        ownerNeedsItem = true,
    },

    transfer = {
        -- If you use the Item then the Player and the Vehicle must be next to you!
        needItem = true, -- Need an item to transfer the vehicle
        canUseItem = true, -- Registers the Item as usable
        itemName = 'contract',
    },

    animation = {
        dict = "anim@mp_player_intmenu@key_fob@",
        anim = "fob_click_fp",
        prop = 'lr_prop_carkey_fob', -- spawn NAME (string); hashed at runtime in client/functions.lua
    },
}

-- This is for exchanging the vehicle locks
-- If you set enable = false then you can still use the exports.
-- The locksmith LOCATIONS are managed from the dashboard's Locksmith tab
-- (stored in msk_vehiclekeys_locksmiths). The seed values below are imported
-- into that table on the very first start only.
Config.Locksmith = {
    enable = true, -- Set to false to disable
    defaultTextUI = true, -- Set false to use the Config.openTextUI function in config/static.lua

    -- Supported Menus: nui (own UI), msk_context, msk_menu, ox_context, ox_menu
    -- You can add your own Menu in client/menu.lua
    menu = 'msk_context',

    targetSystem = {
        -- If you set this to true then you don't get a HelpNotify or TextUI
        enable = true, -- Set true to enable

        -- Supported Target: ox_target
        -- You can add your own target in client/menu.lua
        script = 'ox_target'
    },

    npcVoice = {
        enable = true,
        inRange = 5.0,
        outRange = 5.0
    },

    -- Seed locations (imported into msk_vehiclekeys_locksmiths on first start).
    -- pedmodel is a spawn NAME (string); it is hashed at runtime in client/main.lua.
    locations = {
        ['locksmith'] = {
            label = 'Locksmith Service',
            pedmodel = 's_m_m_autoshop_01',
            blip = {enable = true, label = 'Locksmith Service', id = 134, scale = 1.0, color = 0},
            coords = {
                vector4(170.02, -1799.55, 29.32, 318.5),
            }
        },
        ['lsc'] = {
            label = 'Locksmith Service',
            pedmodel = 's_m_m_autoshop_01',
            blip = {enable = true, label = 'Locksmith Service', id = 134, scale = 1.0, color = 0},
            coords = {
                vector4(-354.61, -128.18, 38.43, 70.2),
            }
        },
        ['benny'] = {
            label = 'Locksmith Service',
            pedmodel = 's_m_m_autoshop_01',
            blip = {enable = true, label = 'Locksmith Service', id = 134, scale = 1.0, color = 0},
            coords = {
                vector4(-190.45, -1309.27, 31.3, 357.8),
            }
        },
    }
}
----------------------------------------------------------------
-- Whitelist specific models and plates for which you don't need a key to (un)lock
-- Models are spawn NAMES (strings). They are hashed at runtime for comparison.
Config.Whitelist = {
    models = {
        'caddy', 'caddy2', 'caddy3', 'airtug', 'docktug', 'forklift', 'mower', 'tractor2',
    },
    plates = {
        -- either exact plates or just a string that should be in the vehicles plate e.g. "ESX" will ignore "12ESX34" too
        "TEST",
    }
}

-- Blacklist specific models and plates so that they cannot be (un)locked
Config.Blacklist = {
    models = {
        'bmx', 'cruiser', 'fixter', 'scorcher', 'tribike', 'tribike2', 'tribike3',
    },
    plates = {
        -- either exact plates or just a string that should be in the vehicles plate e.g. "ESX" will ignore "12ESX34" too
        "TEST2",
    }
}

-- Only groups that are configured in Config.AdminCommand are allowed to (un)lock this vehicles
Config.AdminVehicles = {
    models = {

    },
    plates = {
        -- either exact plates or just a string that should be in the vehicles plate e.g. "ESX" will ignore "12ESX34" too
        "ADMINCAR",
    }
}
----------------------------------------------------------------
-- Players with specific jobs can (un)lock the vehicle with specific plates or if it is a specific model
-- Models are spawn NAMES (strings). Plates: either exact plates or a substring e.g. "ESX" matches "12ESX34".
Config.JobVehicles = {
    ['police'] = {
        models = {
            'police', 'police2', 'police3', 'police4', 'policeb', 'polmav',
        },
        plates = {
            "LSPD", "POL",
        },
        ranks = {
            ['officer'] = {
                models = {
                    'police',
                },
                plates = {
                    "",
                }
            },
        }
    },
    ['ambulance'] = {
        models = {
            'ambulance',
        },
        plates = {
            "LSMD", "AMB",
        }
    },
}
----------------------------------------------------------------
-- In-Game Admin Dashboard
Config.adminCommand = 'advehiclekeys' -- command that opens the admin dashboard (separate from Config.AdminCommand / adlock)
Config.dashboardGroups = { 'mod' }       -- ACE groups (besides 'admin') allowed to open it; 'user' is always denied
-- Groups work with a plain `add_principal identifier.license:xxx group.admin` in
-- your server.cfg. The matching ace objects are created on start through msk_core,
-- so your server.cfg needs the msk_core ace lines (they are in the msk_core docs):
--
--     add_ace resource.msk_core command.add_ace allow
--     add_ace resource.msk_core command.remove_ace allow
--     add_ace resource.msk_core command.add_principal allow
--     add_ace resource.msk_core command.remove_principal allow
--
-- Without them the script says so on start and group access falls back to your
-- framework group (ESX users table / QBCore permissions) and luxu_admin.
--
-- Framework notes:
--   ESX / Qbox : principals are named group.<name> (group.admin, group.mod, ...)
--   QBCore     : principals are named qbcore.<name>, and the staff levels are
--                'god', 'admin' and 'mod'. Both spellings are accepted, so a
--                player set up with /addpermission or `add_principal player.X
--                qbcore.mod` is recognised as group 'mod' here.
-- The ESX group from the users table, QBCore's own permission list and
-- luxu_admin staff groups are picked up as well.
Config.BrandTag = 'MSK'                   -- short badge shown next to the dashboard title (empty = hidden)

-- UI colours (hex). Managed from the dashboard's Settings tab and applied live to
-- the dashboard NUI. Derived shades are computed in the UI (see web/src/lib/theme.ts)
-- — only these 5 brand colours are configurable.
Config.Theme = {
    accent = '#00E676',        -- MSK green accent
    bg = '#0a0b0d',            -- window background
    panel = '#131317',         -- panel surface
    textPrimary = '#f0ede8',   -- primary text
    textSecondary = '#b0adb8', -- secondary text
}
