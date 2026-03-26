const db = require('/var/www/ai-face-swap/server/node_modules/better-sqlite3');
const conn = db('/var/www/ai-face-swap/server/data/face_swap.db');
const r = conn.prepare("SELECT id,status,result_image,error_message,completed_at FROM generations ORDER BY rowid DESC LIMIT 5").all();
r.forEach(row => {
  console.log("ID:", row.id.slice(0,8), "| Status:", row.status, "| Result:", row.result_image || "NULL", "| Error:", row.error_message || "NULL");
});
