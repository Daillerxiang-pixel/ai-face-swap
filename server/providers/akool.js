/**
 * Akool Face Swap Provider
 * 图片换脸 Pro (V4) + 视频换脸 (V3)
 * 
 * API 文档: https://docs.akool.com/ai-tools-suite/faceswap
 * 认证方式: x-api-key header
 */

const https = require('https');
const http = require('http');
const fs = require('fs');
const path = require('path');

const AKOOL_API_KEY = process.env.AKOOL_API_KEY || '';
const AKOOL_BASE_URL = 'openapi.akool.com';

// API 端点
const ENDPOINTS = {
  // Face Swap Pro (V4) — 最高画质，单人脸，不需要人脸检测
  imagePro: '/api/open/v4/faceswap/faceswapByImage',
  // Image Faceswap (V3) — 高质量，支持多人脸
  imageV3: '/api/open/v3/faceswap/highquality/specifyimage',
  // Video Faceswap (V3) — 视频换脸
  videoV3: '/api/open/v3/faceswap/highquality/specifyvideo',
  // Face Detection (新版)
  faceDetect: '/interface/detect-api/detect_faces',
  // 查询结果
  getResult: '/api/open/v3/faceswap/result/listbyids',
  // 查询余额
  getCredit: '/api/open/v3/faceswap/quota/info',
};

/**
 * Akool API 请求封装
 */
function akoolRequest(method, endpointPath, body = null) {
  return new Promise((resolve, reject) => {
    const isHttps = true; // openapi.akool.com is HTTPS
    const data = body ? JSON.stringify(body) : null;

    const options = {
      hostname: AKOOL_BASE_URL,
      path: endpointPath,
      method,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': AKOOL_API_KEY,
      },
      timeout: 120000, // 2 min timeout for generation
    };

    if (data) {
      options.headers['Content-Length'] = Buffer.byteLength(data);
    }

    const transport = isHttps ? https : http;
    const req = transport.request(options, res => {
      let resp = '';
      res.on('data', c => resp += c);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(resp);
          if (parsed.code === 1000 || parsed.error_code === 0) {
            resolve(parsed);
          } else {
            reject(new Error(`Akool API error: code=${parsed.code || parsed.error_code}, msg=${parsed.msg || parsed.error_msg || 'Unknown error'}`));
          }
        } catch (e) {
          reject(new Error(`Akool API parse error: ${resp.substring(0, 200)}`));
        }
      });
    });

    req.on('error', e => reject(new Error(`Akool API request failed: ${e.message}`)));
    req.on('timeout', () => { req.destroy(); reject(new Error('Akool API request timeout')); });

    if (data) req.write(data);
    req.end();
  });
}

/**
 * 人脸检测（用于 V3 API 获取 opts 参数）
 * @param {string} imageUrl - 图片 URL
 * @returns {Promise<{landmarks_str: string, crop_landmarks: string}>}
 */
async function detectFaces(imageUrl) {
  const result = await akoolRequest('POST', ENDPOINTS.faceDetect, {
    url: imageUrl,
    single_face: true, // 只检测最大的人脸
  });

  const faces = result.faces_obj?.['0'];
  if (!faces || !faces.landmarks_str || faces.landmarks_str.length === 0) {
    throw new Error('未检测到人脸');
  }

  return {
    landmarks_str: faces.landmarks_str[0], // 旧格式
    crop_landmarks: faces.crop_landmarks,   // 新格式 (V4 兼容)
    face_url: faces.face_urls ? faces.face_urls[0] : null,
  };
}

/**
 * 上传本地图片到临时可访问的 URL（Akool API 需要公网 URL）
 * 使用 OSS 上传，返回公网 URL
 * @param {string} filePath - 本地文件路径
 * @param {Object} ctx - 包含 genId 等
 * @returns {Promise<string>} 公网可访问的 URL
 */
async function uploadToPublicUrl(filePath, ctx) {
  // 尝试使用 OSS 上传
  try {
    const { isOSSAvailable, getOSSBaseURL, uploadToOSS } = require('../utils/oss');
    if (isOSSAvailable()) {
      const key = `uploads/temp/${ctx.genId}_${path.basename(filePath)}`;
      await uploadToOSS(key, fs.readFileSync(filePath));
      return getOSSBaseURL() + '/' + key;
    }
  } catch (e) {
    console.warn('[Akool] OSS upload failed, trying base64 approach:', e.message);
  }

  throw new Error('需要 OSS 存储来上传图片到公网 URL，请配置 OSS 环境变量');
}

/**
 * 生成图片换脸 — 使用 Face Swap Pro (V4)
 * 最高画质，单人脸，不需要人脸检测
 * 
 * @param {Object} ctx
 * @param {string} ctx.sourceFilePath - 源图片（用户人脸）文件路径
 * @param {Object} ctx.template - 模板记录
 * @param {string} ctx.genId - 生成记录 ID
 * @returns {Promise<{resultPath: string, resultUrl: string, predictionId: string}>}
 */
async function generateImagePro(ctx) {
  const { sourceFilePath, template, genId } = ctx;

  // 上传源图片到公网 URL
  const sourceUrl = await uploadToPublicUrl(sourceFilePath, ctx);
  console.log(`[Akool Pro] Source URL: ${sourceUrl}`);

  // 模板预览图作为目标图片（需要有公网 URL）
  let targetUrl = template.previewUrl || template.videoUrl;
  if (!targetUrl || (!targetUrl.startsWith('http://') && !targetUrl.startsWith('https://'))) {
    // 如果 previewUrl 是相对路径，拼接 OSS
    try {
      const { getOSSBaseURL } = require('../utils/oss');
      targetUrl = getOSSBaseURL() + (targetUrl.startsWith('/') ? '' : '/') + targetUrl;
    } catch (e) {
      throw new Error(`模板图片 URL 无效: ${targetUrl}`);
    }
  }
  console.log(`[Akool Pro] Target URL: ${targetUrl}`);

  // 调用 Face Swap Pro (V4)
  const result = await akoolRequest('POST', ENDPOINTS.imagePro, {
    sourceImage: [{ path: sourceUrl }],
    targetImage: [{ path: targetUrl }],
    model_name: 'akool_faceswap_image_hq',
    face_enhance: true, // 启用人脸增强
    single_face_mode: true,
  });

  console.log(`[Akool Pro] Submit success: _id=${result.data?._id}, job_id=${result.data?.job_id}`);

  return {
    predictionId: result.data?._id || result.data?.job_id,
    jobId: result.data?.job_id,
    status: 'processing',
  };
}

/**
 * 生成视频换脸 — 使用 Video Faceswap (V3)
 * 需要先做人脸检测获取 opts
 * 
 * @param {Object} ctx
 * @param {string} ctx.sourceFilePath - 源图片（用户人脸）文件路径
 * @param {Object} ctx.template - 模板记录
 * @param {string} ctx.genId - 生成记录 ID
 * @returns {Promise<{predictionId: string, status: string}>}
 */
async function generateVideo(ctx) {
  const { sourceFilePath, template, genId } = ctx;

  // 上传源图片到公网 URL
  const sourceUrl = await uploadToPublicUrl(sourceFilePath, ctx);
  console.log(`[Akool Video] Source URL: ${sourceUrl}`);

  // 视频模板的 videoUrl 作为目标视频
  let videoUrl = template.videoUrl;
  if (!videoUrl || (!videoUrl.startsWith('http://') && !videoUrl.startsWith('https://'))) {
    throw new Error(`模板视频 URL 无效: ${videoUrl}`);
  }

  // 人脸检测 — 源图片
  console.log('[Akool Video] Detecting source face...');
  const sourceDetect = await detectFaces(sourceUrl);
  console.log(`[Akool Video] Source landmarks: ${sourceDetect.crop_landmarks || sourceDetect.landmarks_str}`);

  // 人脸检测 — 从视频第一帧检测目标人脸
  // 视频人脸检测需要用视频 URL，但 detect API 支持 URL
  // Akool 的 detect API 也支持视频，但这里我们直接用视频的预览图
  let targetDetect = null;
  if (template.previewUrl) {
    let previewUrl = template.previewUrl;
    if (!previewUrl.startsWith('http')) {
      try {
        const { getOSSBaseURL } = require('../utils/oss');
        previewUrl = getOSSBaseURL() + (previewUrl.startsWith('/') ? '' : '/') + previewUrl;
      } catch (e) { /* ignore */ }
    }
    console.log(`[Akool Video] Detecting target face from preview: ${previewUrl}`);
    try {
      targetDetect = await detectFaces(previewUrl);
      console.log(`[Akool Video] Target landmarks: ${targetDetect.crop_landmarks || targetDetect.landmarks_str}`);
    } catch (e) {
      console.warn(`[Akool Video] Target face detect failed: ${e.message}, will retry without opts`);
    }
  }

  // 调用视频换脸
  const requestBody = {
    sourceImage: [{
      path: sourceDetect.face_url || sourceUrl,
      opts: sourceDetect.crop_landmarks || sourceDetect.landmarks_str,
    }],
    face_enhance: 1,
    modifyVideo: videoUrl,
    webhookUrl: '',
  };

  if (targetDetect) {
    requestBody.targetImage = [{
      path: targetDetect.face_url || template.previewUrl,
      opts: targetDetect.crop_landmarks || targetDetect.landmarks_str,
    }];
  }

  const result = await akoolRequest('POST', ENDPOINTS.videoV3, requestBody);
  console.log(`[Akool Video] Submit success: _id=${result.data?._id}, job_id=${result.data?.job_id}`);

  return {
    predictionId: result.data?._id || result.data?.job_id,
    jobId: result.data?.job_id,
    status: 'processing',
  };
}

/**
 * 主生成入口 — 根据模板类型选择 Pro/V3/Video
 */
async function generate(ctx) {
  const { template } = ctx;
  const type = template.type || '图片';

  if (type === '视频') {
    return generateVideo(ctx);
  }

  // 图片换脸：默认使用 Pro (V4)
  return generateImagePro(ctx);
}

/**
 * 轮询异步任务状态
 * Akool 的所有换脸都是异步的（返回 job_id，需要轮询获取结果）
 * 
 * @param {string} predictionId - 任务 ID (_id)
 * @returns {Promise<{status: string, progress: number, resultUrl?: string, error?: string}>}
 */
async function poll(predictionId) {
  const result = await akoolRequest('GET', `${ENDPOINTS.getResult}?_ids=${predictionId}`);

  if (!result.data || !result.data.result || result.data.result.length === 0) {
    return { status: 'processing', progress: 30 };
  }

  const job = result.data.result[0];
  const faceswapStatus = job.faceswap_status;

  // 1=队列中, 2=处理中, 3=成功, 4=失败
  switch (faceswapStatus) {
    case 1:
      return { status: 'processing', progress: 20 };
    case 2:
      return { status: 'processing', progress: 60 };
    case 3:
      // 成功 — URL 有效期 7 天，需立即下载保存
      if (!job.url) {
        return { status: 'failed', error: '结果 URL 为空' };
      }
      return {
        status: 'completed',
        progress: 100,
        resultUrl: job.url,
      };
    case 4:
      return { status: 'failed', error: 'Akool 换脸处理失败，请检查输入图片' };
    default:
      return { status: 'processing', progress: 30 };
  }
}

/**
 * 下载异步结果到本地
 * Akool 结果 URL 有效期 7 天，下载后保存到本地/OSS
 */
async function downloadResult(resultUrl, genId) {
  const resultDir = path.join(__dirname, '..', '..', 'uploads', 'results');
  if (!fs.existsSync(resultDir)) fs.mkdirSync(resultDir, { recursive: true });

  // 判断结果是图片还是视频
  const ext = resultUrl.includes('.mp4') ? '.mp4' : '.png';
  const localPath = path.join(resultDir, `${genId}${ext}`);
  const localUrl = `/uploads/results/${genId}${ext}`;

  // 下载文件
  await new Promise((resolve, reject) => {
    const file = fs.createWriteStream(localPath);
    https.get(resultUrl, { rejectUnauthorized: false }, (response) => {
      if (response.statusCode >= 300 && response.statusCode < 400 && response.headers.location) {
        // Follow redirect
        https.get(response.headers.location, { rejectUnauthorized: false }, (redirResp) => {
          redirResp.pipe(file);
          file.on('finish', () => { file.close(); resolve(); });
        }).on('error', reject);
      } else {
        response.pipe(file);
        file.on('finish', () => { file.close(); resolve(); });
      }
    }).on('error', reject);
  });

  console.log(`[Akool] Result downloaded: ${localPath}`);

  // 尝试上传到 OSS
  try {
    const { isOSSAvailable, uploadToOSS, getOSSBaseURL } = require('../utils/oss');
    if (isOSSAvailable()) {
      const ossKey = `uploads/results/${genId}${ext}`;
      await uploadToOSS(ossKey, fs.readFileSync(localPath));
      const ossUrl = getOSSBaseURL() + '/' + ossKey;
      console.log(`[Akool] Result uploaded to OSS: ${ossUrl}`);
      return { localPath, localUrl: ossUrl };
    }
  } catch (e) {
    console.warn('[Akool] OSS upload failed, using local path:', e.message);
  }

  return { localPath, localUrl };
}

/**
 * 查询是否需要轮询（Akool 全部是异步的）
 */
function isAsync() {
  return true;
}

/**
 * 查询账户余额
 */
async function getCreditInfo() {
  return akoolRequest('GET', ENDPOINTS.getCredit);
}

module.exports = { generate, isAsync, poll, downloadResult, getCreditInfo, detectFaces };
