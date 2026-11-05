# Graph Report - msk_vehiclekeys  (2026-08-01)

## Corpus Check
- 54 files · ~41,835 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 409 nodes · 682 edges · 38 communities (37 shown, 1 thin omitted)
- Extraction: 95% EXTRACTED · 4% INFERRED · 0% AMBIGUOUS · INFERRED: 30 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `e7ccbd13`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Admin Dashboard UI
- Admin Server API
- Player Keys & Locksmith NUI
- Release History & Concepts
- Dashboard Types & Dev Mock
- TypeScript Build Config
- NUI Runtime Dependencies
- Dashboard Access Control
- Seeding & Permission Constants
- Client Keys NUI Bridge
- Settings & Locksmith Store
- Locksmith Peds & Blips Sync
- Keyring Item Artwork
- Key Menu Actions
- Keyring Icon Variant
- NUI Error Boundary
- NUI Entry Documents
- Key Item Artwork

## God Nodes (most connected - your core abstractions)
1. `compilerOptions` - 16 edges
2. `errText()` - 13 edges
3. `fetchNui()` - 13 edges
4. `tbl()` - 12 edges
5. `AdminApi.SanitizeSettings()` - 12 edges
6. `applyTheme()` - 11 edges
7. `AdminApi.BuildBootstrap()` - 10 edges
8. `Changelogs` - 9 edges
9. `AdminPerms.PlayerInGroup()` - 8 edges
10. `AdminPerms.GetPlayerPerms()` - 8 edges

## Surprising Connections (you probably didn't know these)
- `React Entry Module /src/main.tsx` --semantically_similar_to--> `Hashed Vite Bundle Assets (index-COono7V2.js, index-CyP7xmgF.css)`  [INFERRED] [semantically similar]
  web/index.html → html/index.html
- `AdminApi.GroupsArray()` --calls--> `AdminPerms.AllPerms()`  [INFERRED]
  server/admin/api.lua → shared/admin_perms.lua
- `AdminSeed.Run()` --calls--> `AdminPerms.AllPerms()`  [INFERRED]
  server/admin/seed.lua → shared/admin_perms.lua
- `AdminPerms.EnsureAce()` --calls--> `AdminPerms.IsBlacklisted()`  [INFERRED]
  server/admin/permissions.lua → shared/admin_perms.lua
- `AdminPerms.GetPlayerPerms()` --calls--> `AdminPerms.AllPerms()`  [INFERRED]
  server/admin/permissions.lua → shared/admin_perms.lua

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Dashboard Access Resolution (ace objects, principals, config groups, framework and luxu fallbacks)** — changelogs_permission_system, changelogs_ace_object_auto_registration, changelogs_principal_vs_ace_distinction, changelogs_config_dashboardgroups, changelogs_group_admin, changelogs_framework_group_fallback, changelogs_luxu_admin_support [EXTRACTED 1.00]
- **Selectable Menu Backends for Keys Menu and Locksmith** — changelogs_menu_backend_abstraction, changelogs_nui_menu_backend, changelogs_msk_context_menu, changelogs_msk_menu, changelogs_keys_menu, changelogs_locksmith [EXTRACTED 1.00]
- **Language Pipeline from translation.lua to Dashboard Dropdown and Save Validation** — changelogs_translation_lua, changelogs_dashboard_i18n, changelogs_hungarian_translation, changelogs_language_save_validation [EXTRACTED 1.00]
- **React/Vite NUI Build Pipeline from web/ to committed html/** — web_index_app_root, web_index_main_tsx_entry, html_index_app_root, html_index_bundled_assets [INFERRED 0.95]

## Communities (38 total, 1 thin omitted)

### Community 0 - "Admin Dashboard UI"
Cohesion: 0.05
Nodes (73): TabId, deepMerge(), DEFAULT_SETTINGS, isPlainObject(), AdminLocale, AdminStrings, de, en (+65 more)

### Community 1 - "Admin Server API"
Cohesion: 0.09
Nodes (39): AdminApi.Broadcast(), AdminApi.BuildBootstrap(), AdminApi.GroupsArray(), AdminApi.JobsList(), AdminApi.LocalesArray(), AdminApi.LocksmithsArray(), AdminApi.OnlinePlayers(), AdminApi.PlateLookup() (+31 more)

### Community 2 - "Player Keys & Locksmith NUI"
Cohesion: 0.09
Nodes (37): AdminApp(), allPerms, bootstrap, keysPayload, keyStrings, locksmithPayload, samplePlate, samplePlayer (+29 more)

### Community 3 - "Release History & Concepts"
Cohesion: 0.09
Nodes (33): Automatic group.<name> Ace Object Registration, exports.msk_vehiclekeys:AddKey (server export), In-Game Admin Dashboard (/advehiclekeys), Config.dashboardGroups, Config Split: settings.lua vs static.lua, Dashboard Translation / i18n, Database as Source of Truth (config seeded once), msk_vehiclekeys_* Database Tables (+25 more)

### Community 4 - "Dashboard Types & Dev Mock"
Cohesion: 0.07
Nodes (28): Breaking, Changed, Changed, Changed, Changed files, Changed files, Changed files, Changed files (+20 more)

### Community 5 - "TypeScript Build Config"
Cohesion: 0.09
Nodes (21): DOM, DOM.Iterable, ES2020, src, compilerOptions, allowImportingTsExtensions, isolatedModules, jsx (+13 more)

### Community 6 - "NUI Runtime Dependencies"
Cohesion: 0.05
Nodes (36): autoprefixer, @fontsource/open-sans, @fontsource/work-sans, lucide-react, postcss, react, react-dom, tailwindcss (+28 more)

### Community 8 - "Dashboard Access Control"
Cohesion: 0.22
Nodes (14): AdminCommand.Register(), AdminPerms.CanOpen(), AdminPerms.EnsureAce(), AdminPerms.EnsureAces(), AdminPerms.GetFrameworkGroup(), AdminPerms.GetLuxuGroup(), AdminPerms.GetPlayerPerms(), AdminPerms.GetQbPermission() (+6 more)

### Community 9 - "Seeding & Permission Constants"
Cohesion: 0.46
Nodes (7): AdminSeed.Run(), coordList(), isSeeded(), locksmithForStorage(), locksmithSettings(), setSetting(), vecToTable()

### Community 10 - "Client Keys NUI Bridge"
Cohesion: 0.46
Nodes (7): canOpen(), CloseKeysNui(), keyFlags(), keyStrings(), OpenKeysNui(), OpenLocksmithNui(), runAction()

### Community 11 - "Settings & Locksmith Store"
Cohesion: 0.62
Nodes (6): AdminStore.LoadAll(), AdminStore.LoadLocksmiths(), AdminStore.LoadPermissions(), AdminStore.LoadSettings(), isEnabled(), jdecode()

### Community 12 - "Locksmith Peds & Blips Sync"
Cohesion: 0.47
Nodes (4): applyDefs(), buildBlips(), deletePed(), RebuildLocksmiths()

### Community 13 - "Keyring Item Artwork"
Cohesion: 0.47
Nodes (6): Inventory Item Asset (transparent PNG), Keyring Inventory Icon, Keyring Item, Multiple Vehicle Keys Held Together, Photorealistic Icon Style, Vehicle Key Fob (Remote)

### Community 14 - "Key Menu Actions"
Cohesion: 0.70
Nodes (4): actionsContext(), buildKeyActions(), keyList(), showTypeMenu()

### Community 15 - "Keyring Icon Variant"
Cohesion: 0.60
Nodes (5): Car Key Fob With Remote Buttons, Comic Style Icon On Transparent Background, Keyring 2 Inventory Icon, Keyring Inventory Item, MSK Vehiclekeys Script

### Community 18 - "NUI Entry Documents"
Cohesion: 0.67
Nodes (4): Built NUI Entry Document (html/index.html), Hashed Vite Bundle Assets (index-COono7V2.js, index-CyP7xmgF.css), Vite Dev Entry Document (web/index.html), React Entry Module /src/main.tsx

### Community 19 - "Key Item Artwork"
Cohesion: 0.67
Nodes (4): Car Key With Remote Fob Illustration, Inventory Images Asset Folder, Keys Inventory Item Icon, Vehicle Key Inventory Item

## Ambiguous Edges - Review These
- `Inventory Item Asset (transparent PNG)` → `Multiple Vehicle Keys Held Together`  [AMBIGUOUS]
  inventory_images/keyring.png · relation: semantically_similar_to
- `Keyring 2 Inventory Icon` → `MSK Vehiclekeys Script`  [AMBIGUOUS]
  inventory_images/keyring2.png · relation: semantically_similar_to

## Knowledge Gaps
- **110 isolated node(s):** `name`, `private`, `version`, `type`, `dev` (+105 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **1 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `Inventory Item Asset (transparent PNG)` and `Multiple Vehicle Keys Held Together`?**
  _Edge tagged AMBIGUOUS (relation: semantically_similar_to) - confidence is low._
- **What is the exact relationship between `Keyring 2 Inventory Icon` and `MSK Vehiclekeys Script`?**
  _Edge tagged AMBIGUOUS (relation: semantically_similar_to) - confidence is low._
- **Why does `AdminApi.BuildBootstrap()` connect `Admin Server API` to `Dashboard Access Control`?**
  _High betweenness centrality (0.007) - this node is a cross-community bridge._
- **Why does `AdminPerms.AllPerms()` connect `Dashboard Access Control` to `Admin Server API`, `Seeding & Permission Constants`?**
  _High betweenness centrality (0.007) - this node is a cross-community bridge._
- **Why does `AdminPerms.GetPlayerPerms()` connect `Dashboard Access Control` to `Admin Server API`?**
  _High betweenness centrality (0.007) - this node is a cross-community bridge._
- **What connects `name`, `private`, `version` to the rest of the system?**
  _110 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Admin Dashboard UI` be split into smaller, more focused modules?**
  _Cohesion score 0.053194333066025126 - nodes in this community are weakly interconnected._