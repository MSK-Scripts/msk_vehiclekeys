import { Component, type ReactNode } from 'react'

// Safety net for the dashboard. A render error inside a tab must NEVER unmount the
// whole app — in NUI that would leave the screen blank while the cursor stays
// captured (SetNuiFocus true), forcing a resource restart. Wrapping the tab content
// keeps the header (Close) and the Escape handler mounted, so the user can always
// close the dashboard and free the cursor.
export class ErrorBoundary extends Component<
  { children: ReactNode; fallback: (err: Error) => ReactNode },
  { error: Error | null }
> {
  state: { error: Error | null } = { error: null }

  static getDerivedStateFromError(error: Error) {
    return { error }
  }

  componentDidCatch(error: Error) {
    // Surfaces in the browser/CEF console for debugging.
    console.error('[msk_vehiclekeys admin] tab render error:', error)
  }

  render() {
    if (this.state.error) return this.props.fallback(this.state.error)
    return this.props.children
  }
}
