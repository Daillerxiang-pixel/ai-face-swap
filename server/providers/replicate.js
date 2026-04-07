/**
 * Replicate Provider
 * 用于视频换脸 — Replicate API (facefusion 等模型)
 * 
 * Replicate 是异步的：创建 prediction → 轮询状态 → 获取结果
 */

const Replicate = require('replicate');
const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');

let replicateClient = null;
function getClient() {
  if (replicateClient) return replicateClient;
  replicateClient = new Replicate({
    auth: process.env.REPLICATE_API_TOKEN,
  });
  return replicateClient;
}

/**
 * 默认视频换脸模型配置
 */
const DEFAULT_VIDEO_MODEL = {
  // facefusion/facefusion — 支持图片+视频换脸
  owner: 'lucataco',
  name: 'facefusion',
  version: 'a3610f3ea899498e9b57d1a05fa5c62f48e8afcf2b9c28e0e49b8d2705c2e558',
  // 备选: camenduru/facefusion
  // owner: 'camenduru', name: 'facefusion',
};

/**
 * 生成视频换脸（异步 — 创建 prediction）
 * @param {Object} ctx
 * @param {string} ctx.sourceFilePath - 源图片文件路径
 * @param {Object} ctx.template - 模板记录
 * @param {string} ctx.genId - 生成记录 ID
 * @returns {Promise<{predictionId: string, status: string}>}
 */
async function generate(ctx) {
  const { sourceFilePath, template, genId } = ctx;
  const client = getClient();

  // 读取源图片为 base64 data URI
  const ext = path.extname(sourceFilePath).toLowerCase().replace('.', '') || 'png';
  const mimeType = ext === 'jpg' || ext === 'jpeg' ? 'image/jpeg' : 'image/png';
  const imgBuffer = fs.readFileSync(sourceFilePath);
  const base64Data = imgBuffer.toString('base64');
  const dataUri = `data:${mimeType};base64,${base64Data}`;

  // 模板中的视频 URL 或默认视频
  const targetVideoUrl = template.video_url || 'https://replicate.delivery/pbxt/JtTUsVkGnNQDZCQbOTWYgMexYMQXNQjSsUDrbQTbIuIxtsJHA/example.mp4';

  console.log(`[Replicate] Creating prediction: gen=${genId}, template=${template.name}`);
  console.log(`[Replicate] Model: ${DEFAULT_VIDEO_MODEL.owner}/${DEFAULT_VIDEO_MODEL.name}`);

  try {
    const prediction = await client.predictions.create({
      // model: `${DEFAULT_VIDEO_MODEL.owner}/${DEFAULT_VIDEO_MODEL.name}`,
      version: DEFAULT_VIDEO_MODEL.version,
      input: {
        source_image: dataUri,
        target_video: targetVideoUrl,
      },
    });

    console.log(`[Replicate] Prediction created: id=${prediction.id}, status=${prediction.status}`);

    return {
      predictionId: prediction.id,
      status: prediction.status, // 'starting' | 'processing' | 'succeeded' | 'failed' | 'canceled'
    };
  } catch (error) {
    console.error(`[Replicate] Prediction creation failed:`, error.message);
    throw new Error(`Replicate API failed: ${error.message}`);
  }
}

/**
 * 是否是异步模式
 */
function isAsync() {
  return true;
}

/**
 * 轮询异步任务状态
 * @param {string} predictionId - Replicate prediction ID
 * @returns {Promise<{status: string, progress: number, resultUrl?: string, error?: string}>}
 */
async function poll(predictionId) {
  const client = getClient();

  try {
    const prediction = await client.predictions.get(predictionId);

    // 解析结果
    if (prediction.status === 'succeeded') {
      let videoUrl = null;
      
      // Replicate 输出可能是字符串 URL 或对象
      if (typeof prediction.output === 'string') {
        videoUrl = prediction.output;
      } else if (Array.isArray(prediction.output)) {
        videoUrl = prediction.output[0];
      } else if (prediction.output && typeof prediction.output === 'object') {
        videoUrl = prediction.output.video || prediction.output.url || prediction.output.output;
      }

      if (!videoUrl) {
        console.error('[Replicate] Prediction succeeded but no output URL found:', JSON.stringify(prediction.output));
        return {
          status: 'failed',
          progress: 0,
          error: 'Generation finished but no output URL was returned',
        };
      }

      return {
        status: 'completed',
        progress: 100,
        resultUrl: videoUrl,
      };
    }

    if (prediction.status === 'failed' || prediction.status === 'canceled') {
      const errorMsg = prediction.error || `任务${prediction.status === 'canceled' ? '已取消' : '失败'}`;
      return {
        status: 'failed',
        progress: 0,
        error: errorMsg,
      };
    }

    // 'starting' | 'processing' — 根据日志计算大致进度
    let progress = 10;
    if (prediction.status === 'processing') {
      // 检查日志估算进度
      if (prediction.logs) {
        const logLines = prediction.logs.split('\n').length;
        progress = Math.min(90, 10 + logLines * 2);
      } else {
        progress = 50;
      }
    }

    return {
      status: 'processing',
      progress,
    };
  } catch (error) {
    console.error(`[Replicate] Poll failed for prediction ${predictionId}:`, error.message);
    return {
      status: 'processing',
      progress: 50,
      error: `查询状态失败: ${error.message}`,
    };
  }
}

/**
 * 下载远程视频到本地
 * @param {string} url - 视频下载地址
 * @param {string} genId - 生成记录 ID
 * @returns {Promise<{localPath: string, localUrl: string}>}
 */
async function downloadResult(url, genId) {
  return new Promise((resolve, reject) => {
    const resultDir = path.join(__dirname, '..', '..', 'uploads', 'results');
    if (!fs.existsSync(resultDir)) fs.mkdirSync(resultDir, { recursive: true });
    const localPath = path.join(resultDir, `${genId}.mp4`);
    const file = fs.createWriteStream(localPath);

    const protocol = url.startsWith('https') ? https : http;
    
    protocol.get(url, (response) => {
      if (response.statusCode >= 300 && response.statusCode < 400 && response.headers.location) {
        // 重定向
        downloadResult(response.headers.location, genId).then(resolve).catch(reject);
        return;
      }
      
      if (response.statusCode !== 200) {
        reject(new Error(`下载失败: HTTP ${response.statusCode}`));
        return;
      }

      response.pipe(file);
      file.on('finish', () => {
        file.close();
        resolve({
          localPath,
          localUrl: `/uploads/results/${genId}.mp4`,
        });
      });
    }).on('error', (err) => {
      fs.unlink(localPath, () => {}); // 清理
      reject(err);
    });

    file.on('error', reject);
  });
}

module.exports = { generate, isAsync, poll, downloadResult };
