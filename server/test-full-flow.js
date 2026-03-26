const http = require('http');

function post(path, body) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(body);
    const req = http.request({
      hostname: 'localhost', port: 8080, path, method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(data) }
    }, res => {
      let d = '';
      res.on('data', c => d += c);
      res.on('end', () => resolve(JSON.parse(d)));
    });
    req.write(data);
    req.end();
  });
}

async function test() {
  // Step 1: Upload
  console.log('=== Step 1: Upload ===');
  const fs = require('fs');
  const path = require('path');
  const boundary = '----FormBoundary' + Math.random().toString(36).slice(2);
  const fileData = fs.readFileSync(path.join(__dirname, 'test_face.jpg'));
  const before = '--' + boundary + '\r\nContent-Disposition: form-data; name="photo"; filename="test.jpg"\r\nContent-Type: image/jpeg\r\n\r\n';
  const after = '\r\n--' + boundary + '--\r\n';
  const body = Buffer.concat([Buffer.from(before), fileData, Buffer.from(after)]);

  const uploadRes = await new Promise((resolve, reject) => {
    const req = http.request({
      hostname: 'localhost', port: 8080, path: '/api/upload/image', method: 'POST',
      headers: { 'Content-Type': 'multipart/form-data; boundary=' + boundary, 'Content-Length': body.length }
    }, res => {
      let d = '';
      res.on('data', c => d += c);
      res.on('end', () => resolve(JSON.parse(d)));
    });
    req.write(body);
    req.end();
  });
  console.log('Upload result:', JSON.stringify(uploadRes));
  const fileId = uploadRes.data.fileId;

  // Step 2: Generate
  console.log('\n=== Step 2: Generate ===');
  const genRes = await post('/api/generate', { templateId: 1, sourceFileId: fileId, type: '图片' });
  console.log('Generate result:', JSON.stringify(genRes));

  // Step 3: Verify result image
  if (genRes.data && genRes.data.resultUrl) {
    console.log('\n=== Step 3: Check result image ===');
    const imgUrl = 'http://localhost:8080' + genRes.data.resultUrl;
    console.log('URL:', imgUrl);
    
    http.get(imgUrl, res => {
      console.log('Image status:', res.statusCode, 'Size:', res.headers['content-length']);
      process.exit(0);
    });
  } else {
    console.log('No result URL!');
    process.exit(1);
  }
}

test().catch(e => { console.error('FATAL:', e); process.exit(1); });
