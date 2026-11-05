import { useState } from 'react'
import { Search } from 'lucide-react'
import { fetchNui } from '../lib/nui'
import type { AdminStrings } from './i18n'
import { errText } from './i18n'
import type { CallResult, PlateDetail } from './types'
import { Btn, ConfirmDialog, Section, StatusText, TextInput } from './ui'

type Notify = (msg: string, ok: boolean) => void

export function VehiclesTab({
  t,
  perms,
  notify,
  toast,
}: {
  t: AdminStrings
  perms: Record<string, boolean>
  notify: Notify
  toast: { msg: string; ok: boolean } | null
}) {
  const canManage = Boolean(perms['vehicles.manage'])
  const [detail, setDetail] = useState<PlateDetail | null>(null)
  const [lookup, setLookup] = useState('')
  const [newPlate, setNewPlate] = useState('')
  const [confirm, setConfirm] = useState<null | 'removeAll' | 'reset'>(null)

  const load = async (plate: string) => {
    const res = await fetchNui<CallResult>('admin:plate:lookup', { plate })
    if (res?.ok && res.plate) setDetail(res.plate)
    else notify(errText(t, res?.err), false)
  }

  const run = async (endpoint: string, payload: unknown, okMsg: string) => {
    const res = await fetchNui<CallResult>(endpoint, payload)
    if (res?.ok && res.plate) {
      setDetail(res.plate)
      notify(okMsg, true)
    } else {
      notify(errText(t, res?.err), false)
    }
  }

  const doChangePlate = () => {
    if (!detail || !newPlate.trim()) return
    run('admin:plate:changePlate', { oldPlate: detail.plate, newPlate: newPlate.trim() }, t.saved)
    setNewPlate('')
  }

  const typeLabel = (ty: string) => (ty === 'primary' ? t.primary : ty === 'secondary' ? t.secondary : t.temporary)

  return (
    <div className="flex flex-col gap-4">
      <div className="flex min-h-[18px] items-center justify-end">
        <StatusText toast={toast} />
      </div>

      <Section title={t.plate_lookup}>
        <div className="flex gap-2">
          <TextInput value={lookup} onChange={setLookup} placeholder={t.plate_placeholder} />
          <Btn onClick={() => lookup.trim() && load(lookup.trim())}><Search size={13} /> {t.lookup}</Btn>
        </div>
      </Section>

      {detail && (
        <>
          <Section title={`${t.plate}: ${detail.plate}`}>
            <div className="grid grid-cols-2 gap-4">
              <div className="flex flex-col gap-1.5">
                <span className="msk-label text-[10px] font-bold">{t.owner}</span>
                {detail.owners.length === 0 ? (
                  <span className="font-sans text-[12px] text-text-muted">{t.no_owner}</span>
                ) : (
                  detail.owners.map((o, i) => (
                    <div key={i} className="flex items-center gap-2">
                      <span className="font-sans text-[13px] text-text-primary">{o.name}</span>
                      <span className="font-mono text-[10px] text-text-muted">{o.identifier}</span>
                    </div>
                  ))
                )}
              </div>
              <div className="flex flex-col gap-1.5">
                <span className="msk-label text-[10px] font-bold">{t.holders}</span>
                {detail.holders.length === 0 ? (
                  <span className="font-sans text-[12px] text-text-muted">{t.no_holders}</span>
                ) : (
                  detail.holders.map((h, i) => (
                    <div key={i} className="flex items-center gap-2">
                      <span className="font-sans text-[13px] text-text-primary">{h.name}</span>
                      <span className="rounded-sm bg-white/10 px-1.5 py-0.5 font-mono text-[10px] uppercase text-text-secondary">{typeLabel(h.type)}</span>
                    </div>
                  ))
                )}
              </div>
            </div>
          </Section>

          {canManage && (
            <>
              <Section title={t.change_plate}>
                <div className="flex items-end gap-2">
                  <div className="flex-1">
                    <TextInput value={newPlate} onChange={setNewPlate} placeholder={t.new_plate} />
                  </div>
                  <Btn variant="accent" onClick={doChangePlate} disabled={!newPlate.trim()}>{t.change_plate}</Btn>
                </div>
              </Section>

              <Section title={t.reset_locks}>
                <p className="font-sans text-[12px] text-text-muted">{t.reset_locks_hint}</p>
                <div className="flex gap-2">
                  <Btn onClick={() => setConfirm('reset')}>{t.reset_locks}</Btn>
                  <Btn variant="danger" onClick={() => setConfirm('removeAll')}>{t.remove_all_keys}</Btn>
                </div>
              </Section>
            </>
          )}
        </>
      )}

      {confirm && detail && (
        <ConfirmDialog
          title={confirm === 'removeAll' ? t.remove_all_keys : t.reset_locks}
          message={confirm === 'removeAll' ? t.confirm_remove_all : t.confirm_reset_locks}
          confirmLabel={confirm === 'removeAll' ? t.remove_all_keys : t.reset_locks}
          cancelLabel={t.cancel}
          onCancel={() => setConfirm(null)}
          onConfirm={() => {
            const mode = confirm
            setConfirm(null)
            if (mode === 'removeAll') run('admin:plate:removeAllKeys', { plate: detail.plate }, t.saved)
            else run('admin:plate:resetLocks', { plate: detail.plate }, t.saved)
          }}
        />
      )}
    </div>
  )
}
