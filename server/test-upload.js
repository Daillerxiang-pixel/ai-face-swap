const fs = require('fs');
const path = require('path');
const http = require('http');

const boundary = '----FormBoundary' + Math.random().toString(36).slice(2);
const fileData = fs.readFileSync(path.join(__dirname, 'test_face.jpg'));

const before = '--' + boundary + '\r\nContent-Disposition: form-data; name="photo"; filename="test.jpg"\r\nContent-Type: image/jpeg\r\n\r\n';
const after = '\r\n--' + boundary + '--\r\n';
const body = Buffer.concat([Buffer.from(before), fileData, Buffer.from(after)]);

const req = http.request({
  hostname: 'localhost', port: 8080, path: '/api/upload/image', method: 'POST',
  headers: { 'Content-Type': 'multipart/form-data; boundary=' + boundary, 'Content-Length': body.length }
}, res => {
  let data = '';
  res.on('data', c => data += c);
  res.on('end', () => { console.log('Status:', res.statusCode); console.log('Body:', data.slice(0, 500)); process.exit(0); });
});
req.write(body);
req.end();
setTimeout(() => process.exit(1), 10000);
