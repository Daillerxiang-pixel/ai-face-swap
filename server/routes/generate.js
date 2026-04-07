/**
 * Generate Route — 多 Provider 统一生成接口
 * 
 * 流程：
 *   1. 验证源文件和模板
 *   2. 根据 template.provider 选择对应的 Provider
 *   3. 同步 Provider (腾讯云): 直接生成 → 返回结果
 *   4. 异步 Provider (Replicate): 创建任务 → 返回 predictionId → 客户端轮询 /api/generate/:id/status
 */

const { Router } = require('express');
const { v4: uuidv4 } = require('uuid');
const fs = require('fs');
const path = require('path');
const { getDb } = require('../data/database');
const providerRegistry = require('../providers');
const { isOSSAvailable, getOSSBaseURL, uploadToOSS } = require('../utils/oss');
const { authMiddleware } = require('../middleware/auth');

const router = Router();

// All routes require authentication
router.use(authMiddleware);

const USE_OSS = isOSSAvailable();

// ===== POST /api/generate =====
router.post('/', async (req, res) => {
  const { templateId, sourceFileId } = req.body;
  const db = getDb();
  const genId = uuidv4();

  // 须在 try 外声明：catch 中更新失败记录时也要能读到 autoSave
  const user = db.prepare('SELECT auto_save, monthly_usage, monthly_limit FROM users WHERE id = ?').get(req.userId);
  const autoSave = user ? (user.auto_save !== 0) : true;

  try {
    // 1. 次数限制
    const monthlyUsage = user?.monthly_usage || 0;
    const monthlyLimit = user?.monthly_limit || 50;
    if (monthlyUsage >= monthlyLimit) {
      return res.status(403).json({
        success: false,
        error: 'Monthly generation limit reached',
        errorCode: 'QUOTA_EXCEEDED',
        data: {
          monthlyUsage,
          monthlyLimit,
          remaining: 0,
        }
      });
    }

    // 2. 验证源文件
    const sourceRecord = db.prepare('SELECT * FROM upload_files WHERE id = ?').get(sourceFileId);
    if (!sourceRecord) {
      return res.status(400).json({ success: false, error: 'Source photo not found. Please upload again.' });
    }

    // 判断源文件是 OSS 路径还是本地路径
    let sourceFilePath = sourceRecord.file_path;
    let sourceFileUrl = null;

    if (sourceFilePath.startsWith('http://') || sourceFilePath.startsWith('https://')) {
      // 完整 OSS URL
      sourceFileUrl = sourceFilePath;
      console.log(`[Generate] 源文件在 OSS (URL): ${sourceFileUrl}`);
    } else if (sourceFilePath.startsWith('/uploads/') || sourceFilePath.startsWith('uploads/')) {
      // OSS key（如 uploads/xxx.jpg），拼接为完整 OSS URL
      sourceFileUrl = getOSSBaseURL() + '/' + sourceFilePath.replace(/^\//, '');
      console.log(`[Generate] 源文件在 OSS (key): ${sourceFileUrl}`);
    } else if (fs.existsSync(sourceFilePath)) {
      // 本地绝对路径：直接使用
      console.log(`[Generate] 源文件在本地: ${sourceFilePath}`);
    } else {
      return res.status(400).json({ success: false, error: 'Source photo not found. Please upload again.' });
    }

    // 3. 验证模板
    const template = db.prepare('SELECT * FROM templates WHERE id = ?').get(templateId);
    if (!template) {
      return res.status(404).json({ success: false, error: 'Template not found' });
    }

    const providerName = template.provider || 'tencent';
    const provider = providerRegistry.getProvider(providerName);

    // 4. Create generation record (skip if auto_save = 0)
    let genIdForDb = genId;
    if (autoSave) {
      db.prepare(
        'INSERT INTO generations (id, user_id, template_id, source_image, type, status, provider) VALUES (?,?,?,?,?,?,?)'
      ).run(genId, req.userId, templateId, sourceRecord.file_path, template.type, 'processing', providerName);
    }

    // 5. 更新使用统计
    db.prepare('UPDATE users SET monthly_usage = monthly_usage + 1, total_generated = total_generated + 1 WHERE id = ?')
      .run(req.userId);
    db.prepare('UPDATE templates SET usage_count = usage_count + 1 WHERE id = ?').run(templateId);

    // 6. 如果源文件在 OSS，先下载到本地临时文件
    if (sourceFileUrl) {
      const tmpDir = path.join(__dirname, '..', '..', 'uploads', 'tmp');
      if (!fs.existsSync(tmpDir)) fs.mkdirSync(tmpDir, { recursive: true });
      sourceFilePath = path.join(tmpDir, `${sourceFileId}${path.extname(sourceFileUrl) || '.jpg'}`);

      const response = await fetch(sourceFileUrl);
      const buffer = Buffer.from(await response.arrayBuffer());
      fs.writeFileSync(sourceFilePath, buffer);
      console.log(`[Generate] OSS 文件已下载到: ${sourceFilePath}`);
    }

    // 6. 调用 Provider 生成
    const ctx = {
      sourceFilePath: sourceFilePath,
      template,
      genId,
    };

    if (provider.async) {
      // ===== 异步模式 (Replicate) =====
      const result = await providerRegistry.callGenerate(providerName, ctx);

      // 保存 predictionId
      if (autoSave) {
        db.prepare("UPDATE generations SET prediction_id = ?, status = 'processing', progress = 10 WHERE id = ?")
          .run(result.predictionId, genId);
      }

      console.log(`🎬 [Async] gen=${genId}, provider=${providerName}, prediction=${result.predictionId}`);

      res.json({
        success: true,
        data: {
          generationId: genId,
          status: 'processing',
          progress: 10,
          async: true,
          predictionId: result.predictionId,
          text: 'Video processing, about 1–3 minutes...'
        }
      });

    } else {
      // ===== 同步模式 (腾讯云) =====
      const result = await providerRegistry.callGenerate(providerName, ctx);

      if (autoSave) {
        db.prepare(
          "UPDATE generations SET status = 'completed', progress = 100, result_image = ?, completed_at = datetime('now', 'localtime') WHERE id = ?"
        ).run(result.resultUrl, genId);
      }

      console.log(`✅ [Sync] gen=${genId}, provider=${providerName}`);

      res.json({
        success: true,
        data: {
          generationId: genId,
          status: 'completed',
          progress: 100,
          async: false,
          resultUrl: result.resultUrl,
          text: 'Done'
        }
      });
    }

  } catch (error) {
    console.error(`❌ Generation failed: gen=${genId}`, error.message);
    if (autoSave) {
      db.prepare(
        "UPDATE generations SET status = 'failed', error_message = ?, progress = 0 WHERE id = ?"
      ).run(error.message || 'Generation failed', genId);
    }

    res.json({
      success: true,
      data: {
        generationId: genId,
        status: 'failed',
        progress: 0,
        error: error.message || 'Generation failed',
        text: 'Generation failed'
      }
    });
  }
});

// ===== GET /api/generate/:id =====
router.get('/:id', (req, res) => {
  const db = getDb();
  const gen = db.prepare(
    'SELECT id, status, progress, result_image as resultUrl, error_message as error, type, prediction_id as predictionId, provider FROM generations WHERE id = ?'
  ).get(req.params.id);
  if (!gen) return res.status(404).json({ success: false, error: 'Job not found' });
  res.json({ success: true, data: gen });
});

// ===== GET /api/generate/:id/status — 轮询异步任务状态 =====
router.get('/:id/status', async (req, res) => {
  const db = getDb();
  const genId = req.params.id;

  const gen = db.prepare(
    'SELECT id, status, progress, result_image as resultUrl, error_message as error, prediction_id as predictionId, provider FROM generations WHERE id = ?'
  ).get(genId);

  if (!gen) return res.status(404).json({ success: false, error: 'Job not found' });

  // 如果已经完成或失败，直接返回
  if (gen.status === 'completed' || gen.status === 'failed' || gen.status === 'cancelled') {
    return res.json({ success: true, data: gen });
  }

  // 正在处理中 → 调用 Provider poll
  try {
    const pollResult = await providerRegistry.callPoll(gen.provider, gen.predictionId);

    if (pollResult.status === 'completed') {
      // Akool 结果 URL 有 IP 限制，服务器下载会 403
      // 直接返回原始 URL 给客户端，让客户端直接访问
      let finalUrl = pollResult.resultUrl;
      
      // 对于非 Akool provider，尝试下载到本地/OSS
      if (gen.provider !== 'akool') {
        const downloaded = await providerRegistry.downloadAsyncResult(gen.provider, pollResult.resultUrl, genId);
        if (downloaded) finalUrl = downloaded.localUrl;
      }

      db.prepare(
        "UPDATE generations SET status = 'completed', progress = 100, result_image = ?, completed_at = datetime('now', 'localtime') WHERE id = ?"
      ).run(finalUrl, genId);

      return res.json({
        success: true,
        data: {
          ...gen,
          status: 'completed',
          progress: 100,
          resultUrl: finalUrl,
        }
      });
    }

    if (pollResult.status === 'failed') {
      db.prepare(
        "UPDATE generations SET status = 'failed', error_message = ?, progress = 0 WHERE id = ?"
      ).run(pollResult.error, genId);

      return res.json({
        success: true,
        data: {
          ...gen,
          status: 'failed',
          progress: 0,
          error: pollResult.error,
        }
      });
    }

    // 仍在处理中
    db.prepare('UPDATE generations SET progress = ?, status = ? WHERE id = ?')
      .run(pollResult.progress, pollResult.status, genId);

    return res.json({
      success: true,
      data: {
        ...gen,
        status: pollResult.status,
        progress: pollResult.progress,
      }
    });

  } catch (error) {
    console.error(`❌ Poll failed: gen=${genId}`, error.message);
    // 不标记失败，让客户端继续轮询
    return res.json({
      success: true,
      data: {
        ...gen,
        status: 'processing',
        progress: gen.progress || 50,
      }
    });
  }
});

// ===== POST /api/generate/:id/cancel =====
router.post('/:id/cancel', (req, res) => {
  const db = getDb();
  db.prepare("UPDATE generations SET status = 'cancelled' WHERE id = ?").run(req.params.id);
  res.json({ success: true });
});

// ===== GET /api/generate/providers — 列出可用 Provider =====
router.get('/providers/list', (req, res) => {
  res.json({ success: true, data: providerRegistry.listProviders() });
});

module.exports = router;
