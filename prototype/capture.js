const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const htmlFile = path.resolve(__dirname, 'ui-current.html');
const screenshotsDir = path.resolve(__dirname, 'screenshots');
if (!fs.existsSync(screenshotsDir)) fs.mkdirSync(screenshotsDir, { recursive: true });

async function captureScreens() {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({
    viewport: { width: 375, height: 852 },
    deviceScaleFactor: 2
  });

  await page.goto('file:///' + htmlFile, { waitUntil: 'networkidle' });
  await page.waitForTimeout(500);

  const screens = [
    { name: '01-onboarding-1', action: null },
    { name: '02-onboarding-2', action: async (p) => { await p.click('#ob-next'); await p.waitForTimeout(400); } },
    { name: '03-onboarding-3', action: async (p) => { await p.click('#ob-next'); await p.waitForTimeout(400); } },
    { name: '04-home', action: async (p) => { await p.click('.ob-skip'); await p.waitForTimeout(400); } },
    { name: '05-create', action: async (p) => { await p.evaluate(() => switchTab('create', document.querySelectorAll('.tab-item')[1])); await p.waitForTimeout(300); } },
    { name: '06-works', action: async (p) => { await p.evaluate(() => switchTab('works', document.querySelectorAll('.tab-item')[2])); await p.waitForTimeout(300); } },
    { name: '07-profile', action: async (p) => { await p.evaluate(() => switchTab('profile', document.querySelectorAll('.tab-item')[3])); await p.waitForTimeout(300); } },
    { name: '08-select-template', action: async (p) => { 
      await p.evaluate(() => switchTab('home', document.querySelectorAll('.tab-item')[0])); await p.waitForTimeout(300);
      await p.click('.section-title .more'); await p.waitForTimeout(400); 
    }},
    { name: '09-detail', action: async (p) => {
      await p.click('.select-card'); await p.waitForTimeout(400);
    }},
    { name: '10-upload', action: async (p) => {
      await p.click('.use-btn'); await p.waitForTimeout(400);
    }},
    { name: '11-result', action: async (p) => {
      await p.click('.gen-btn'); await p.waitForTimeout(400);
    }},
    { name: '12-share-sheet', action: async (p) => {
      await p.click('.btn-outline'); await p.waitForTimeout(400);
    }},
  ];

  // Go back to home first by reloading
  await page.goto('file:///' + htmlFile, { waitUntil: 'networkidle' });
  await page.waitForTimeout(500);

  for (const s of screens) {
    if (s.action) await s.action(page);
    await page.screenshot({ path: path.join(screenshotsDir, s.name + '.png'), clip: { x: 0, y: 0, width: 375, height: 852 } });
    console.log('✓ ' + s.name);
  }

  await browser.close();
  console.log('\nDone! Screenshots saved to: ' + screenshotsDir);
}

captureScreens().catch(e => { console.error(e); process.exit(1); });
