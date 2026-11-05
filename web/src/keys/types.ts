import type { Theme } from '../lib/theme'

export interface VehItem {
  label: string
  plate: string
  model: number
}

// Resolved player-menu strings forwarded from translation.lua (single source of truth).
export interface KeyStrings {
  menu_vehicle_keys: string
  menu_primary_keys: string
  menu_secondary_keys: string
  menu_temporary_keys: string
  menu_give_secondary_keys: string
  menu_exchange_locks: string
  menu_transfer_vehicle: string
  menu_no_keys_available: string
  menu_locksmith_title: string
  menu_locksmith_exchangelocks: string
}

export interface KeyFlags {
  showSecondaryKeys: boolean
  showTempKeys: boolean
  showExchangeLocks: boolean
  showTransferVehicle: boolean
}

export interface KeysPayload {
  locale: string
  theme?: Partial<Theme>
  brandTag?: string
  strings: KeyStrings
  flags: KeyFlags
  keys: { primary: VehItem[]; secondary: VehItem[]; temporary: VehItem[] }
}

export interface LocksmithPayload {
  locale: string
  theme?: Partial<Theme>
  brandTag?: string
  strings: KeyStrings
  vehicles: VehItem[]
}
