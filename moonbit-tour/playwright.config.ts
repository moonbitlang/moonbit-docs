import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "tests",
  workers: 1,
  timeout: 30_000,
  use: {
    baseURL: "http://127.0.0.1:4176",
    channel: process.env.PLAYWRIGHT_CHANNEL,
    locale: "en-US",
    viewport: { width: 1440, height: 1000 },
  },
  webServer: {
    command: "pnpm exec serve dist -l 4176",
    url: "http://127.0.0.1:4176",
  },
});
