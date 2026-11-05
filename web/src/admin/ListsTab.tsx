import { useState } from 'react'
import { Plus, Save, Trash2 } from 'lucide-react'
import type { AdminStrings } from './i18n'
import { errText } from './i18n'
import type { CallResult, JobInfo, ModelEntry, SettingsPayload } from './types'
import { Btn, Field, Section, StatusText, StringListEditor } from './ui'

type Call = (endpoint: string, payload?: unknown) => Promise<CallResult | null>
type Notify = (msg: string, ok: boolean) => void

interface VList { models: string[]; plates: string[] }
interface JEntry { models: string[]; plates: string[]; ranks: Record<string, { models: string[]; plates: string[] }> }

const toStr = (arr?: ModelEntry[]): string[] => (arr || []).map((m) => String(m))

function VListEditor({ t, value, onChange }: { t: AdminStrings; value: VList; onChange: (v: VList) => void }) {
  return (
    <div className="grid grid-cols-2 gap-4">
      <Field label={t.models}>
        <StringListEditor
          values={value.models}
          placeholder={t.model_placeholder}
          addLabel={t.add_model}
          onChange={(models) => onChange({ ...value, models })}
        />
      </Field>
      <Field label={t.plates}>
        <StringListEditor
          values={value.plates}
          placeholder={t.plate_placeholder}
          addLabel={t.add_plate}
          onChange={(plates) => onChange({ ...value, plates })}
        />
      </Field>
    </div>
  )
}

export function ListsTab({
  t,
  settings,
  jobsList,
  call,
  notify,
  toast,
}: {
  t: AdminStrings
  settings: SettingsPayload
  jobsList: JobInfo[]
  call: Call
  notify: Notify
  toast: { msg: string; ok: boolean } | null
}) {
  const [wl, setWl] = useState<VList>({ models: toStr(settings.Whitelist?.models), plates: settings.Whitelist?.plates || [] })
  const [bl, setBl] = useState<VList>({ models: toStr(settings.Blacklist?.models), plates: settings.Blacklist?.plates || [] })
  const [av, setAv] = useState<VList>({ models: toStr(settings.AdminVehicles?.models), plates: settings.AdminVehicles?.plates || [] })

  const [jobs, setJobs] = useState<Record<string, JEntry>>(() => {
    const out: Record<string, JEntry> = {}
    for (const [job, e] of Object.entries(settings.JobVehicles || {})) {
      const ranks: JEntry['ranks'] = {}
      for (const [r, rd] of Object.entries(e.ranks || {})) ranks[r] = { models: toStr(rd.models), plates: rd.plates || [] }
      out[job] = { models: toStr(e.models), plates: e.plates || [], ranks }
    }
    return out
  })

  const [newJob, setNewJob] = useState('')
  const [newRank, setNewRank] = useState<Record<string, string>>({})

  const save = async () => {
    const res = await call('admin:lists:save', {
      lists: { Whitelist: wl, Blacklist: bl, AdminVehicles: av, JobVehicles: jobs },
    })
    notify(res?.ok ? t.saved : errText(t, res?.err), Boolean(res?.ok))
  }

  const addJob = () => {
    const name = newJob.trim().toLowerCase()
    if (!name || jobs[name]) { setNewJob(''); return }
    setJobs((j) => ({ ...j, [name]: { models: [], plates: [], ranks: {} } }))
    setNewJob('')
  }
  const removeJob = (name: string) => setJobs((j) => { const n = { ...j }; delete n[name]; return n })
  const setJob = (name: string, patch: Partial<JEntry>) => setJobs((j) => ({ ...j, [name]: { ...j[name], ...patch } }))

  const addRank = (job: string) => {
    const rank = (newRank[job] || '').trim().toLowerCase()
    if (!rank || jobs[job].ranks[rank]) return
    setJobs((j) => ({ ...j, [job]: { ...j[job], ranks: { ...j[job].ranks, [rank]: { models: [], plates: [] } } } }))
    setNewRank((s) => ({ ...s, [job]: '' }))
  }
  const removeRank = (job: string, rank: string) =>
    setJobs((j) => { const ranks = { ...j[job].ranks }; delete ranks[rank]; return { ...j, [job]: { ...j[job], ranks } } })
  const setRank = (job: string, rank: string, patch: Partial<{ models: string[]; plates: string[] }>) =>
    setJobs((j) => ({ ...j, [job]: { ...j[job], ranks: { ...j[job].ranks, [rank]: { ...j[job].ranks[rank], ...patch } } } }))

  const inputCls = 'rounded-sm border border-border bg-input px-3 py-2 text-[13px] text-text-primary outline-none focus:border-border-accent'

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <StatusText toast={toast} />
        <Btn variant="accent" onClick={save}><Save size={14} /> {t.save_lists}</Btn>
      </div>
      <p className="font-sans text-[12px] text-text-muted">{t.lists_hint}</p>

      <Section title={t.whitelist}><VListEditor t={t} value={wl} onChange={setWl} /></Section>
      <Section title={t.blacklist}><VListEditor t={t} value={bl} onChange={setBl} /></Section>
      <Section title={t.admin_vehicles}><VListEditor t={t} value={av} onChange={setAv} /></Section>

      <Section title={t.job_vehicles}>
        <div className="flex gap-2">
          <input
            value={newJob}
            onChange={(e) => setNewJob(e.target.value)}
            list="vk-jobs"
            placeholder={t.job_name}
            className={`${inputCls} flex-1`}
          />
          <datalist id="vk-jobs">
            {jobsList.map((j) => <option key={j.name} value={j.name}>{j.label}</option>)}
          </datalist>
          <Btn onClick={addJob}><Plus size={13} /> {t.add_job}</Btn>
        </div>

        {Object.entries(jobs).map(([job, e]) => (
          <div key={job} className="flex flex-col gap-3 rounded-sm border border-border bg-input p-3">
            <div className="flex items-center justify-between">
              <span className="font-mono text-[13px] uppercase text-text-primary">{job}</span>
              <button onClick={() => removeJob(job)} className="rounded-sm border border-border p-1.5 text-text-muted hover:text-red-400">
                <Trash2 size={14} />
              </button>
            </div>

            <VListEditor t={t} value={{ models: e.models, plates: e.plates }} onChange={(v) => setJob(job, v)} />

            <div className="flex flex-col gap-2 border-t border-border pt-3">
              <span className="msk-label text-[10px] font-bold">{t.ranks}</span>
              {Object.entries(e.ranks).map(([rank, rd]) => (
                <div key={rank} className="flex flex-col gap-2 rounded-sm border border-border bg-panel-raised p-3">
                  <div className="flex items-center justify-between">
                    <span className="font-mono text-[12px] uppercase text-text-secondary">{rank}</span>
                    <button onClick={() => removeRank(job, rank)} className="rounded-sm border border-border p-1.5 text-text-muted hover:text-red-400">
                      <Trash2 size={13} />
                    </button>
                  </div>
                  <VListEditor t={t} value={rd} onChange={(v) => setRank(job, rank, v)} />
                </div>
              ))}
              <div className="flex gap-2">
                <input
                  value={newRank[job] || ''}
                  onChange={(ev) => setNewRank((s) => ({ ...s, [job]: ev.target.value }))}
                  placeholder={t.rank_name}
                  className={`${inputCls} flex-1`}
                />
                <Btn onClick={() => addRank(job)}><Plus size={13} /> {t.add_rank}</Btn>
              </div>
            </div>
          </div>
        ))}
      </Section>
    </div>
  )
}
