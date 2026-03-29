const { Router } = require('express');
const multer = require('multer');
const { v4: uuidv4 } = require('uuid');
const path = require('path');
const { getDb } = require('../data/database');
const { uploadToOSS, getOSSUrl } = require('../utils/oss');

const router = Router();

// 是否启用 OSS
const USE_OSS = !!process.env.OSS_ACCESS_KEY_ID;

// 内存存储（用于 OSS 上传）+ 磀测文件类型
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
  fileFilter: (req, file, cb) => {
    const allowed = ['.jpg', '.jpeg', '.png', '.webp'];
    const ext = path.extname(file.originalname).toLowerCase();
    if (allowed.includes(ext)) cb(null, true);
    else cb(new Error('不支持的文件格式，请上传 JPG/PNG/WEBP'));
  }
});

// POST /api/upload/image — upload user photo
router.post('/image', (req, res, next) => {
  upload.single('photo')(req, res, (err) => {
    if (err) {
      if (err.code === 'LIMIT_FILE_SIZE') {
        return res.status(400).json({ success: false, error: '文件大小不能超过 10MB' });
      }
      if (err instanceof multer.MulterError) {
        return res.status(400).json({ success: false, error: '上传失败：' + err.message });
      }
      return res.status(400).json({ success: false, error: err.message || '上传失败' });
    }
    next();
  });
}, async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ success: false, error: '请选择文件' });

    const db = getDb();
    const fileId = uuidv4();
    const ext = path.extname(req.file.originalname);
    const ossKey = `uploads/${fileId}${ext}`;

    let fileUrl;
    let filePath;

    if (USE_OSS) {
      // 上传到 OSS
      const ossUrl = await uploadToOSS(req.file.buffer, ossKey, req.file.mimetype);
      fileUrl = ossUrl;
      filePath = ossKey;
      console.log(`[Upload] 文件已上传到 OSS: ${ossUrl}`);
    } else {
      // 回退到本地存储
      const fs = require('fs');
      const uploadsDir = path.join(__dirname, '..', '..', 'uploads');
      if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true });

      const localFilename = `${fileId}${ext}`;
      filePath = path.join(uploadsDir, localFilename);
      fs.writeFileSync(filePath, req.file.buffer);
      fileUrl = `/uploads/${localFilename}`;
      console.log(`[Upload] 文件已保存到本地: ${fileUrl}`);
    }

    // 记录到数据库
    db.prepare(
      'INSERT INTO upload_files (id, user_id, original_name, file_path, file_size, mime_type) VALUES (?,?,?,?,?,?)'
    ).run(fileId, req.userId || 'anonymous', req.file.originalname, filePath, req.file.size, req.file.mimetype);

    res.json({
      success: true,
      data: {
        fileId,
        originalName: req.file.originalname,
        url: fileUrl,
        size: req.file.size,
        storage: USE_OSS ? 'oss' : 'local'
      }
    });
  } catch (err) {
    console.error('[Upload] 上传失败:', err);
    res.status(500).json({ success: false, error: '上传失败：' + (err.message || '服务器错误') });
  }
});

module.exports = router;
