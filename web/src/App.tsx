import { useCallback, useEffect, useState } from 'react'
import { fetchNui } from './lib/nui'
import { AdminApp } from './admin/AdminApp'
import { KeysApp } from './keys/KeysApp'
import { LocksmithApp } from './keys/LocksmithApp'
import type { AdminBootstrap } from './admin/types'
import type { KeysPayload, LocksmithPayload } from './keys/types'

// The NUI hosts three independent views over the single ui_page: the admin
// dashboard (openAdmin) and the two player menus (openKeys / openLocksmith).
// Only one is ever mounted at a time — the last open* message wins.
type View =
  | { kind: 'admin'; data: AdminBootstrap }
  | { kind: 'keys'; data: KeysPayload }
  | { kind: 'locksmith'; data: LocksmithPayload }
  | null

export default function App() {
  const [view, setView] = useState<View>(null)

  useEffect(() => {
    const listener = (event: MessageEvent) => {
      const msg = event.data as { action?: string; data?: unknown } | null
      if (!msg || !msg.action) return
      switch (msg.action) {
        case 'openAdmin':
          setView({ kind: 'admin', data: msg.data as AdminBootstrap })
          break
        case 'openKeys':
          setView({ kind: 'keys', data: msg.data as KeysPayload })
          break
        case 'openLocksmith':
          setView({ kind: 'locksmith', data: msg.data as LocksmithPayload })
          break
        case 'closeKeys':
        case 'closeLocksmith':
          setView(null)
          break
      }
    }
    window.addEventListener('message', listener)
    return () => window.removeEventListener('message', listener)
  }, [])

  const closeAdmin = useCallback(() => {
    setView(null)
    fetchNui('admin:close')
  }, [])

  const closeKeys = useCallback(() => {
    setView(null)
    fetchNui('keys:close')
  }, [])

  const closeLocksmith = useCallback(() => {
    setView(null)
    fetchNui('locksmith:close')
  }, [])

  if (!view) return null
  if (view.kind === 'admin') return <AdminApp data={view.data} onClose={closeAdmin} />
  if (view.kind === 'keys') return <KeysApp data={view.data} onClose={closeKeys} />
  return <LocksmithApp data={view.data} onClose={closeLocksmith} />
}
