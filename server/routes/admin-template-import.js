/**
 * 管理端：Excel + ZIP 批量导入模板
 *
 * Excel 第一行为表头；预览图/视频路径为 ZIP 包内相对路径（不可用本机绝对路径）。
 * 与 multipart 同时上传：excel（.xlsx）、archive（.zip）
 */

const express = require('express');
const multer = require('multer');
const jwt = require('jsonwebtoken');
const fs = require('fs');
const path = require('path');
const os = require('os');
const crypto = require('crypto');
const XLSX = require('xlsx');
const AdmZip = require('adm-zip');
const { getDb } = require('../data/database');
const { uploadBuffer, isOSSAvailable } = require('../utils/oss');

// 须与 routes/admin.js 完全一致，否则下载/导入会 401 被前端当作登出
const JWT_SECRET = process.env.JWT_SECRET || 'ai-face-swap-admin-jwt-secret-2026';

function authMiddleware(req, res, next) {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ success: false, error: '未登录' });
  try {
    req.admin = jwt.verify(token, JWT_SECRET);
    next();
  } catch {
    return res.status(401).json({ success: false, error: '登录已过期，请重新登录' });
  }
}

const HEADER_MAP = [
  { key: 'name', aliases: ['模板名称', 'name', '名称'] },
  { key: 'scene', aliases: ['场景', 'scene', '分类', '模板分类'] },
  { key: 'type', aliases: ['类型', 'type'] },
  { key: 'provider', aliases: ['服务商', 'provider', '换脸api', '换脸API', 'API服务商'] },
  { key: 'preview_path', aliases: ['预览图路径', 'preview_path', '预览图', 'preview', '图片路径'] },
  { key: 'video_path', aliases: ['视频路径', 'video_path', '视频', 'video'] },
  { key: 'badge', aliases: ['标签', 'badge'] },
  { key: 'description', aliases: ['描述', 'description'] },
  { key: 'usage_count', aliases: ['热度', 'usage_count', '使用次数'] },
  { key: 'rating', aliases: ['评分', 'rating'] },
  { key: 'icon', aliases: ['图标', 'icon'] },
  { key: 'bg_gradient', aliases: ['背景渐变', 'bg_gradient', '背景'] },
  { key: 'provider_model_id', aliases: ['model_id', 'provider_model_id', 'Model ID', '模型ID'] },
];

function normalizeHeader(h) {
  if (h == null) return '';
  return String(h).replace(/\uFEFF/g, '').trim();
}

function mapRow(rawRow) {
  const out = {};
  const keys = Object.keys(rawRow);
  for (const { key, aliases } of HEADER_MAP) {
    for (const k of keys) {
      const nk = normalizeHeader(k);
      if (!nk) continue;
      if (aliases.some((a) => a.toLowerCase() === nk.toLowerCase())) {
        out[key] = rawRow[k];
        break;
      }
    }
  }
  return out;
}

function mimeFromExt(ext) {
  const e = ext.toLowerCase();
  const m = {
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.webp': 'image/webp',
    '.gif': 'image/gif',
    '.mp4': 'video/mp4',
    '.webm': 'video/webm',
    '.mov': 'video/quicktime',
  };
  return m[e] || 'application/octet-stream';
}

function safeJoinZipRoot(rootAbs, relPath) {
  const rel = String(relPath || '').replace(/\\/g, '/').replace(/^\/+/, '');
  if (!rel || rel.includes('..')) throw new Error('路径非法或为空');
  const resolved = path.resolve(rootAbs, rel);
  const rootResolved = path.resolve(rootAbs);
  if (!resolved.startsWith(rootResolved + path.sep) && resolved !== rootResolved) {
    throw new Error('路径不能跳出压缩包根目录');
  }
  return resolved;
}

async function storeMedia(buffer, originalExt) {
  const ext = originalExt || '.bin';
  const id = crypto.randomBytes(8).toString('hex');
  const filename = `${id}${ext}`;
  const subdir = 'template-import';

  if (isOSSAvailable()) {
    const { url, key } = await uploadBuffer(buffer, `uploads/${subdir}`, filename, mimeFromExt(ext));
    return { storageUrl: url, previewValue: url };
  }

  const uploadsRoot = path.join(__dirname, '..', '..', 'uploads', subdir);
  if (!fs.existsSync(uploadsRoot)) fs.mkdirSync(uploadsRoot, { recursive: true });
  const abs = path.join(uploadsRoot, filename);
  fs.writeFileSync(abs, buffer);
  const rel = `/uploads/${subdir}/${filename}`;
  return { storageUrl: rel, previewValue: rel };
}

const importUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 520 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const fn = (file.originalname || '').toLowerCase();
    if (file.fieldname === 'excel' && (fn.endsWith('.xlsx') || fn.endsWith('.xls'))) return cb(null, true);
    if (file.fieldname === 'archive' && fn.endsWith('.zip')) return cb(null, true);
    cb(new Error('请上传 .xlsx 与 .zip（archive 字段）'));
  },
});

function parseExcelBuffer(buf) {
  const wb = XLSX.read(buf, { type: 'buffer' });
  const sheetName = wb.SheetNames[0];
  if (!sheetName) throw new Error('Excel 无工作表');
  const sheet = wb.Sheets[sheetName];
  const rows = XLSX.utils.sheet_to_json(sheet, { defval: '', raw: false });
  return rows;
}

/** 与 mapRow 识别的中文表头一致，便于下载后直接改内容再上传 */
function buildImportTemplateBuffer() {
  const headers = [
    '模板名称',
    '场景',
    '类型',
    '服务商',
    '预览图路径',
    '视频路径',
    '标签',
    '描述',
    '热度',
    '评分',
    '图标',
    '背景渐变',
    'Model ID',
  ];
  const exampleImage = [
    '示例-图片模板',
    '电影',
    '图片',
    'akool',
    'items/example/preview.jpg',
    '',
    'new',
    '图片模板示例：预览图路径为 ZIP 内相对路径',
    '100',
    '4.8',
    '🎬',
    'linear-gradient(135deg,#667eea,#764ba2)',
    '',
  ];
  const exampleVideo = [
    '示例-视频模板',
    '舞台',
    '视频',
    'akool',
    'items/example/v_cover.jpg',
    'items/example/v_main.mp4',
    'hot',
    '视频模板示例：须同时填预览图与视频路径',
    '50',
    '4.7',
    '🎥',
    'linear-gradient(135deg,#6a11cb,#2575fc)',
    '',
  ];
  const aoa = [headers, exampleImage, exampleVideo];
  const ws = XLSX.utils.aoa_to_sheet(aoa);
  ws['!cols'] = [
    { wch: 20 },
    { wch: 10 },
    { wch: 8 },
    { wch: 10 },
    { wch: 32 },
    { wch: 32 },
    { wch: 8 },
    { wch: 36 },
    { wch: 8 },
    { wch: 8 },
    { wch: 8 },
    { wch: 42 },
    { wch: 28 },
  ];
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, '模板列表');
  const note = XLSX.utils.aoa_to_sheet([
    ['批量导入说明'],
    ['1. 修改「模板列表」工作表中的行，可删除示例行后按需复制增加；第一行为表头勿删。'],
    ['2. 「预览图路径」「视频路径」须与 ZIP 包内文件一致（正斜杠 /），不要使用本机 D:\\ 等绝对路径。'],
    ['3. 类型填：图片 或 视频；视频模板必须填写「视频路径」。'],
    ['4. 服务商：akool / tencent / replicate；腾讯云请在控制台先创建素材后填写 Model ID。'],
    ['5. 保存为 .xlsx 后，与打包好的 .zip 在「模板管理」页一并上传。'],
  ]);
  note['!cols'] = [{ wch: 90 }];
  XLSX.utils.book_append_sheet(wb, note, '填写说明');
  return XLSX.write(wb, { type: 'buffer', bookType: 'xlsx' });
}

function templateImportRoutes() {
  const router = express.Router();

  router.get('/templates/import-excel-template', authMiddleware, (req, res) => {
    try {
      const buf = buildImportTemplateBuffer();
      const asciiName = 'template-import-template.xlsx';
      const utf8Name = encodeURIComponent('模板批量导入模板.xlsx');
      res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      res.setHeader(
        'Content-Disposition',
        `attachment; filename="${asciiName}"; filename*=UTF-8''${utf8Name}`
      );
      res.send(Buffer.from(buf));
    } catch (e) {
      console.error('[import-excel-template]', e);
      res.status(500).json({ success: false, error: e.message || '生成模板失败' });
    }
  });

  router.post(
    '/templates/import-excel',
    authMiddleware,
    (req, res, next) => {
      importUpload.fields([
        { name: 'excel', maxCount: 1 },
        { name: 'archive', maxCount: 1 },
      ])(req, res, (err) => {
        if (err) {
          return res.status(400).json({ success: false, error: err.message || '文件上传失败' });
        }
        next();
      });
    },
    async (req, res) => {
      const excelFile = req.files?.excel?.[0];
      const zipFile = req.files?.archive?.[0];
      if (!excelFile || !zipFile) {
        return res.status(400).json({ success: false, error: '请同时上传 Excel（.xlsx）与资源压缩包（.zip）' });
      }

      let tempDir = null;
      try {
        const rows = parseExcelBuffer(excelFile.buffer);
        if (!rows.length) {
          return res.status(400).json({ success: false, error: 'Excel 无数据行（除表头外至少一行）' });
        }

        tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'tpl-import-'));
        const zip = new AdmZip(zipFile.buffer);
        zip.extractAllTo(tempDir, true);

        const db = getDb();
        const imported = [];
        const failed = [];

        for (let i = 0; i < rows.length; i++) {
          const excelRowIndex = i + 2;
          const raw = rows[i];
          const anyCell = Object.values(raw).some((v) => String(v ?? '').trim() !== '');
          if (!anyCell) continue;

          const row = mapRow(raw);
          const name = String(row.name || '').trim();
          if (!name) {
            failed.push({ row: excelRowIndex, error: '缺少模板名称' });
            continue;
          }

          const scene = String(row.scene || '通用').trim() || '通用';
          const type = String(row.type || '图片').trim();
          if (type !== '图片' && type !== '视频') {
            failed.push({ row: excelRowIndex, error: `类型须为「图片」或「视频」，当前: ${type}` });
            continue;
          }

          const provider = String(row.provider || 'akool').trim().toLowerCase();
          if (!['tencent', 'replicate', 'akool'].includes(provider)) {
            failed.push({ row: excelRowIndex, error: `不支持的服务商: ${provider}` });
            continue;
          }

          const previewRel = String(row.preview_path || '').trim();
          if (!previewRel) {
            failed.push({ row: excelRowIndex, error: '缺少预览图路径（ZIP 内相对路径）' });
            continue;
          }

          let videoRel = String(row.video_path || '').trim();
          if (type === '视频' && !videoRel) {
            failed.push({ row: excelRowIndex, error: '视频模板须填写视频路径' });
            continue;
          }
          if (type === '图片') videoRel = '';

          try {
            const previewAbs = safeJoinZipRoot(tempDir, previewRel);
            if (!fs.existsSync(previewAbs)) {
              throw new Error(`预览图不存在: ${previewRel}`);
            }
            const prevBuf = fs.readFileSync(previewAbs);
            const prevExt = path.extname(previewRel) || '.jpg';
            const prevStore = await storeMedia(prevBuf, prevExt);

            let videoUrlValue = '';
            if (type === '视频' && videoRel) {
              const videoAbs = safeJoinZipRoot(tempDir, videoRel);
              if (!fs.existsSync(videoAbs)) throw new Error(`视频不存在: ${videoRel}`);
              const vidBuf = fs.readFileSync(videoAbs);
              const vidExt = path.extname(videoRel) || '.mp4';
              const vidStore = await storeMedia(vidBuf, vidExt);
              videoUrlValue = vidStore.previewValue;
            }

            const icon = String(row.icon || '').trim();
            const bg_gradient = String(row.bg_gradient || '').trim();
            const badge = String(row.badge || '').trim();
            const description = String(row.description || '').trim();
            const provider_model_id = String(row.provider_model_id || '').trim();

            let usage_count = parseInt(String(row.usage_count || '0'), 10);
            if (Number.isNaN(usage_count) || usage_count < 0) usage_count = 0;
            let rating = parseFloat(String(row.rating || '4.8'));
            if (Number.isNaN(rating)) rating = 4.8;

            const result = db
              .prepare(
                `INSERT INTO templates (name, icon, bg_gradient, scene, type, badge, description, provider, provider_model_id, video_url, preview_url, usage_count, rating)
                 VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)`
              )
              .run(
                name,
                icon,
                bg_gradient,
                scene,
                type,
                badge,
                description,
                provider,
                provider_model_id,
                videoUrlValue,
                prevStore.previewValue,
                usage_count,
                rating
              );

            imported.push({
              row: excelRowIndex,
              id: result.lastInsertRowid,
              name,
            });
          } catch (e) {
            failed.push({ row: excelRowIndex, error: e.message || String(e) });
          }
        }

        res.json({
          success: true,
          data: {
            imported: imported.length,
            failed: failed.length,
            details: { ok: imported, errors: failed },
          },
        });
      } catch (err) {
        console.error('[admin-template-import]', err);
        res.status(400).json({ success: false, error: err.message || '导入失败' });
      } finally {
        if (tempDir && fs.existsSync(tempDir)) {
          try {
            fs.rmSync(tempDir, { recursive: true, force: true });
          } catch (_) {
            /* ignore */
          }
        }
      }
    }
  );
  return router;
}

module.exports = { templateImportRoutes };
