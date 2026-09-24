import { defineConfig } from '@playwright/test';

// Peg denne mod jeres Azure-VM inden I kører testene:
//   TARGET_URL=http://<public-ip> npx playwright test
// (eller http://<public-ip>:8080 hvis I beholder 8080-mappingen i stedet for at rette den til 80)
export default defineConfig({
  testDir: './tests',
  timeout: 30_000,
  retries: 1,
  use: {
    baseURL: process.env.TARGET_URL || 'http://localhost:8080',
    ignoreHTTPSErrors: true,
  },
  reporter: [['list'], ['html', { open: 'never' }]],
});
