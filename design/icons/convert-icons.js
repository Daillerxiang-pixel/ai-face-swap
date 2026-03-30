const { chromium } = require('C:/Users/xiangjj/AppData/Local/nvm/v22.16.0/node_modules/openclaw/node_modules/playwright-core');
const path = require('path');
const fs = require('fs');

const iconDir = __dirname;
const icons = ['icon-new-a', 'icon-new-b', 'icon-new-c'];

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  
  // Set viewport to 1024x1024
  await page.setViewportSize({ width: 1024, height: 1024 });
  
  for (const icon of icons) {
    const svgPath = path.join(iconDir, `${icon}.svg`);
    const pngPath = path.join(iconDir, `${icon}-1024.png`);
    
    // Read SVG content
    const svgContent = fs.readFileSync(svgPath, 'utf8');
    
    // Create HTML to render the SVG
    const html = `<!DOCTYPE html>
<html>
<head>
<style>
* { margin: 0; padding: 0; }
body { width: 1024px; height: 1024px; background: transparent; }
</style>
</head>
<body>${svgContent}</body>
</html>`;
    
    await page.setContent(html);
    
    // Wait for any animations/fonts to load
    await page.waitForTimeout(500);
    
    // Take screenshot
    await page.screenshot({ path: pngPath, omitBackground: true });
    console.log(`Generated: ${pngPath}`);
  }
  
  await browser.close();
  console.log('All icons generated!');
})();
