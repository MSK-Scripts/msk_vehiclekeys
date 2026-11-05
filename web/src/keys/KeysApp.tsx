import { useCallback, useEffect, useState } from 'react'
import { Car, Key } from 'lucide-react'
import { fetchNui } from '../lib/nui'
import { applyTheme } from '../lib/theme'
import { EmptyRow, MenuFrame, MenuRow } from './ui'
import type { KeysPayload, VehItem } from './types'

type Category = 'primary' | 'secondary' | 'temporary'

// Player keys menu (/keyMenu) — drill-down: categories -> vehicles -> actions.
// Replaces the ox_context/ox_menu variant; the Lua side pushes the payload and
// the action callbacks reuse the same shared helpers, so behaviour is identical.
export function KeysApp({ data, onClose }: { data: KeysPayload; onClose: () => void }) {
  const s = data.strings
  const [cat, setCat] = useState<Category | null>(null)
  const [veh, setVeh] = useState<VehItem | null>(null)

  useEffect(() => {
    applyTheme(data.theme)
  }, [data.theme])

  // Escape / back-arrow: go up one level, or close at the top.
  const back = useCallback(() => {
    if (veh) setVeh(null)
    else if (cat) setCat(null)
    else onClose()
  }, [veh, cat, onClose])

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault()
        back()
      }
    }
    window.addEventListener('keyup', onKey)
    return () => window.removeEventListener('keyup', onKey)
  }, [back])

  // Fire an action, then close (context-menu behaviour). The Lua callback already
  // releases focus before running the action; onClose here just unmounts the view.
  const act = useCallback(
    async (endpoint: string, v: VehItem) => {
      await fetchNui(endpoint, { label: v.label, plate: v.plate, model: v.model })
      onClose()
    },
    [onClose],
  )

  const catTitle = (c: Category) =>
    c === 'primary' ? s.menu_primary_keys : c === 'secondary' ? s.menu_secondary_keys : s.menu_temporary_keys

  // Level 2: actions for the selected primary-key vehicle.
  if (cat === 'primary' && veh) {
    return (
      <MenuFrame title={`${veh.label} - ${veh.plate}`} brandTag={data.brandTag} onBack={back} onClose={onClose}>
        <MenuRow icon={<Key size={16} />} label={s.menu_give_secondary_keys} onClick={() => act('keys:giveSecondary', veh)} />
        {data.flags.showExchangeLocks ? (
          <MenuRow icon={<Key size={16} />} label={s.menu_exchange_locks} onClick={() => act('keys:exchangeLocks', veh)} />
        ) : null}
        {data.flags.showTransferVehicle ? (
          <MenuRow icon={<Key size={16} />} label={s.menu_transfer_vehicle} onClick={() => act('keys:transferVehicle', veh)} />
        ) : null}
      </MenuFrame>
    )
  }

  // Level 1: vehicle list for the chosen category. Primary drills into actions;
  // secondary/temporary are read-only (mirrors the old menus).
  if (cat) {
    const list = data.keys[cat] ?? []
    return (
      <MenuFrame title={catTitle(cat)} brandTag={data.brandTag} onBack={back} onClose={onClose}>
        {list.length === 0 ? (
          <EmptyRow label={s.menu_no_keys_available} />
        ) : (
          list.map((v, i) => (
            <MenuRow
              key={`${v.plate}-${i}`}
              icon={<Car size={16} />}
              label={v.label}
              sub={v.plate}
              arrow={cat === 'primary'}
              readOnly={cat !== 'primary'}
              onClick={cat === 'primary' ? () => setVeh(v) : undefined}
            />
          ))
        )}
      </MenuFrame>
    )
  }

  // Level 0: key categories.
  return (
    <MenuFrame title={s.menu_vehicle_keys} brandTag={data.brandTag} onClose={onClose}>
      <MenuRow icon={<Key size={16} />} label={s.menu_primary_keys} arrow onClick={() => setCat('primary')} />
      {data.flags.showSecondaryKeys ? (
        <MenuRow icon={<Key size={16} />} label={s.menu_secondary_keys} arrow onClick={() => setCat('secondary')} />
      ) : null}
      {data.flags.showTempKeys ? (
        <MenuRow icon={<Key size={16} />} label={s.menu_temporary_keys} arrow onClick={() => setCat('temporary')} />
      ) : null}
    </MenuFrame>
  )
}
