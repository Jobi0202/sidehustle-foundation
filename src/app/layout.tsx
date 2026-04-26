import type { Metadata } from 'next'
import type { ReactNode } from 'react'

import './globals.css'

export const metadata: Metadata = {
  title: 'Bildungsurlaub als Elterngeld-Ersatz in Hessen',
  description:
    'Kostenloser 5-Schritte-Guide: bis zu 10 Tage bezahlten Bildungsurlaub clever mit der Elternzeit kombinieren.',
}

export default function RootLayout({
  children,
}: {
  children: ReactNode
}) {
  return (
    <html lang="de">
      <body className="min-h-screen bg-background text-foreground antialiased">
        {children}
      </body>
    </html>
  )
}
