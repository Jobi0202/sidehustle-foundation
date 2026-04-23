import { test, expect } from '@playwright/test'

// Placeholder E2E test so Gate 1 passes on the empty template.
// Delete this file once the first real feature test lands.
test.describe('template smoke', () => {
  test('test runner is alive', async () => {
    expect(1 + 1).toBe(2)
  })
})
