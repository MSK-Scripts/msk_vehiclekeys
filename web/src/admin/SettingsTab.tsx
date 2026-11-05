import { useState } from 'react'
import { Save } from 'lucide-react'
import type { AdminStrings } from './i18n'
import { errText, localeLabel } from './i18n'
import type { CallResult, SettingsPayload } from './types'
import { DEFAULT_SETTINGS, deepMerge } from './defaults'
import { Btn, ColorInput, Field, NumInput, Section, Select, StatusText, StringListEditor, TextInput, ToggleRow } from './ui'

type Call = (endpoint: string, payload?: unknown) => Promise<CallResult | null>
type Notify = (msg: string, ok: boolean) => void

// null-safe: a missing script list must never crash the tab.
const opts = (arr?: string[]) => (arr ?? []).map((v) => ({ value: v, label: v }))

export function SettingsTab({
  t,
  settings,
  scripts,
  locales,
  call,
  notify,
  toast,
}: {
  t: AdminStrings
  settings: SettingsPayload
  scripts: { target: string[]; menu: string[]; inventory: string[] }
  locales: string[]
  call: Call
  notify: Notify
  toast: { msg: string; ok: boolean } | null
}) {
  // Deep-merge the live payload over full defaults so no nested field is ever
  // undefined (a partial/old DB value would otherwise crash the tab).
  const [s, setS] = useState<SettingsPayload>(() => deepMerge(DEFAULT_SETTINGS, settings))
  const sc = {
    target: scripts?.target ?? [],
    menu: scripts?.menu ?? [],
    inventory: scripts?.inventory ?? [],
  }

  // Language options come from the server (translation.lua). Fall back to de/en if
  // the list is missing, and always keep the current value selectable.
  const localeCodes = (locales && locales.length ? locales : ['de', 'en']).slice()
  if (!localeCodes.includes(s.Locale)) localeCodes.push(s.Locale)
  const localeOpts = localeCodes.map((code) => ({ value: code, label: localeLabel(code) }))

  const top = <K extends keyof SettingsPayload>(k: K, v: SettingsPayload[K]) => setS((p) => ({ ...p, [k]: v }))
  const core = (patch: Partial<SettingsPayload['Settings']>) => setS((p) => ({ ...p, Settings: { ...p.Settings, ...patch } }))
  const key = (patch: Partial<SettingsPayload['Settings']['key']>) =>
    setS((p) => ({ ...p, Settings: { ...p.Settings, key: { ...p.Settings.key, ...patch } } }))
  const menu = (patch: Partial<SettingsPayload['Settings']['menu']>) =>
    setS((p) => ({ ...p, Settings: { ...p.Settings, menu: { ...p.Settings.menu, ...patch } } }))
  const transfer = (patch: Partial<SettingsPayload['Settings']['transfer']>) =>
    setS((p) => ({ ...p, Settings: { ...p.Settings, transfer: { ...p.Settings.transfer, ...patch } } }))
  const anim = (patch: Partial<SettingsPayload['Settings']['animation']>) =>
    setS((p) => ({ ...p, Settings: { ...p.Settings, animation: { ...p.Settings.animation, ...patch } } }))
  const npc = (patch: Partial<SettingsPayload['Settings']['lockVehiclesFromNPCs']>) =>
    setS((p) => ({ ...p, Settings: { ...p.Settings, lockVehiclesFromNPCs: { ...p.Settings.lockVehiclesFromNPCs, ...patch } } }))
  const theme = (patch: Partial<SettingsPayload['Theme']>) => setS((p) => ({ ...p, Theme: { ...p.Theme, ...patch } }))
  const ring = (patch: Partial<SettingsPayload['KeyRingSystem']>) => setS((p) => ({ ...p, KeyRingSystem: { ...p.KeyRingSystem, ...patch } }))
  const vt = (patch: Partial<SettingsPayload['VehicleTarget']>) => setS((p) => ({ ...p, VehicleTarget: { ...p.VehicleTarget, ...patch } }))
  const give = (patch: Partial<SettingsPayload['GivePrimaryKey']>) => setS((p) => ({ ...p, GivePrimaryKey: { ...p.GivePrimaryKey, ...patch } }))
  const ls = (patch: Partial<SettingsPayload['Locksmith']>) => setS((p) => ({ ...p, Locksmith: { ...p.Locksmith, ...patch } }))
  const admincmd = (patch: Partial<SettingsPayload['AdminCommand']>) => setS((p) => ({ ...p, AdminCommand: { ...p.AdminCommand, ...patch } }))

  const setCmd = (name: 'lock' | 'keyMenu' | 'refreshKeys', patch: Partial<{ enable: boolean; command: string }>) =>
    setS((p) => ({ ...p, Commands: { ...p.Commands, [name]: { ...p.Commands[name], ...patch } } }))
  const setHot = (name: 'lock' | 'keyMenu', patch: Partial<{ enable: boolean; key: string }>) =>
    setS((p) => ({ ...p, Hotkeys: { ...p.Hotkeys, [name]: { ...p.Hotkeys[name], ...patch } } }))
  const setRefresh = (grp: 'OnPlayerLoaded' | 'OnRefreshKeys', patch: Partial<{ primaryKeys: boolean; secondaryKeys: boolean }>) =>
    setS((p) => ({ ...p, OnRefreshKeys: { ...p.OnRefreshKeys, [grp]: { ...p.OnRefreshKeys[grp], ...patch } } }))

  const save = async () => {
    const res = await call('admin:settings:save', { settings: s })
    notify(res?.ok ? t.saved : errText(t, res?.err), Boolean(res?.ok))
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <StatusText toast={toast} />
        <Btn variant="accent" onClick={save}><Save size={14} /> {t.save}</Btn>
      </div>
      <p className="font-sans text-[12px] text-text-muted">{t.restart_hint}</p>

      <div className="grid grid-cols-2 gap-4">
        <Section title={t.general}>
          <Field label={t.locale}>
            <Select value={s.Locale} onChange={(v) => top('Locale', v)} options={localeOpts} />
          </Field>
          <Field label={t.brand_tag}><TextInput value={s.BrandTag} onChange={(v) => top('BrandTag', v)} /></Field>
          <Field label={t.admin_command}><TextInput value={s.adminCommand} onChange={(v) => top('adminCommand', v)} /></Field>
          <ToggleRow label={t.debug} checked={s.Debug} onChange={(v) => top('Debug', v)} />
          <ToggleRow label={t.versionchecker} checked={s.VersionChecker} onChange={(v) => top('VersionChecker', v)} />
        </Section>

        <Section title={t.theme}>
          <ColorInput label={t.color_accent} value={s.Theme.accent} onChange={(v) => theme({ accent: v })} />
          <ColorInput label={t.color_bg} value={s.Theme.bg} onChange={(v) => theme({ bg: v })} />
          <ColorInput label={t.color_panel} value={s.Theme.panel} onChange={(v) => theme({ panel: v })} />
          <ColorInput label={t.color_text_primary} value={s.Theme.textPrimary} onChange={(v) => theme({ textPrimary: v })} />
          <ColorInput label={t.color_text_secondary} value={s.Theme.textSecondary} onChange={(v) => theme({ textSecondary: v })} />
        </Section>

        <Section title={t.lock_settings}>
          <Field label={t.lock_distance}><NumInput value={s.Settings.lockDistance} step={0.5} onChange={(v) => core({ lockDistance: v })} /></Field>
          <Field label={t.exchange_price}><NumInput value={s.Settings.exchangeLocksPrice} onChange={(v) => core({ exchangeLocksPrice: v })} /></Field>
          <ToggleRow label={t.transfer_vehicle} checked={s.Settings.transferVehicle} onChange={(v) => core({ transferVehicle: v })} />
          <ToggleRow label={t.npc_lock} checked={s.Settings.lockVehiclesFromNPCs.enable} onChange={(v) => npc({ enable: v })} />
          <Field label={t.npc_probability}><NumInput value={s.Settings.lockVehiclesFromNPCs.probability} onChange={(v) => npc({ probability: v })} /></Field>
        </Section>

        <Section title={t.key_item}>
          <Field label={t.item_name}><TextInput value={s.Settings.key.itemName} onChange={(v) => key({ itemName: v })} /></Field>
          <Field label={t.inventory}><Select value={s.Settings.key.inventory} onChange={(v) => key({ inventory: v })} options={opts(sc.inventory)} /></Field>
          <Field label={t.item_label}><TextInput value={s.Settings.key.itemLabel} onChange={(v) => key({ itemLabel: v })} /></Field>
          <Field label={t.plate_label}><TextInput value={s.Settings.key.plateLabel} onChange={(v) => key({ plateLabel: v })} /></Field>
          <ToggleRow label={t.need_item} checked={s.Settings.key.needItem} onChange={(v) => key({ needItem: v })} />
          <ToggleRow label={t.can_use_item} checked={s.Settings.key.canUseItem} onChange={(v) => key({ canUseItem: v })} />
          <ToggleRow label={t.unique_items} checked={s.Settings.key.uniqueItems} onChange={(v) => key({ uniqueItems: v })} />
          <ToggleRow label={t.toggle_with_key} checked={s.Settings.key.toggleWithKey} onChange={(v) => key({ toggleWithKey: v })} />
          <ToggleRow label={t.owner_needs_item} checked={s.Settings.key.ownerNeedsItem} onChange={(v) => key({ ownerNeedsItem: v })} />
          <p className="font-sans text-[11px] text-text-muted">{t.owner_needs_item_hint}</p>
        </Section>

        <Section title={t.menu_settings}>
          <Field label={t.keys_menu}><Select value={s.Settings.menu.keysMenu} onChange={(v) => menu({ keysMenu: v })} options={opts(sc.menu)} /></Field>
          <ToggleRow label={t.show_secondary} checked={s.Settings.menu.showSecondaryKeys} onChange={(v) => menu({ showSecondaryKeys: v })} />
          <ToggleRow label={t.show_temp} checked={s.Settings.menu.showTempKeys} onChange={(v) => menu({ showTempKeys: v })} />
          <ToggleRow label={t.show_exchange} checked={s.Settings.menu.showExchangeLocks} onChange={(v) => menu({ showExchangeLocks: v })} />
          <ToggleRow label={t.show_transfer} checked={s.Settings.menu.showTransferVehicle} onChange={(v) => menu({ showTransferVehicle: v })} />
          <ToggleRow label={t.refresh_on_menu} checked={s.Settings.menu.refreshPlayerKeys} onChange={(v) => menu({ refreshPlayerKeys: v })} />
        </Section>

        <Section title={t.transfer_item}>
          <Field label={t.item_name}><TextInput value={s.Settings.transfer.itemName} onChange={(v) => transfer({ itemName: v })} /></Field>
          <ToggleRow label={t.need_item} checked={s.Settings.transfer.needItem} onChange={(v) => transfer({ needItem: v })} />
          <ToggleRow label={t.can_use_item} checked={s.Settings.transfer.canUseItem} onChange={(v) => transfer({ canUseItem: v })} />
        </Section>

        <Section title={t.keyring}>
          <Field label={t.keyring_item}><TextInput value={s.KeyRingSystem.item} onChange={(v) => ring({ item: v })} /></Field>
          <ToggleRow label={t.enable} checked={s.KeyRingSystem.enable} onChange={(v) => ring({ enable: v })} />
          <ToggleRow label={t.keyring_add} checked={s.KeyRingSystem.addItem} onChange={(v) => ring({ addItem: v })} />
        </Section>

        <Section title={t.target_settings}>
          <Field label={t.script}><Select value={s.VehicleTarget.script} onChange={(v) => vt({ script: v })} options={opts(sc.target)} /></Field>
          <ToggleRow label={t.enable} checked={s.VehicleTarget.enable} onChange={(v) => vt({ enable: v })} />
          <ToggleRow label={t.select_seat} checked={s.VehicleTarget.selectSeat} onChange={(v) => vt({ selectSeat: v })} />
        </Section>

        <Section title={t.give_primary}>
          <ToggleRow label={t.give_secondary_key} checked={s.GivePrimaryKey.giveSecondaryKey} onChange={(v) => give({ giveSecondaryKey: v })} />
          <ToggleRow label={t.give_primary_key} checked={s.GivePrimaryKey.givePrimaryKey} onChange={(v) => give({ givePrimaryKey: v })} />
          <ToggleRow label={t.remove_primary_key} checked={s.GivePrimaryKey.removePrimaryKey} onChange={(v) => give({ removePrimaryKey: v })} />
          <ToggleRow label={t.transfer_ownership} checked={s.GivePrimaryKey.transferOwnership} onChange={(v) => give({ transferOwnership: v })} />
        </Section>

        <Section title={t.refresh_settings}>
          <span className="msk-label text-[10px] font-bold">{t.on_player_loaded}</span>
          <ToggleRow label={t.primary_keys} checked={s.OnRefreshKeys.OnPlayerLoaded.primaryKeys} onChange={(v) => setRefresh('OnPlayerLoaded', { primaryKeys: v })} />
          <ToggleRow label={t.secondary_keys} checked={s.OnRefreshKeys.OnPlayerLoaded.secondaryKeys} onChange={(v) => setRefresh('OnPlayerLoaded', { secondaryKeys: v })} />
          <span className="msk-label text-[10px] font-bold">{t.on_refresh}</span>
          <ToggleRow label={t.primary_keys} checked={s.OnRefreshKeys.OnRefreshKeys.primaryKeys} onChange={(v) => setRefresh('OnRefreshKeys', { primaryKeys: v })} />
          <ToggleRow label={t.secondary_keys} checked={s.OnRefreshKeys.OnRefreshKeys.secondaryKeys} onChange={(v) => setRefresh('OnRefreshKeys', { secondaryKeys: v })} />
        </Section>

        <Section title={t.locksmith_settings}>
          <Field label={t.keys_menu}><Select value={s.Locksmith.menu} onChange={(v) => ls({ menu: v })} options={opts(sc.menu)} /></Field>
          <Field label={t.target_script}><Select value={s.Locksmith.targetSystem.script} onChange={(v) => ls({ targetSystem: { ...s.Locksmith.targetSystem, script: v } })} options={opts(sc.target)} /></Field>
          <ToggleRow label={t.enable} checked={s.Locksmith.enable} onChange={(v) => ls({ enable: v })} />
          <ToggleRow label={t.default_textui} checked={s.Locksmith.defaultTextUI} onChange={(v) => ls({ defaultTextUI: v })} />
          <ToggleRow label={`${t.target_settings}`} checked={s.Locksmith.targetSystem.enable} onChange={(v) => ls({ targetSystem: { ...s.Locksmith.targetSystem, enable: v } })} />
          <ToggleRow label={t.npc_voice} checked={s.Locksmith.npcVoice.enable} onChange={(v) => ls({ npcVoice: { ...s.Locksmith.npcVoice, enable: v } })} />
          <div className="grid grid-cols-2 gap-3">
            <Field label={t.npc_in_range}><NumInput value={s.Locksmith.npcVoice.inRange} step={0.5} onChange={(v) => ls({ npcVoice: { ...s.Locksmith.npcVoice, inRange: v } })} /></Field>
            <Field label={t.npc_out_range}><NumInput value={s.Locksmith.npcVoice.outRange} step={0.5} onChange={(v) => ls({ npcVoice: { ...s.Locksmith.npcVoice, outRange: v } })} /></Field>
          </div>
        </Section>

        <Section title={t.animation}>
          <Field label={t.anim_dict}><TextInput value={s.Settings.animation.dict} onChange={(v) => anim({ dict: v })} /></Field>
          <Field label={t.anim_name}><TextInput value={s.Settings.animation.anim} onChange={(v) => anim({ anim: v })} /></Field>
          <Field label={t.anim_prop}><TextInput value={s.Settings.animation.prop} onChange={(v) => anim({ prop: v })} /></Field>
        </Section>

        <Section title={t.admin_lock_command}>
          <Field label={t.command}><TextInput value={s.AdminCommand.command} onChange={(v) => admincmd({ command: v })} /></Field>
          <ToggleRow label={t.enable} checked={s.AdminCommand.enable} onChange={(v) => admincmd({ enable: v })} />
          <Field label={t.groups}>
            <StringListEditor values={s.AdminCommand.groups} placeholder="admin" addLabel={t.add} onChange={(groups) => admincmd({ groups })} />
          </Field>
        </Section>

        <Section title={t.commands}>
          {(['lock', 'keyMenu', 'refreshKeys'] as const).map((name) => (
            <div key={name} className="flex flex-col gap-2 rounded-sm border border-border bg-input p-2">
              <span className="font-mono text-[11px] uppercase text-text-secondary">{name}</span>
              <TextInput value={s.Commands[name].command} onChange={(v) => setCmd(name, { command: v })} />
              <ToggleRow label={t.enable} checked={s.Commands[name].enable} onChange={(v) => setCmd(name, { enable: v })} />
            </div>
          ))}
        </Section>

        <Section title={t.hotkeys}>
          {(['lock', 'keyMenu'] as const).map((name) => (
            <div key={name} className="flex flex-col gap-2 rounded-sm border border-border bg-input p-2">
              <span className="font-mono text-[11px] uppercase text-text-secondary">{name}</span>
              <TextInput value={s.Hotkeys[name].key} onChange={(v) => setHot(name, { key: v })} />
              <ToggleRow label={t.enable} checked={s.Hotkeys[name].enable} onChange={(v) => setHot(name, { enable: v })} />
            </div>
          ))}
        </Section>
      </div>
    </div>
  )
}
