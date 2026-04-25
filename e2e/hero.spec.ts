import { expect, test } from '@playwright/test'

const HEADLINE_PATTERN = /Kein Elterngeld\? Nutzt euren Bildungsurlaub/i
const BUTTON_PATTERN = /Kostenlosen 5-Schritte-Guide anfordern/i
const EMAIL_LABEL_PATTERN = /E-Mail-Adresse/i

test.describe('hero + lead-magnet form', () => {
  test('hero renders with headline, email field, and clickable button', async ({
    page,
  }) => {
    await page.goto('/')

    const hero = page.getByTestId('hero-section')
    await expect(hero).toBeVisible()
    await expect(
      hero.getByRole('heading', { name: HEADLINE_PATTERN, level: 1 }),
    ).toBeVisible()

    const form = page.getByTestId('lead-magnet-form')
    await expect(form).toBeVisible()
    await expect(form.getByLabel(EMAIL_LABEL_PATTERN)).toBeVisible()

    const button = form.getByRole('button', { name: BUTTON_PATTERN })
    await expect(button).toBeVisible()
    await expect(button).toBeEnabled()
  })

  test('submitting a valid email triggers the success alert', async ({ page }) => {
    await page.goto('/')

    let dialogType = ''
    let dialogMessage = ''
    page.once('dialog', async (dialog) => {
      dialogType = dialog.type()
      dialogMessage = dialog.message()
      await dialog.accept()
    })

    await page.getByLabel(EMAIL_LABEL_PATTERN).fill('eltern@beispiel.de')
    await page.getByRole('button', { name: BUTTON_PATTERN }).click()

    await expect.poll(() => dialogMessage).toContain('eltern@beispiel.de')
    expect(dialogType).toBe('alert')
  })

  test('blank email is rejected by native validation and no alert fires', async ({
    page,
  }) => {
    await page.goto('/')

    let dialogFired = false
    page.on('dialog', async (dialog) => {
      dialogFired = true
      await dialog.dismiss()
    })

    await page.getByRole('button', { name: BUTTON_PATTERN }).click()
    await page.waitForTimeout(250)
    expect(dialogFired).toBe(false)

    const emailInput = page.getByLabel(EMAIL_LABEL_PATTERN)
    const isValueMissing = await emailInput.evaluate(
      (el) => (el as HTMLInputElement).validity.valueMissing,
    )
    expect(isValueMissing).toBe(true)
  })
})
