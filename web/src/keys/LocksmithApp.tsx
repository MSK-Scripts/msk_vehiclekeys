import { useCallback, useEffect } from 'react'
import { Car } from 'lucide-react'
import { fetchNui } from '../lib/nui'
import { applyTheme } from '../lib/theme'
import { EmptyRow, MenuFrame, MenuRow } from './ui'
import type { LocksmithPayload, VehItem } from './types'

// Locksmith menu — a flat list of the player's vehicles; selecting one exchanges
// its locks. Replaces the ox_context/ox_menu locksmith variant.
export function LocksmithApp({ data, onClose }: { data: LocksmithPayload; onClose: () => void }) {
  const s = data.strings

  useEffect(() => {
    applyTheme(data.theme)
  }, [data.theme])

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault()
        onClose()
      }
    }
    window.addEventListener('keyup', onKey)
    return () => window.removeEventListener('keyup', onKey)
  }, [onClose])

  const exchange = useCallback(
    async (v: VehItem) => {
      await fetchNui('locksmith:exchange', { label: v.label, plate: v.plate, model: v.model })
      onClose()
    },
    [onClose],
  )

  return (
    <MenuFrame title={s.menu_locksmith_title} brandTag={data.brandTag} onClose={onClose}>
      {data.vehicles.length === 0 ? (
        <EmptyRow label={s.menu_no_keys_available} />
      ) : (
        data.vehicles.map((v, i) => (
          <MenuRow
            key={`${v.plate}-${i}`}
            icon={<Car size={16} />}
            label={v.label}
            sub={`${v.plate} · ${s.menu_locksmith_exchangelocks}`}
            onClick={() => exchange(v)}
          />
        ))
      )}
    </MenuFrame>
  )
}
