import { useState } from 'react'
import { MapPin, Pencil, Plus, Trash2 } from 'lucide-react'
import type { AdminStrings } from './i18n'
import { errText } from './i18n'
import type { CallResult, Coord, LocksmithDef } from './types'
import { Btn, ConfirmDialog, CoordList, Field, Modal, NumInput, Section, StatusText, TextInput, ToggleRow } from './ui'

type Call = (endpoint: string, payload?: unknown) => Promise<CallResult | null>
type Notify = (msg: string, ok: boolean) => void

const emptyLocksmith = (): LocksmithDef => ({
  id: '',
  label: '',
  pedmodel: 's_m_m_autoshop_01',
  blip: { enable: true, label: 'Locksmith Service', id: 134, scale: 1.0, color: 0 },
  coords: [{ x: 0, y: 0, z: 0, w: 0 }],
})

function Editor({
  t,
  initial,
  isNew,
  onSave,
  onClose,
}: {
  t: AdminStrings
  initial: LocksmithDef
  isNew: boolean
  onSave: (def: LocksmithDef) => void
  onClose: () => void
}) {
  const [def, setDef] = useState<LocksmithDef>(initial)
  const set = <K extends keyof LocksmithDef>(k: K, v: LocksmithDef[K]) => setDef((d) => ({ ...d, [k]: v }))
  const setBlip = (patch: Partial<LocksmithDef['blip']>) => setDef((d) => ({ ...d, blip: { ...d.blip, ...patch } }))

  return (
    <Modal
      title={isNew ? t.create_locksmith : `${t.edit} — ${def.id}`}
      onClose={onClose}
      footer={
        <>
          <Btn variant="ghost" onClick={onClose}>{t.cancel}</Btn>
          <Btn variant="accent" onClick={() => onSave(def)} disabled={!def.id.trim() || def.coords.length === 0}>{t.save}</Btn>
        </>
      }
    >
      <div className="flex flex-col gap-4">
        <div className="grid grid-cols-2 gap-3">
          <Field label={t.id}>
            <TextInput value={def.id} onChange={(v) => set('id', v)} disabled={!isNew} placeholder="locksmith" />
          </Field>
          <Field label={t.label}>
            <TextInput value={def.label} onChange={(v) => set('label', v)} placeholder="Locksmith Service" />
          </Field>
        </div>

        <Field label={t.ped_model}>
          <TextInput value={def.pedmodel} onChange={(v) => set('pedmodel', v)} placeholder="s_m_m_autoshop_01" />
        </Field>

        <Section title={t.blip}>
          <ToggleRow label={t.enable} checked={def.blip.enable} onChange={(v) => setBlip({ enable: v })} />
          <div className="grid grid-cols-2 gap-3">
            <Field label={t.blip_label}>
              <TextInput value={def.blip.label} onChange={(v) => setBlip({ label: v })} />
            </Field>
            <Field label={t.blip_sprite}>
              <NumInput value={def.blip.id} onChange={(v) => setBlip({ id: v })} />
            </Field>
            <Field label={t.blip_scale}>
              <NumInput value={def.blip.scale} step={0.1} onChange={(v) => setBlip({ scale: v })} />
            </Field>
            <Field label={t.blip_color}>
              <NumInput value={def.blip.color} onChange={(v) => setBlip({ color: v })} />
            </Field>
          </div>
        </Section>

        <CoordList
          title={t.locations}
          addLabel={t.add_location}
          useLabel={t.use_position}
          coords={def.coords}
          onChange={(next: Coord[]) => set('coords', next)}
        />
      </div>
    </Modal>
  )
}

export function LocksmithTab({
  t,
  locksmiths,
  perms,
  call,
  notify,
  toast,
}: {
  t: AdminStrings
  locksmiths: LocksmithDef[]
  perms: Record<string, boolean>
  call: Call
  notify: Notify
  toast: { msg: string; ok: boolean } | null
}) {
  const canCreate = Boolean(perms['locksmith.create'])
  const canEdit = Boolean(perms['locksmith.edit'])
  const canDelete = Boolean(perms['locksmith.delete'])

  const [editing, setEditing] = useState<{ def: LocksmithDef; isNew: boolean } | null>(null)
  const [pendingDelete, setPendingDelete] = useState<string | null>(null)

  const save = async (def: LocksmithDef) => {
    const res = await call('admin:locksmith:save', { locksmith: def })
    if (res?.ok) { notify(t.saved, true); setEditing(null) }
    else notify(errText(t, res?.err), false)
  }

  const del = async (id: string) => {
    const res = await call('admin:locksmith:delete', { id })
    notify(res?.ok ? t.saved : errText(t, res?.err), Boolean(res?.ok))
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <StatusText toast={toast} />
        {canCreate && (
          <Btn variant="accent" onClick={() => setEditing({ def: emptyLocksmith(), isNew: true })}>
            <Plus size={14} /> {t.create_locksmith}
          </Btn>
        )}
      </div>

      {locksmiths.length === 0 ? (
        <Section title={t.tab_locksmith}>
          <p className="font-sans text-[12px] text-text-muted">{t.no_locksmiths}</p>
        </Section>
      ) : (
        <div className="grid grid-cols-2 gap-3">
          {locksmiths.map((ls) => (
            <div key={ls.id} className="flex flex-col gap-2 rounded-sm border border-border bg-panel-raised p-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <MapPin size={15} className="text-accent" />
                  <span className="font-display text-[14px] font-semibold text-text-primary">{ls.label || ls.id}</span>
                </div>
                <span className="font-mono text-[11px] text-text-muted">{ls.id}</span>
              </div>
              <div className="flex items-center gap-3 font-mono text-[11px] text-text-muted">
                <span>{ls.pedmodel}</span>
                <span>· {ls.coords.length} {t.locations.toLowerCase()}</span>
              </div>
              <div className="flex justify-end gap-2 pt-1">
                {canEdit && (
                  <Btn onClick={() => setEditing({ def: ls, isNew: false })}><Pencil size={13} /> {t.edit}</Btn>
                )}
                {canDelete && (
                  <button onClick={() => setPendingDelete(ls.id)} className="rounded-sm border border-border p-2 text-text-muted hover:text-red-400">
                    <Trash2 size={14} />
                  </button>
                )}
              </div>
            </div>
          ))}
        </div>
      )}

      {editing && (
        <Editor
          t={t}
          initial={editing.def}
          isNew={editing.isNew}
          onSave={save}
          onClose={() => setEditing(null)}
        />
      )}

      {pendingDelete && (
        <ConfirmDialog
          title={t.delete}
          message={`${t.confirm_delete_locksmith}\n\n${pendingDelete}`}
          confirmLabel={t.delete}
          cancelLabel={t.cancel}
          onCancel={() => setPendingDelete(null)}
          onConfirm={() => {
            const id = pendingDelete
            setPendingDelete(null)
            void del(id)
          }}
        />
      )}
    </div>
  )
}
