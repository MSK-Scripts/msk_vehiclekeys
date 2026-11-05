# Changelogs

## v3.4.1

### Requires msk_core 4.1.0

Uses the table forms that msk_core 4.1.0 introduced, so the deprecation warnings in the server console are gone. The notifications are sent as a table, which an older msk_core takes as the title. Update msk_core along with this script.

### Added

- **The msk_core version is checked on start.** `MSK.Check.Dependency('msk_core', '4.1.0', true)` logs an error in the server console when msk_core is older, instead of leaving you to wonder why the notifications look wrong. *(server/versionchecker.lua)*

### Changed

- **`Config.Notification` passes a table to `MSK.Notification`.** The form with title, message, type and duration is deprecated since msk_core 4.1.0 and logs a warning once per resource. If you keep your own config, change the two `MSK.Notification` lines the same way. Leaving them works too, the old form is still accepted for now. *(config/static.lua)*

- **`Config.openTextUI` passes a table to `MSK.TextUI.Show`.** The form with key, text and color is deprecated since msk_core 4.1.0. *(config/static.lua)*

### Changed files

```text
fxmanifest.lua
config/static.lua
server/versionchecker.lua
```

## v3.4.0

### Requires msk_core 4.0.0

Every framework call in this resource goes through the rewritten bridge. On
msk_core 3.x the player object arrives without its methods and nothing works.
Update msk_core along with this script.

### Security

- **Money could be created out of nothing when selling a vehicle.** Both
  framework branches credited the seller **before** taking the money from the
  buyer. A deduction that failed for any reason left the seller paid and the
  buyer's balance untouched. The money is taken first now, and only a successful
  deduction credits the seller. `RemoveMoney` refuses on an insufficient balance
  and says so, so the deduction itself decides instead of the check in front of
  it.

### Added

- **Qbox support.** Qbox uses the same `player_vehicles` and `players` layout as
  QBCore, verified against `qbx_core.sql` and `qbx_vehicles/vehicles.sql`.

### Fixed

- **Nothing was ever set up for a player on ESX.** The keyring item and the
  conversion of the old storage method hung on `esx:playerLoaded` on the server
  and on the two QBCore client events. msk_core turns every framework's own load
  event into `msk_core:playerLoaded`, which is what the resource listens to now,
  on all three frameworks.

- **The load and logout handlers were net events.** Server side those events are
  local, and as net events any client could fire them with an arbitrary player
  id. They are `AddEventHandler` now.

- **The job rank was read under two different names.** `grade_name` on ESX,
  `grade.name` on QBCore, and neither existed on Qbox. It is `gradeName`
  everywhere now.

- **`GetPlayerVehicles` returned an empty list, and offline players showed up as
  their raw identifier in the dashboard.** Both branched on `Config.Framework`,
  which msk_core detects now, so the value stayed at `'AUTO'` and every branch
  was skipped. They ask `MSK.Bridge.Framework.Type` instead and cover Qbox with
  the same path as QBCore. A vehicle row with unreadable property JSON no longer
  takes `GetPlayerVehicles` down either.

### Changed

- **`Config.Framework` in `config/static.lua` is no longer read.** The line stays
  so an existing config does not break, but changing it has no effect. Pin the
  framework in msk_core's `config.lua` instead.

- **Framework detection is gone from this resource.** It sat at the top of
  `client/main.lua` and `server/main.lua`, knew only ESX and QBCore, and msk_core
  has already detected the framework when those files load. The tables are still
  resolved per framework, because that is what actually differs.

- **The client no longer keeps its own copy of the player data.**
  `client/main.lua` mirrored `esx:setPlayerData`, `esx:setJob` and
  `QBCore:Player:SetPlayerData` into a local table that nothing else in the
  resource read. msk_core keeps that copy itself, use `MSK.GetPlayerData()`.

- Usable items are registered through `MSK.RegisterItem`, which covers ESX,
  QBCore and Qbox in one call.

- The player helpers (`GetPlayerFromId`, `GetPlayerFromIdentifier`,
  `GetPlayerSource`, `GetPlayerIdentifier`, `GetPlayerJob`) keep their names,
  because the rest of the resource calls them, but each is one line now instead
  of one branch per framework.

### Changed files

```text
fxmanifest.lua
config/static.lua
client/main.lua
client/encrypted.lua
server/main.lua
server/functions.lua
server/storage.lua
server/admin/api.lua
server/admin/permissions.lua
```

## v3.3.3

### Fixed

- **QBCore and Qbox: your staff could not open the admin dashboard, even though the permissions in your server.cfg were correct.** The frameworks do not agree on how a group principal is named. ESX and Qbox use `group.admin`, QBCore uses `qbcore.admin`, and that is not a detail you can configure away: `/addpermission` and `QBCore.Functions.AddPermission` write exactly that. QBCore also only ever links `qbcore.god` to `group.admin`, so anyone below god level was a member of no `group.*` principal at all and the dashboard check came back empty for them. On ESX this stayed invisible, because there the group from the `users` table caught it, and that fallback does not exist on QBCore. The script now registers its own ace object per group and points both spellings at it, so `add_principal identifier.license:xxx group.mod` and `/addpermission 1 mod` both get you in. Nothing changes for ESX servers.
- **`/adlock` was dead on QBCore for the same reason.** The command was only granted to `group.<name>`, which a QBCore admin never holds. Both spellings are granted now.
- **`Access denied for command add_ace` spam on every server start.** FiveM checks `add_ace` against the resource that runs it, and no resource holds that right by default. So the ace objects introduced in v3.3.2 were never actually created, every attempt was refused and only printed an error. On ESX this went unnoticed because the framework group caught it. The aces are now registered through msk_core, which is the one resource your server.cfg already grants that right, and the script checks up front whether it is allowed instead of spamming the console.

### Requires msk_core 3.3.0

This release uses `MSK.AddRawAce` and `MSK.CanAddAce`, both added in msk_core 3.3.0. Update msk_core along with this script.

Your `server.cfg` needs the msk_core ace lines, which are the ones the msk_core documentation has always listed:

```cfg
add_ace resource.msk_core command.add_ace allow
add_ace resource.msk_core command.remove_ace allow
add_ace resource.msk_core command.add_principal allow
add_ace resource.msk_core command.remove_principal allow
```

Those are what let the script create its ace objects, which is what makes a plain `add_principal ... group.mod` work without you writing any further ace lines by hand. One set of lines covers every MSK script.

If they are missing nothing breaks, the script says so on start and group access falls back to your framework group (ESX `users` table, QBCore permission list) and luxu_admin.

There is nothing to rebuild and no database change. Replace the resource files and restart it.

### Changed files

- `fxmanifest.lua` (version bump)
- `server/admin/permissions.lua` (own ace object per group, both principal spellings, QBCore permission fallback, extended debug output)
- `server/main.lua` (grants the adlock command to both spellings)
- `server/admin/boot.lua` (corrected the command name in the startup message)
- `server/admin/command.lua` (corrected the fallback command name, only ever used when `Config.adminCommand` is missing)
- `config/settings.lua` (note on how the frameworks name their groups)
- `web/src/admin/devMock.ts` (browser dev mock only, not part of the build)

## v3.3.2

### Fixed

- **Admins with `group.admin` could not open the dashboard.** FiveM keeps principals and ace objects apart. A line like `add_principal identifier.license:xxx group.admin` in your server.cfg only makes that player a member of the group, it does not give them the ace object of the same name. The dashboard checked for that ace object, so unless someone had also written `add_ace group.admin group.admin allow` by hand, the check came back empty and the player was turned away. It worked on some servers by accident, because there the ESX or QBCore group in the users table happened to be `admin` as well and the framework fallback caught it. The script now creates those ace objects itself on start, for `admin`, for every group in `Config.dashboardGroups` and for every group in the permission matrix. So a plain `add_principal` in your server.cfg is enough, exactly like you would expect. New groups you add from the Permissions tab are covered right away, no restart needed.
- **Checking a group name in the Permissions tab reported "not found" for brand new groups.** The check ran before the group existed as an ace object, so it could never find anyone in it. The group is registered first now.

There is nothing to rebuild and no database change. Replace the resource files and restart it.

If you cannot update right now, this one line in your server.cfg has the same effect for `group.admin`:

```cfg
add_ace group.admin group.admin allow
```

### Changed files

- `fxmanifest.lua` (version bump)
- `server/admin/permissions.lua` (registers the `group.<name>` ace objects, plus a debug output that tells you why a player was denied when `Config.Debug` is on)
- `server/admin/boot.lua` (registers the ace objects on start)
- `server/admin/api.lua` (covers groups added or changed while the server is running)
- `server/admin/command.lua` (comment only)
- `config/settings.lua` (note about `add_principal` being enough)

## v3.3.1

### Fixed

- **The dashboard fell back to German for any language it did not have its own translation for.** Picking a language in the Settings tab that only exists in `translation.lua` (Hungarian) silently rendered the whole dashboard UI in German instead of the picked language, even though the in-game texts (notifications, key menu) already used it correctly. The dashboard now ships a full Hungarian translation, so picking Hungarian actually shows Hungarian everywhere.

The NUI ships prebuilt, so there is nothing to build on your side. Just replace the resource files as usual, the server needs no npm.

### Changed files

- `fxmanifest.lua` (version bump)
- `web/package.json` (version bump)
- `web/src/admin/i18n.ts` (added the Hungarian dashboard translation)
- `html/**` (rebuilt NUI, replaces the old assets, the server needs no npm)

## v3.3.0

### New

- **The Context Menu and the Menu from msk_core are now supported.** Both menu dropdowns got two new entries, `msk_context` (mouse driven, with drilldown and back arrow) and `msk_menu` (keyboard driven in the NativeUI style, so you can keep walking or driving while it is open). They behave exactly like the ox variants, the same key categories, the same actions, and everything still runs through the same functions under the hood. This needs msk_core v3.0.0 or newer.

### Changed

- **New defaults.** The keys menu (`/keyMenu`) now uses `msk_menu` and the locksmith uses `msk_context`. `nui`, `ox_context` and `ox_menu` are all still available, you can switch any time in the dashboard Settings tab. Since the settings live in the database, an existing installation keeps whatever it had, only a fresh install picks up the new defaults.

### Fixed

- **Hungarian was missing from the language dropdown.** The dashboard language picker only listed German and English, so Hungarian could not be selected even though the translation was already shipped in `translation.lua`. The dropdown is now built from the languages that actually exist in `translation.lua`, so every translated language shows up on its own. Adding a new language block there is enough, there is no second list to keep in sync anymore.
- **The server dropped any language other than German or English on save.** Even with Hungarian visible in the dropdown, saving it would have been rejected server side, because the save validation only allowed `de` and `en`. The server now accepts any language that `translation.lua` provides.

The dashboard interface itself is available in German and English. If you pick a language the interface does not translate yet (like Hungarian), the dashboard falls back to German while the in-game texts (notifications, key menu) use the language you picked.

### Changed files

- `fxmanifest.lua` (version bump)
- `client/menu.lua` (`msk_context` and `msk_menu` branches for both menus, shared action list extracted)
- `config/settings.lua` (keysMenu defaults to `msk_menu`, Locksmith menu defaults to `msk_context`)
- `shared/admin_perms.lua` (`msk_context` and `msk_menu` added to the selectable menus)
- `server/admin/api.lua` (language validation and the dropdown list are derived from `translation.lua`)
- `web/src/admin/types.ts` (bootstrap carries the available languages)
- `web/src/admin/i18n.ts` (language display names, unknown codes fall back to the uppercased code)
- `web/src/admin/AdminApp.tsx` (passes the languages into the Settings tab)
- `web/src/admin/SettingsTab.tsx` (language dropdown is rendered from the server list)
- `web/src/admin/defaults.ts` (new menu defaults)
- `web/src/admin/devMock.ts` (dev mock exposes the languages and the new menus)
- `web/package.json` (version bump)
- `html/**` (rebuilt NUI, replaces the old assets, the server needs no npm)

## v3.2.0

### New

- **Own UI for the keys menu and the locksmith.** The `/keyMenu` and the locksmith menu no longer run on ox_context or ox_menu, they run on their own NUI in the MSK style. The flow stays the same as before, you pick a key category, then one of your vehicles, then the action (give secondary key, exchange locks, transfer vehicle). The locksmith shows your vehicles as a list and exchanges the locks on the one you pick. Everything the menu does still goes through the same functions as before, so the behavior is identical, only the look changed. The back arrow and Escape go one step up, the X closes it.

### Changed

- **`nui` is the new default.** `Config.Settings.menu.keysMenu` and `Config.Locksmith.menu` are set to `'nui'` now. ox_context and ox_menu are still there as a fallback, and a new `nui` option was added to both menu dropdowns in the dashboard Settings tab, so you can switch back and forth live without touching the config.

### Changed files

- `fxmanifest.lua` (version bump, new client file registered)
- `config/settings.lua` (keysMenu and Locksmith menu default to `nui`)
- `shared/admin_perms.lua` (`nui` added to the selectable menus)
- `client/menu.lua` (`nui` branch for both menus, shared key actions extracted)
- `client/nui.lua` (new, the NUI open/close focus and the callbacks)
- `client/admin/main.lua` (focus reset now covers the new player UI too)
- `html/**` (rebuilt NUI, replaces the old assets, the server needs no npm)

## v3.1.1

### Fixed

- Key hand-outs were broken since v3.0 for garage and shop integrations that give you a key through the client exports. Taking your own vehicle out of the garage would say "This vehicle doesn't belong to you!" and give no key. Two separate things were behind it.
- First, the check that guards giving out a key also demanded that the owner was already carrying the key item. That item rule belongs to locking and unlocking, not to receiving a key, so an owner taking their car out of the garage with no key yet got rejected and could never get the first one. Giving yourself a key for a car you own no longer needs you to already hold the item.
- Second, when a key was already saved in the database but the item was missing from the inventory, the script stopped early and gave nothing back. It now notices the missing item and hands it back, the same way the force refresh does.
- On top of that the owner check trims the plate before matching, so plates saved with extra spaces (ESX default) are recognised, and giving yourself a key keeps the type you asked for, primary included. Sharing a key with another nearby player stays limited to secondary and temporary keys.

This is a server-side fix, so there is nothing to rebuild. On the client exports, primary and secondary keys can be added when the player owns the vehicle or already holds a key for it, while temporary keys can be added for any vehicle since they are removed again on reconnect. Server scripts can always hand out keys through the server export `exports.msk_vehiclekeys:AddKey(...)`, which is not restricted.

## v3.1.0

### New

- **luxu_admin support.** The admin dashboard now works with luxu_admin out of the box. luxu_admin keeps its staff groups internally instead of using FiveM ace permissions, so the dashboard reads a player's staff group straight from luxu_admin and matches it to your dashboard groups by name. A luxu group called `admin` gets full access, and any other group works like a normal dashboard group. You can turn it on or off, require staff to be on duty, and map luxu group names to your own groups in `config/static.lua` (`Config.LuxuAdmin`). It is auto-detected, so it stays off when luxu_admin is not running.

## v3.0.0

This is a big one. VehicleKeys now comes with its own in-game admin dashboard, and most of the config moves into the database so you can manage everything while the server is running.

### New

- **Admin dashboard.** Type `/advehiclekeys` in-game to open it. From there you can hand out or take keys, look up who owns a plate and who is carrying a key for it, set up locksmiths, edit your whitelist, blacklist and job vehicles, change the settings and decide who else is allowed in. You can rename the command with `Config.adminCommand`.
- **Permission system.** You can give your team access to the dashboard without handing them the keys to everything. Every group gets its own set of rights. `group.admin` can always do it all and `group.user` can never get in. You manage the groups from the Permissions tab, and `Config.dashboardGroups` decides which groups may open the dashboard at all.
- **Force refresh.** On the Players tab you get a normal refresh and a force refresh. The force one gives the player every missing key item back, even if you normally keep item handouts turned off for realism.
- **Owner needs item (optional).** New option `Config.Settings.key.ownerNeedsItem`. Turn it on if you want the vehicle owner to carry the key item as well. It is off by default, so your current setup does not change unless you enable it.
- **Theme editor.** You can recolor the dashboard live from the Settings tab.

### Changed

- **Everything runs off the database now.** The config is imported once on the first start, and after that the database is the source of truth and you edit things from the dashboard. Three tables are created automatically for this: `msk_vehiclekeys_settings`, `msk_vehiclekeys_permissions` and `msk_vehiclekeys_locksmiths`. Your existing `msk_vehiclekeys_keys` table stays exactly as it is.
- **Config was split into two files.** `config/settings.lua` holds all the values you can also change in the dashboard, and `config/static.lua` holds the code parts like the framework detection, the notification and the TextUI. `Config.Framework` moved into `config/static.lua`.
- **Vehicle models are written as names now.** In the whitelist, blacklist, admin vehicles and job vehicles you can just write the spawn name like `'police'` instead of a hash. Old hash entries still work, so you do not have to change anything if you do not want to.
- **Locksmiths are managed from the dashboard.** The spots in the config are only the starting point. After that you add, edit and delete them from the Locksmith tab, and the peds and blips update right away without a restart.

### Security

- Closed a few holes where players could mess with keys they should not touch. Giving out a key, taking a key, exchanging locks and transferring a vehicle now check that you actually own the car and that the other player is standing next to you. The lookups that used to leak other players' keys were tightened as well.

### Breaking

- `config.lua` is gone and replaced by the `config/` folder. Please give your config a quick look after updating and move any custom values over to `config/settings.lua` (or `config/static.lua` for the code parts).
- Vehicle models in the lists are spawn names now. Your old backtick hashes keep working, so this only matters if you want the cleaner look.
