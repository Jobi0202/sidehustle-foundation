import { LeadMagnetForm } from '@/components/lead-magnet-form'
import { cn } from '@/lib/utils'

export interface HeroProps {
  className?: string
}

/**
 * Landing-page hero. Presentational only — copy is colocated, the email
 * capture is delegated to the LeadMagnetForm sibling component.
 */
export function Hero({ className }: HeroProps) {
  return (
    <section
      data-testid="hero-section"
      aria-labelledby="hero-heading"
      className={cn(
        'relative isolate flex min-h-[80vh] flex-col items-center justify-center px-6 py-24 text-center',
        className,
      )}
    >
      <div className="mx-auto max-w-2xl space-y-6">
        <p className="text-sm font-semibold uppercase tracking-widest text-muted-foreground">
          Side-hustle foundation
        </p>
        <h1
          id="hero-heading"
          className="text-balance text-4xl font-bold tracking-tight sm:text-5xl md:text-6xl"
        >
          Ship your MVP in days, not months.
        </h1>
        <p className="text-balance text-lg text-muted-foreground sm:text-xl">
          A pragmatic launch kit for solo founders. Drop your email and we&apos;ll
          send you the playbook the moment it&apos;s live.
        </p>
        <div className="mx-auto max-w-md pt-4">
          <LeadMagnetForm />
        </div>
      </div>
    </section>
  )
}
