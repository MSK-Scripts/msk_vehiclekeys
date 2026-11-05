import type { ReactNode } from 'react'
import { ArrowLeft, ChevronRight, X } from 'lucide-react'

// Compact menu window shared by the keys and locksmith player UIs. Matches the
// admin dashboard's MSK panel styling (bg-panel, border, shadow) at a smaller scale.
export function MenuFrame({
  title,
  brandTag,
  onBack,
  onClose,
  children,
}: {
  title: string
  brandTag?: string
  onBack?: () => void
  onClose: () => void
  children: ReactNode
}) {
  return (
    <div className="pointer-events-none flex h-full w-full items-center justify-center font-sans">
      <div className="msk-panel pointer-events-auto flex w-[360px] max-w-[92vw] flex-col overflow-hidden animate-slide-up">
        <div className="flex items-center gap-2 border-b border-border px-3 py-3">
          {onBack ? (
            <button
              onClick={onBack}
              aria-label="Back"
              className="flex h-8 w-8 items-center justify-center rounded-sm text-text-muted transition-colors hover:bg-input hover:text-text-primary"
            >
              <ArrowLeft size={17} />
            </button>
          ) : (
            <span className="h-8 w-8" />
          )}
          <div className="flex flex-1 items-center justify-center gap-2 overflow-hidden">
            <span className="truncate font-display text-[15px] font-semibold text-text-primary">{title}</span>
            {brandTag ? (
              <span className="shrink-0 rounded-sm bg-accent/15 px-1.5 py-0.5 font-mono text-[9px] uppercase tracking-[0.1em] text-accent">
                {brandTag}
              </span>
            ) : null}
          </div>
          <button
            onClick={onClose}
            aria-label="Close"
            className="flex h-8 w-8 items-center justify-center rounded-sm text-text-muted transition-colors hover:bg-input hover:text-text-primary"
          >
            <X size={17} />
          </button>
        </div>
        <div className="msk-scroll flex max-h-[60vh] flex-col gap-1.5 overflow-y-auto p-2.5">{children}</div>
      </div>
    </div>
  )
}

// A single selectable (or read-only) menu entry.
export function MenuRow({
  icon,
  label,
  sub,
  onClick,
  arrow,
  readOnly,
}: {
  icon?: ReactNode
  label: string
  sub?: string
  onClick?: () => void
  arrow?: boolean
  readOnly?: boolean
}) {
  const clickable = !!onClick && !readOnly
  return (
    <button
      type="button"
      disabled={!clickable}
      onClick={onClick}
      className={`flex w-full items-center gap-3 rounded-sm border border-border bg-input px-3 py-2.5 text-left transition-colors ${
        clickable ? 'hover:border-border-accent hover:bg-white/5' : 'cursor-default'
      }`}
    >
      {icon ? <span className="shrink-0 text-accent">{icon}</span> : null}
      <span className="flex min-w-0 flex-1 flex-col">
        <span className="truncate font-sans text-[13px] text-text-primary">{label}</span>
        {sub ? (
          <span className="truncate font-mono text-[10px] uppercase tracking-[0.06em] text-text-muted">{sub}</span>
        ) : null}
      </span>
      {arrow ? <ChevronRight size={16} className="shrink-0 text-text-muted" /> : null}
    </button>
  )
}

// Placeholder row shown when a list is empty.
export function EmptyRow({ label }: { label: string }) {
  return (
    <div className="rounded-sm border border-dashed border-border px-3 py-4 text-center font-sans text-[12px] text-text-muted">
      {label}
    </div>
  )
}
