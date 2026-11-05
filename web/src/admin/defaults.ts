import { DEFAULT_THEME } from '../lib/theme'
import type { SettingsPayload } from './types'

// Complete default settings. The live payload from the server is deep-merged over
// this, so a missing/partial DB value can NEVER leave a nested field undefined and
// crash the Settings tab (which would white-screen the NUI and trap the cursor).
export const DEFAULT_SETTINGS: SettingsPayload = {
  Locale: 'de',
  Debug: true,
  VersionChecker: true,
  Commands: {
    lock: { enable: true, command: 'lock' },
    keyMenu: { enable: true, command: 'keyMenu' },
    refreshKeys: { enable: true, command: 'refreshKeys' },
  },
  Hotkeys: { lock: { enable: true, key: 'L' }, keyMenu: { enable: true, key: 'U' } },
  VehicleTarget: { enable: true, selectSeat: true, script: 'ox_target' },
  AdminCommand: { enable: true, command: 'adlock', groups: [] },
  OnRefreshKeys: {
    OnPlayerLoaded: { primaryKeys: false, secondaryKeys: false },
    OnRefreshKeys: { primaryKeys: false, secondaryKeys: false },
  },
  GivePrimaryKey: { giveSecondaryKey: true, givePrimaryKey: false, removePrimaryKey: false, transferOwnership: false },
  KeyRingSystem: { enable: true, addItem: true, item: 'keyring' },
  Settings: {
    lockDistance: 8.0,
    exchangeLocksPrice: 5000,
    transferVehicle: true,
    lockVehiclesFromNPCs: { enable: true, probability: 25 },
    menu: {
      showSecondaryKeys: true,
      showTempKeys: true,
      showExchangeLocks: true,
      showTransferVehicle: true,
      refreshPlayerKeys: true,
      keysMenu: 'msk_menu',
    },
    key: {
      needItem: true,
      canUseItem: true,
      itemName: 'keys',
      uniqueItems: true,
      inventory: 'ox_inventory',
      itemLabel: 'Vehicle Key',
      plateLabel: 'Plate: %s',
      toggleWithKey: true,
      ownerNeedsItem: false,
    },
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
  Whitelist: { models: [], plates: [] },
  Blacklist: { models: [], plates: [] },
  AdminVehicles: { models: [], plates: [] },
  JobVehicles: {},
  adminCommand: 'advehiclekeys',
  BrandTag: 'MSK',
  Theme: DEFAULT_THEME,
  dashboardGroups: [],
}

function isPlainObject(v: unknown): v is Record<string, unknown> {
  return typeof v === 'object' && v !== null && !Array.isArray(v)
}

// Recursively fills every key present in `base` (the defaults) with the value from
// `over` (the live payload) when present. Arrays are replaced wholesale; primitives
// fall back to the default when the incoming value is undefined.
export function deepMerge<T>(base: T, over: unknown): T {
  if (Array.isArray(base)) return (Array.isArray(over) ? over : base) as unknown as T
  if (isPlainObject(base)) {
    const src = isPlainObject(over) ? over : {}
    const out: Record<string, unknown> = {}
    for (const k of Object.keys(base as Record<string, unknown>)) {
      out[k] = deepMerge((base as Record<string, unknown>)[k], src[k])
    }
    for (const k of Object.keys(src)) if (!(k in out)) out[k] = src[k]
    return out as T
  }
  return (over === undefined ? base : over) as T
}
