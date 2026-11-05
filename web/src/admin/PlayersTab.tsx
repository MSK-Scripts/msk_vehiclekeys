import { useState } from 'react'
import { KeyRound, RefreshCw, Search, Trash2, UserRound } from 'lucide-react'
import { fetchNui } from '../lib/nui'
import type { AdminStrings } from './i18n'
import { errText } from './i18n'
import type { CallResult, KeyEntry, PlayerDetail, PlayerListEntry } from './types'
import { Btn, Section, Select, StatusText, Switch, TextInput } from './ui'

type Notify = (msg: string, ok: boolean) => void

export function PlayersTab({
  t,
  players,
  perms,
  keyTypes,
  notify,
  toast,
}: {
  t: AdminStrings
  players: PlayerListEntry[]
  perms: Record<string, boolean>
  keyTypes: string[]
  notify: Notify
  toast: { msg: string; ok: boolean } | null
}) {
  const canManage = Boolean(perms['keys.manage'])
  const [player, setPlayer] = useState<PlayerDetail | null>(null)
  const [lookup, setLookup] = useState('')

  // Add-key form
  const [plate, setPlate] = useState('')
  const [type, setType] = useState(keyTypes[0] ?? 'primary')
  const [giveItem, setGiveItem] = useState(false)

  const typeLabel = (ty: string) =>
    ty === 'primary' ? t.primary : ty === 'secondary' ? t.secondary : t.temporary

  const load = async (identifier: string) => {
    const res = await fetchNui<CallResult>('admin:player:lookup', { identifier })
    if (res?.ok && res.player) setPlayer(res.player)
    else notify(errText(t, res?.err), false)
  }

  const runAction = async (endpoint: string, payload: unknown, okMsg: string) => {
    const res = await fetchNui<CallResult>(endpoint, payload)
    if (res?.ok && res.player) {
      setPlayer(res.player)
      notify(okMsg, true)
    } else {
      notify(errText(t, res?.err), false)
    }
  }

  const addKey = () => {
    if (!player || !plate.trim()) return
    runAction('admin:keys:add', { identifier: player.identifier, plate: plate.trim(), type, giveItem }, t.saved)
    setPlate('')
  }

  const removeKey = (k: KeyEntry) => {
    if (!player) return
    runAction('admin:keys:remove', { identifier: player.identifier, plate: k.plate, type: k.type }, t.saved)
  }

  const inputCls = 'w-full rounded-sm border border-border bg-input px-3 py-2 text-[13px] text-text-primary outline-none focus:border-border-accent'

  return (
    <div className="flex flex-col gap-4">
      <div className="flex min-h-[18px] items-center justify-end">
        <StatusText toast={toast} />
      </div>

      <div className="grid grid-cols-[320px_1fr] gap-4">
        {/* Left: online list + lookup */}
        <div className="flex flex-col gap-4">
          <Section title={t.player_lookup}>
            <div className="flex gap-2">
              <input
                value={lookup}
                onChange={(e) => setLookup(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && lookup.trim() && load(lookup.trim())}
                placeholder={t.lookup_placeholder}
                className={inputCls}
              />
              <Btn onClick={() => lookup.trim() && load(lookup.trim())}><Search size={13} /> {t.lookup}</Btn>
            </div>
          </Section>

          <Section title={t.players_online}>
            {players.length === 0 ? (
              <p className="font-sans text-[12px] text-text-muted">{t.no_players}</p>
            ) : (
              <div className="msk-scroll flex max-h-[46vh] flex-col gap-1 overflow-y-auto pr-1">
                {players.map((pl) => (
                  <button
                    key={pl.serverId}
                    onClick={() => load(pl.identifier)}
                    className={`flex items-center justify-between rounded-sm border px-3 py-2 text-left transition-colors ${
                      player?.identifier === pl.identifier
                        ? 'border-border-accent bg-accent/10'
                        : 'border-border bg-input hover:border-border-accent'
                    }`}
                  >
                    <span className="flex items-center gap-2">
                      <UserRound size={14} className="text-text-muted" />
                      <span className="font-sans text-[13px] text-text-primary">{pl.name}</span>
                    </span>
                    <span className="font-mono text-[11px] text-text-muted">[{pl.serverId}]</span>
                  </button>
                ))}
              </div>
            )}
          </Section>
        </div>

        {/* Right: detail */}
        <div className="flex flex-col gap-4">
          {!player ? (
            <Section title={t.keys_heading}>
              <p className="font-sans text-[12px] text-text-muted">{t.player_lookup}</p>
            </Section>
          ) : (
            <>
              <Section title={player.name}>
                <div className="flex flex-wrap items-center gap-2">
                  <span className="font-mono text-[11px] text-text-muted">{player.identifier}</span>
                  <span className={`rounded-sm px-2 py-0.5 font-mono text-[10px] uppercase ${player.online ? 'bg-accent/15 text-accent' : 'bg-white/10 text-text-muted'}`}>
                    {player.online ? t.online : t.offline}
                  </span>
                </div>

                {canManage && (
                  <div className="flex flex-wrap gap-2 pt-1">
                    <Btn
                      onClick={() => runAction('admin:keys:refresh', { identifier: player.identifier }, t.saved)}
                      disabled={!player.online}
                    >
                      <RefreshCw size={13} /> {t.refresh}
                    </Btn>
                    <Btn
                      variant="accent"
                      onClick={() => runAction('admin:keys:refreshForce', { identifier: player.identifier }, t.saved)}
                      disabled={!player.online}
                    >
                      <RefreshCw size={13} /> {t.refresh_force}
                    </Btn>
                    {!player.online && <span className="font-sans text-[11px] text-text-muted">{t.online_only}</span>}
                  </div>
                )}
                <p className="font-sans text-[11px] text-text-muted">{t.refresh_force_hint}</p>
              </Section>

              {canManage && (
                <Section title={t.add_key}>
                  <div className="grid grid-cols-[1fr_150px] gap-2">
                    <TextInput value={plate} onChange={setPlate} placeholder={t.plate} />
                    <Select
                      value={type}
                      onChange={setType}
                      options={keyTypes.map((ty) => ({ value: ty, label: typeLabel(ty) }))}
                    />
                  </div>
                  <div className="flex items-center justify-between rounded-sm border border-border bg-input px-3 py-2">
                    <span className="font-sans text-[13px] text-text-secondary">{t.give_item_on_add}</span>
                    <Switch checked={giveItem} onChange={setGiveItem} disabled={!player.online} />
                  </div>
                  <Btn variant="accent" onClick={addKey} disabled={!plate.trim()}>
                    <KeyRound size={13} /> {t.add_key}
                  </Btn>
                </Section>
              )}

              <Section title={t.keys_heading}>
                {player.keys.length === 0 ? (
                  <p className="font-sans text-[12px] text-text-muted">{t.no_keys}</p>
                ) : (
                  <div className="flex flex-col gap-1">
                    {player.keys.map((k, i) => (
                      <div key={`${k.plate}-${k.type}-${i}`} className="flex items-center justify-between rounded-sm border border-border bg-input px-3 py-2">
                        <div className="flex items-center gap-3">
                          <span className="font-mono text-[13px] uppercase text-text-primary">{k.plate}</span>
                          <span className="rounded-sm bg-white/10 px-2 py-0.5 font-mono text-[10px] uppercase text-text-secondary">{typeLabel(k.type)}</span>
                        </div>
                        {canManage && (
                          <div className="flex items-center gap-2">
                            {player.online && (
                              <>
                                <Btn onClick={() => runAction('admin:keys:giveItem', { identifier: player.identifier, plate: k.plate, type: k.type }, t.saved)}>{t.give_item}</Btn>
                                <Btn onClick={() => runAction('admin:keys:takeItem', { identifier: player.identifier, plate: k.plate }, t.saved)}>{t.take_item}</Btn>
                              </>
                            )}
                            <button onClick={() => removeKey(k)} className="rounded-sm border border-border p-1.5 text-text-muted hover:text-red-400">
                              <Trash2 size={14} />
                            </button>
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                )}
              </Section>

              <Section title={t.owned_vehicles}>
                {player.vehicles.length === 0 ? (
                  <p className="font-sans text-[12px] text-text-muted">{t.no_vehicles}</p>
                ) : (
                  <div className="flex flex-wrap gap-2">
                    {player.vehicles.map((v, i) => (
                      <span key={`${v.plate}-${i}`} className="rounded-sm border border-border bg-input px-2.5 py-1 font-mono text-[12px] uppercase text-text-secondary">
                        {v.plate}
                      </span>
                    ))}
                  </div>
                )}
              </Section>
            </>
          )}
        </div>
      </div>
    </div>
  )
}
