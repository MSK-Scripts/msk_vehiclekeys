import type { Theme } from '../lib/theme'

export interface Coord { x: number; y: number; z: number; w: number }

// A model list entry is a spawn name (string). Legacy numeric hashes may appear.
export type ModelEntry = string | number

export interface CmdDef { enable: boolean; command: string }
export interface HotkeyDef { enable: boolean; key: string }
export interface RefreshFlags { primaryKeys: boolean; secondaryKeys: boolean }

export interface SettingsCore {
  lockDistance: number
  exchangeLocksPrice: number
  transferVehicle: boolean
  lockVehiclesFromNPCs: { enable: boolean; probability: number }
  menu: {
    showSecondaryKeys: boolean
    showTempKeys: boolean
    showExchangeLocks: boolean
    showTransferVehicle: boolean
    refreshPlayerKeys: boolean
    keysMenu: string
  }
  key: {
    needItem: boolean
    canUseItem: boolean
    itemName: string
    uniqueItems: boolean
    inventory: string
    itemLabel: string
    plateLabel: string
    toggleWithKey: boolean
    ownerNeedsItem: boolean
  }
  transfer: { needItem: boolean; canUseItem: boolean; itemName: string }
  animation: { dict: string; anim: string; prop: string }
}

export interface LocksmithFlags {
  enable: boolean
  defaultTextUI: boolean
  menu: string
  targetSystem: { enable: boolean; script: string }
  npcVoice: { enable: boolean; inRange: number; outRange: number }
}

export interface VehList { models: ModelEntry[]; plates: string[] }
export interface JobRank { models: ModelEntry[]; plates: string[] }
export interface JobVehEntry { models: ModelEntry[]; plates: string[]; ranks?: Record<string, JobRank> }
export type JobVehicles = Record<string, JobVehEntry>

export interface SettingsPayload {
  Locale: string
  Debug: boolean
  VersionChecker: boolean
  Commands: { lock: CmdDef; keyMenu: CmdDef; refreshKeys: CmdDef }
  Hotkeys: { lock: HotkeyDef; keyMenu: HotkeyDef }
  VehicleTarget: { enable: boolean; selectSeat: boolean; script: string }
  AdminCommand: { enable: boolean; command: string; groups: string[] }
  OnRefreshKeys: { OnPlayerLoaded: RefreshFlags; OnRefreshKeys: RefreshFlags }
  GivePrimaryKey: {
    giveSecondaryKey: boolean
    givePrimaryKey: boolean
    removePrimaryKey: boolean
    transferOwnership: boolean
  }
  KeyRingSystem: { enable: boolean; addItem: boolean; item: string }
  Settings: SettingsCore
  Locksmith: LocksmithFlags
  Whitelist: VehList
  Blacklist: VehList
  AdminVehicles: VehList
  JobVehicles: JobVehicles
  adminCommand: string
  BrandTag: string
  Theme: Theme
  dashboardGroups: string[]
}

export interface LocksmithBlip { enable: boolean; label: string; id: number; scale: number; color: number }
export interface LocksmithDef {
  id: string
  label: string
  pedmodel: string
  blip: LocksmithBlip
  coords: Coord[]
}

export interface JobGrade { grade: number; name: string; label: string }
export interface JobInfo { name: string; label: string; grades: JobGrade[] }

export interface PlayerListEntry { serverId: number; identifier: string; name: string; job: string }
export interface KeyEntry { plate: string; type: string; model: number }
export interface VehicleEntry { plate: string; model: number }
export interface PlayerDetail {
  identifier: string
  name: string
  online: boolean
  serverId?: number
  keys: KeyEntry[]
  vehicles: VehicleEntry[]
}
export interface PlateOwner { identifier: string; name: string; online: boolean }
export interface PlateHolder { identifier: string; name: string; type: string; model: number; online: boolean }
export interface PlateDetail { plate: string; owners: PlateOwner[]; holders: PlateHolder[] }

export interface GroupDef {
  name: string
  protected: boolean
  perms: Record<string, boolean>
}

export interface AdminBootstrap {
  locale: string
  perms: Record<string, boolean>
  permKeys: string[]
  settings: SettingsPayload
  locksmiths: LocksmithDef[]
  groups: GroupDef[]
  suggestedGroups: string[]
  keyTypes: string[]
  locales: string[]
  jobsList: JobInfo[]
  players: PlayerListEntry[]
  scripts: { target: string[]; menu: string[]; inventory: string[] }
}

export interface CallResult {
  ok: boolean
  err?: string
  data?: AdminBootstrap
  player?: PlayerDetail
  plate?: PlateDetail
  players?: PlayerListEntry[]
  valid?: boolean
  exists?: boolean
  blacklisted?: boolean
}
