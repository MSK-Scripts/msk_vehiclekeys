// Browser-only dev mock. Loaded exclusively via `import.meta.env.DEV` in main.tsx
// so it never ships in the production build. Answers fetchNui dev-calls and posts
// an initial openAdmin message so the dashboard renders in `npm run dev`.
import { DEFAULT_THEME } from '../lib/theme'
import type { AdminBootstrap, PlateDetail, PlayerDetail, SettingsPayload } from './types'
import type { KeysPayload, LocksmithPayload } from '../keys/types'

const allPerms: Record<string, boolean> = {
  'keys.view': true, 'keys.manage': true,
  'vehicles.view': true, 'vehicles.manage': true,
  'locksmith.view': true, 'locksmith.create': true, 'locksmith.edit': true, 'locksmith.delete': true,
  'lists.manage': true, 'settings.manage': true, 'permissions.manage': true,
}

let bootstrap: AdminBootstrap = {
  locale: 'de',
  perms: allPerms,
  permKeys: Object.keys(allPerms),
  settings: {
    Locale: 'de',
    Debug: true,
    VersionChecker: true,
    Commands: { lock: { enable: true, command: 'lock' }, keyMenu: { enable: true, command: 'keyMenu' }, refreshKeys: { enable: true, command: 'refreshKeys' } },
    Hotkeys: { lock: { enable: true, key: 'L' }, keyMenu: { enable: true, key: 'U' } },
    VehicleTarget: { enable: true, selectSeat: true, script: 'ox_target' },
    AdminCommand: { enable: true, command: 'adlock', groups: ['superadmin', 'admin'] },
    OnRefreshKeys: { OnPlayerLoaded: { primaryKeys: false, secondaryKeys: false }, OnRefreshKeys: { primaryKeys: false, secondaryKeys: false } },
    GivePrimaryKey: { giveSecondaryKey: true, givePrimaryKey: false, removePrimaryKey: false, transferOwnership: false },
    KeyRingSystem: { enable: true, addItem: true, item: 'keyring' },
    Settings: {
      lockDistance: 8.0,
      exchangeLocksPrice: 5000,
      transferVehicle: true,
      lockVehiclesFromNPCs: { enable: true, probability: 25 },
      menu: { showSecondaryKeys: true, showTempKeys: true, showExchangeLocks: true, showTransferVehicle: true, refreshPlayerKeys: true, keysMenu: 'msk_menu' },
      key: { needItem: true, canUseItem: true, itemName: 'keys', uniqueItems: true, inventory: 'ox_inventory', itemLabel: 'Vehicle Key', plateLabel: 'Plate: %s', toggleWithKey: true, ownerNeedsItem: false },
      transfer: { needItem: true, canUseItem: true, itemName: 'contract' },
      animation: { dict: 'anim@mp_player_intmenu@key_fob@', anim: 'fob_click_fp', prop: 'lr_prop_carkey_fob' },
    },
    Locksmith: {
      enable: true,
      defaultTextUI: true,
      menu: 'msk_context',
      targetSystem: { enable: true, script: 'ox_target' },
      npcVoice: { enable: true, inRange: 5.0, outRange: 5.0 },
    },
    Whitelist: { models: ['caddy', 'airtug'], plates: ['TEST'] },
    Blacklist: { models: ['bmx'], plates: ['TEST2'] },
    AdminVehicles: { models: [], plates: ['ADMINCAR'] },
    JobVehicles: {
      police: { models: ['police', 'police2'], plates: ['LSPD', 'POL'], ranks: { officer: { models: ['police'], plates: [''] } } },
      ambulance: { models: ['ambulance'], plates: ['LSMD', 'AMB'] },
    },
    adminCommand: 'advehiclekeys',
    BrandTag: 'MSK',
    Theme: DEFAULT_THEME,
    dashboardGroups: ['mod'],
  },
  locksmiths: [
    { id: 'locksmith', label: 'Locksmith Service', pedmodel: 's_m_m_autoshop_01', blip: { enable: true, label: 'Locksmith Service', id: 134, scale: 1.0, color: 0 }, coords: [{ x: 170.02, y: -1799.55, z: 29.32, w: 318.5 }] },
  ],
  groups: [
    { name: 'admin', protected: true, perms: allPerms },
    { name: 'mod', protected: false, perms: { 'keys.view': true, 'vehicles.view': true } },
  ],
  suggestedGroups: ['admin', 'mod', 'dev'],
  keyTypes: ['primary', 'secondary', 'temporary'],
  locales: ['de', 'en', 'hu'],
  jobsList: [
    { name: 'police', label: 'Police', grades: [{ grade: 0, name: 'officer', label: 'Officer' }] },
    { name: 'ambulance', label: 'EMS', grades: [{ grade: 0, name: 'trainee', label: 'Trainee' }] },
  ],
  players: [
    { serverId: 1, identifier: 'char1:abc', name: 'John Doe', job: 'police' },
    { serverId: 2, identifier: 'char1:def', name: 'Jane Roe', job: 'unemployed' },
  ],
  scripts: { target: ['ox_target'], menu: ['nui', 'msk_context', 'msk_menu', 'ox_context', 'ox_menu'], inventory: ['ox_inventory', 'jaksam_inventory'] },
}

const samplePlayer: PlayerDetail = {
  identifier: 'char1:abc',
  name: 'John Doe',
  online: true,
  serverId: 1,
  keys: [
    { plate: 'ABC123', type: 'primary', model: 0 },
    { plate: 'XYZ789', type: 'secondary', model: 0 },
  ],
  vehicles: [{ plate: 'ABC123', model: 0 }],
}

const samplePlate: PlateDetail = {
  plate: 'ABC123',
  owners: [{ identifier: 'char1:abc', name: 'John Doe', online: true }],
  holders: [{ identifier: 'char1:abc', name: 'John Doe', type: 'primary', model: 0, online: true }],
}

// Player-menu previews (open with ?view=keys or ?view=locksmith in `npm run dev`).
const keyStrings = {
  menu_vehicle_keys: 'Vehicle Keys',
  menu_primary_keys: 'Primary Keys',
  menu_secondary_keys: 'Secondary Keys',
  menu_temporary_keys: 'Temporary Keys',
  menu_give_secondary_keys: 'Give Secondary Key',
  menu_exchange_locks: 'Exchange Locks',
  menu_transfer_vehicle: 'Transfer Vehicle',
  menu_no_keys_available: 'No Keys Available',
  menu_locksmith_title: 'Locksmith Service',
  menu_locksmith_exchangelocks: 'Exchange Vehicle Locks',
}

const keysPayload: KeysPayload = {
  locale: 'de',
  theme: DEFAULT_THEME,
  brandTag: 'MSK',
  strings: keyStrings,
  flags: { showSecondaryKeys: true, showTempKeys: true, showExchangeLocks: true, showTransferVehicle: true },
  keys: {
    primary: [
      { label: 'Zentorno', plate: 'LS 5698', model: 0 },
      { label: 'Revolter', plate: 'SCU 103', model: 0 },
    ],
    secondary: [{ label: 'Sentinel', plate: 'FSU 881', model: 0 }],
    temporary: [],
  },
}

const locksmithPayload: LocksmithPayload = {
  locale: 'de',
  theme: DEFAULT_THEME,
  brandTag: 'MSK',
  strings: keyStrings,
  vehicles: [
    { label: 'Zentorno', plate: 'LS 5698', model: 0 },
    { label: 'Sentinel', plate: 'FSU 881', model: 0 },
  ],
}

window.addEventListener('nui:dev-call', (e: Event) => {
  const detail = (e as CustomEvent).detail as { id: string; endpoint: string; data: unknown }
  const ep = detail.endpoint
  let result: unknown = { ok: true, data: bootstrap }

  if (ep.startsWith('keys:') || ep.startsWith('locksmith:')) result = { ok: true }
  else if (ep === 'admin:getCurrentCoords') result = { x: 0, y: 0, z: 0, w: 0 }
  else if (ep === 'admin:players:list') result = { ok: true, players: bootstrap.players }
  else if (ep === 'admin:player:lookup') result = { ok: true, player: samplePlayer }
  else if (ep.startsWith('admin:keys:')) result = { ok: true, player: samplePlayer }
  else if (ep.startsWith('admin:plate:')) result = { ok: true, plate: samplePlate }
  else if (ep === 'admin:perms:validateGroup') result = { ok: true, valid: true, exists: false }
  else if (ep === 'admin:close') result = 'ok'
  else if (ep === 'admin:settings:save') {
    // Mirror the server: merge the patch and re-derive locale from Config.Locale
    // so the language switcher (and theme) actually update in the browser.
    const patch = (detail.data as { settings?: Partial<SettingsPayload> } | undefined)?.settings
    if (patch && typeof patch === 'object') {
      const settings = { ...bootstrap.settings, ...patch }
      bootstrap = { ...bootstrap, settings, locale: typeof patch.Locale === 'string' ? patch.Locale : bootstrap.locale }
    }
    result = { ok: true, data: bootstrap }
  } else if (ep === 'admin:lists:save') {
    const lists = (detail.data as { lists?: Partial<SettingsPayload> } | undefined)?.lists
    if (lists && typeof lists === 'object') {
      bootstrap = { ...bootstrap, settings: { ...bootstrap.settings, ...lists } }
    }
    result = { ok: true, data: bootstrap }
  }

  window.dispatchEvent(new CustomEvent('nui:dev-reply', { detail: { id: detail.id, result } }))
})

window.setTimeout(() => {
  const view = new URLSearchParams(location.search).get('view')
  if (view === 'keys') window.postMessage({ action: 'openKeys', data: keysPayload }, '*')
  else if (view === 'locksmith') window.postMessage({ action: 'openLocksmith', data: locksmithPayload }, '*')
  else window.postMessage({ action: 'openAdmin', data: bootstrap }, '*')
}, 100)
