import { expect, test } from '@playwright/test'

test.describe('hero + lead-magnet form', () => {
  test('hero renders with heading and email capture', async ({ page }) => {
    await page.goto('/')

    const hero = page.getByTestId('hero-section')
    await expect(hero).toBeVisible()
    await expect(
      hero.getByRole('heading', { name: /ship your mvp in days/i, level: 1 }),
    ).toBeVisible()

    const form = page.getByTestId('lead-magnet-form')
    await expect(form).toBeVisible()
    await expect(form.getByLabel(/email address/i)).toBeVisible()
    await expect(form.getByRole('button', { name: /send me the playbook/i })).toBeVisible()
  })

  test('submitting a valid email triggers the alert with that email', async ({ page }) => {
    await page.goto('/')

    let dialogType = ''
    let dialogMessage = ''
    page.once('dialog', async (dialog) => {
      dialogType = dialog.type()
      dialogMessage = dialog.message()
      await dialog.accept()
    })

    await page.getByLabel(/email address/i).fill('jo@example.com')
    await page.getByRole('button', { name: /send me the playbook/i }).click()

    await expect.poll(() => dialogMessage).toContain('jo@example.com')
    expect(dialogType).toBe('alert')
  })

  test('blank email is rejected by native validation and no alert fires', async ({ page }) => {
    await page.goto('/')

    let dialogFired = false
    page.on('dialog', async (dialog) => {
      dialogFired = true
      await dialog.dismiss()
    })

    await page.getByRole('button', { name: /send me the playbook/i }).click()
    // Browser blocks submit -> no alert. Give the event loop a beat.
    await page.waitForTimeout(250)
    expect(dialogFired).toBe(false)

    const emailInput = page.getByLabel(/email address/i)
    const isInvalid = await emailInput.evaluate(
      (el) => (el as HTMLInputElement).validity.valueMissing,
    )
    expect(isInvalid).toBe(true)
  })
})
