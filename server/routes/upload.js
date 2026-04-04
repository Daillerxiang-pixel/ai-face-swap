const { Router } = require('express');
const multer = require('multer');
const { v4: uuidv4 } = require('uuid');
const path = require('path');
const { getDb } = require('../data/database');
const { uploadToOSS, isOSSAvailable } = require('../utils/oss');
const { optionalAuthMiddleware } = require('../middleware/auth');

const router = Router();

/** 每次请求重新判断（避免只改了 .env 却忘了重启）；设 SKIP_OSS_UPLOAD=1 可强制只走本地 */
function shouldTryOSSUpload() {
  if (process.env.SKIP_OSS_UPLOAD === '1' || process.env.SKIP_OSS_UPLOAD === 'true') return false;
  return isOSSAvailable();
}

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

// POST /api/upload/image — 优先解析 JWT（multipart 须走 Header）；无 token 时仍可匿名上传
router.post('/image', optionalAuthMiddleware, (req, res, next) => {
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

    const saveLocal = () => {
      const fs = require('fs');
      const uploadsDir = path.join(__dirname, '..', '..', 'uploads');
      if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true });
      const localFilename = `${fileId}${ext}`;
      const abs = path.join(uploadsDir, localFilename);
      fs.writeFileSync(abs, req.file.buffer);
      return { filePath: abs, fileUrl: `/uploads/${localFilename}` };
    };

    let storageKind = 'local';

    if (shouldTryOSSUpload()) {
      try {
        const ossUrl = await uploadToOSS(req.file.buffer, ossKey, req.file.mimetype);
        fileUrl = ossUrl;
        filePath = ossKey;
        storageKind = 'oss';
        console.log(`[Upload] 文件已上传到 OSS: ${ossUrl}`);
      } catch (ossErr) {
        console.error('[Upload] OSS 上传失败，改存本地:', ossErr.message || ossErr);
        const local = saveLocal();
        fileUrl = local.fileUrl;
        filePath = local.filePath;
        storageKind = 'local';
        console.log(`[Upload] 文件已保存到本地: ${fileUrl}`);
      }
    } else {
      const local = saveLocal();
      fileUrl = local.fileUrl;
      filePath = local.filePath;
      storageKind = 'local';
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
        storage: storageKind
      }
    });
  } catch (err) {
    console.error('[Upload] 上传失败:', err);
    res.status(500).json({ success: false, error: '上传失败，请稍后重试' });
  }
});

module.exports = router;
