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
      <div className="mx-auto max-w-3xl space-y-6">
        <p className="text-sm font-semibold uppercase tracking-widest text-muted-foreground">
          Für Eltern in Hessen
        </p>
        <h1
          id="hero-heading"
          className="text-balance text-4xl font-bold tracking-tight sm:text-5xl md:text-6xl"
        >
          Kein Elterngeld? Nutzt euren Bildungsurlaub für bis zu 10 Tage extra
          Elternzeit in Hessen.
        </h1>
        <p className="text-balance text-lg text-muted-foreground sm:text-xl">
          Hessen erlaubt jedem Beschäftigten bis zu 10 bezahlte Bildungstage pro
          Jahr. Unser kostenloser 5-Schritte-Guide zeigt euch, wie ihr sie
          rechtssicher beantragt und clever mit der Elternzeit kombiniert.
        </p>
        <div className="mx-auto max-w-md pt-4">
          <LeadMagnetForm />
        </div>
      </div>
    </section>
  )
}
