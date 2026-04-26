import { type ClassValue, clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'

/**
 * Merge Tailwind class names, resolving conflicts. Used by every shadcn/ui
 * primitive to compose `className` props without specificity surprises.
 */
export function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs))
}
