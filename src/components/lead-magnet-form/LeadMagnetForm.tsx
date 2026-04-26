'use client'

import { type FormEvent, useState } from 'react'

import { Button, Input, Label } from '@/components/ui'
import { cn } from '@/lib/utils'

export interface LeadMagnetFormProps {
  className?: string
  /**
   * Override the submit behavior — useful for tests and for swapping in a
   * real backend later. When omitted, a browser `alert()` confirms receipt
   * (PoC behavior, no network).
   */
  onSubmit?: (email: string) => void
}

/**
 * Email capture form for the landing-page lead magnet. Presentational + local
 * state only — no fetch, no DB. The default submit handler raises a browser
 * alert so the PoC can be verified end-to-end without a backend.
 */
export function LeadMagnetForm({ className, onSubmit }: LeadMagnetFormProps) {
  const [email, setEmail] = useState('')

  function handleSubmit(event: FormEvent<HTMLFormElement>): void {
    event.preventDefault()
    if (onSubmit) {
      onSubmit(email)
      return
    }
    window.alert(
      `Vielen Dank! Wir schicken den 5-Schritte-Guide an ${email}.`,
    )
  }

  return (
    <form
      data-testid="lead-magnet-form"
      onSubmit={handleSubmit}
      className={cn('flex flex-col gap-3 sm:flex-row sm:items-end', className)}
    >
      <div className="flex-1 text-left">
        <Label htmlFor="lead-magnet-email" className="sr-only">
          E-Mail-Adresse
        </Label>
        <Input
          id="lead-magnet-email"
          name="email"
          type="email"
          required
          autoComplete="email"
          placeholder="name@beispiel.de"
          value={email}
          onChange={(event) => setEmail(event.target.value)}
        />
      </div>
      <Button type="submit" size="lg" className="sm:w-auto">
        Kostenlosen 5-Schritte-Guide anfordern
      </Button>
    </form>
  )
}
