const db = require('better-sqlite3')('/var/www/ai-face-swap/server/data/face_swap.db');
const r = db.prepare('SELECT id,status,result_image,error_message,completed_at FROM generations ORDER BY created_at DESC LIMIT 5').all();
console.log(JSON.stringify(r, null, 2));
