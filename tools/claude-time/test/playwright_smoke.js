// Playwright smoke test for the claude-time test container.
//
// Confirms Playwright + Chromium are wired correctly inside the container.
// Phase 3 of claude-time-test-containerization. This is the de-facto
// readiness signal for WP5 Phase 4 (the real Playwright behavioral test
// for the visualize dashboard).
//
// Usage (inside the container, after `run-in-container.sh start`):
//     tools/claude-time/test/run-in-container.sh exec node test/playwright_smoke.js
//
// Exits 0 on success, 1 on failure. Logs "smoke ok" on success.

const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.setContent('<title>smoke</title><body>hello smoke</body>');
  const title = await page.title();
  const body = await page.locator('body').textContent();
  await browser.close();
  if (title !== 'smoke' || body !== 'hello smoke') {
    console.error(`FAIL: title=${title} body=${body}`);
    process.exit(1);
  }
  console.log('smoke ok');
})().catch(err => {
  console.error('FAIL:', err.message);
  process.exit(1);
});
