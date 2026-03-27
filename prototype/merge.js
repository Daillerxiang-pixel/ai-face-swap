const { createCanvas, loadImage } = require('canvas');
const fs = require('fs');
const path = require('path');

const dir = path.resolve(__dirname, 'screenshots');
const files = fs.readdirSync(dir).filter(f => f.endsWith('.png')).sort();
const W = 375 * 2; // each screenshot is 750px wide (2x scale)
const H = 852 * 2; // 1704px tall
const PAD = 20;
const COLS = 4;
const ROWS = Math.ceil(files.length / COLS);

const canvas = createCanvas(COLS * W + (COLS - 1) * PAD, ROWS * H + (ROWS - 1) * PAD);
const ctx = canvas.getContext('2d');
ctx.fillStyle = '#111111';
ctx.fillRect(0, 0, canvas.width, canvas.height);

(async () => {
  for (let i = 0; i < files.length; i++) {
    const img = await loadImage(path.join(dir, files[i]));
    const col = i % COLS;
    const row = Math.floor(i / COLS);
    const x = col * (W + PAD);
    const y = row * (H + PAD);
    ctx.drawImage(img, x, y, W, H);
    // Page label
    ctx.fillStyle = 'rgba(124,58,237,0.9)';
    const label = files[i].replace('.png', '').replace(/^\d+-/, '');
    const tw = ctx.measureText(label).width;
    ctx.fillRect(x, y, Math.max(tw + 20, 140), 28);
    ctx.fillStyle = '#fff';
    ctx.font = '600 13px -apple-system, sans-serif';
    ctx.fillText(label, x + 10, y + 18);
  }
  
  const outPath = path.resolve(__dirname, 'ui-current-all-pages.png');
  const buf = canvas.toBuffer('image/png');
  fs.writeFileSync(outPath, buf);
  console.log('✅ Saved: ' + outPath);
  console.log('Size: ' + (buf.length / 1024 / 1024).toFixed(1) + 'MB');
  console.log('Dimensions: ' + canvas.width + 'x' + canvas.height);
})().catch(e => { console.error(e); process.exit(1); });
