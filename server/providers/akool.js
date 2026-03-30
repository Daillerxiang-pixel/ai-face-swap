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
    landmarks_str: faces.landmarks_str?.[0], // 旧格式 - 取第一个元素
    crop_landmarks: faces.crop_landmarks?.[0], // 新格式 - 取第一个元素（数组）
    face_url: faces.face_urls?.[0], // 人脸裁剪 URL
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
      await uploadToOSS(fs.readFileSync(filePath), key);
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
 * ⚠️ 重要：返回的 `_id` 用于查询结果，不是 `job_id`！
 * 
 * @param {Object} ctx
 * @param {string} ctx.sourceFilePath - 源图片（用户人脸）文件路径
 * @param {Object} ctx.template - 模板记录
 * @param {string} ctx.genId - 生成记录 ID
 * @returns {Promise<{predictionId: string, status: string}>}
 */
async function generateImagePro(ctx) {
  const { sourceFilePath, template, genId } = ctx;

  // 上传源图片到公网 URL
  const sourceUrl = await uploadToPublicUrl(sourceFilePath, ctx);
  console.log(`[Akool Pro] Source URL: ${sourceUrl}`);

  // 模板预览图作为目标图片（需要有公网 URL）
  let targetUrl = template.preview_url || template.video_url;
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

  // ⚠️ 重要：返回 _id 用于后续查询结果，不是 job_id
  const _id = result.data?._id;
  const jobId = result.data?.job_id;
  
  console.log(`[Akool Pro] Submit success: _id=${_id}, job_id=${jobId}`);

  // 返回 _id 作为 predictionId，这是查询结果时需要用的 ID
  return {
    predictionId: _id,  // ⚠️ 查询结果必须用 _id，不是 job_id
    jobId: jobId,
    status: 'processing',
  };
}

/**
 * 生成视频换脸 — 使用 Video Faceswap (V3)
 * 需要先做人脸检测获取 opts
 * 
 * ⚠️ 重要：返回的 `_id` 用于查询结果，不是 `job_id`！
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
  let videoUrl = template.video_url;
  if (!videoUrl) {
    throw new Error('模板缺少 video_url 字段');
  }
  // 处理相对路径，拼接 OSS URL
  if (!videoUrl.startsWith('http://') && !videoUrl.startsWith('https://')) {
    try {
      const { getOSSBaseURL } = require('../utils/oss');
      videoUrl = getOSSBaseURL() + (videoUrl.startsWith('/') ? '' : '/') + videoUrl;
    } catch (e) {
      throw new Error(`模板视频 URL 无效，OSS 未配置: ${videoUrl}`);
    }
  }
  console.log(`[Akool Video] Target Video URL: ${videoUrl}`);

  // 人脸检测 — 源图片
  console.log('[Akool Video] Detecting source face...');
  const sourceDetect = await detectFaces(sourceUrl);
  console.log(`[Akool Video] Source landmarks: ${sourceDetect.crop_landmarks || sourceDetect.landmarks_str}`);

  // 人脸检测 — 从视频第一帧检测目标人脸
  // 视频人脸检测需要用视频 URL，但 detect API 支持 URL
  // Akool 的 detect API 也支持视频，但这里我们直接用视频的预览图
  let targetDetect = null;
  if (template.preview_url) {
    let previewUrl = template.preview_url;
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
      path: targetDetect.face_url || template.preview_url,
      opts: targetDetect.crop_landmarks || targetDetect.landmarks_str,
    }];
  }

  const result = await akoolRequest('POST', ENDPOINTS.videoV3, requestBody);
  
  // ⚠️ 重要：返回 _id 用于后续查询结果，不是 job_id
  const _id = result.data?._id;
  const jobId = result.data?.job_id;
  
  console.log(`[Akool Video] Submit success: _id=${_id}, job_id=${jobId}`);

  return {
    predictionId: _id,  // ⚠️ 查询结果必须用 _id，不是 job_id
    jobId: jobId,
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
 * Akool 的所有换脸都是异步的（返回 _id 和 job_id）
 * 
 * ⚠️ 重要：查询结果必须使用 `_id`，而不是 `job_id`！
 * 
 * @param {string} predictionId - 任务 ID (_id，不是 job_id)
 * @returns {Promise<{status: string, progress: number, resultUrl?: string, error?: string}>}
 */
async function poll(predictionId) {
  // 确保 predictionId 是 _id 格式（24位十六进制字符串）
  // 如果传入的是 job_id，需要提示调用方使用 _id
  const result = await akoolRequest('GET', `${ENDPOINTS.getResult}?_ids=${predictionId}`);

  if (!result.data || !result.data.result || result.data.result.length === 0) {
    // 结果为空可能是：1. 任务仍在处理，2. 使用了错误的 ID（job_id 而非 _id）
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

  // 下载文件（带状态码检查）
  const downloadWithCheck = (url) => new Promise((resolve, reject) => {
    const file = fs.createWriteStream(localPath);
    const doPipe = (resp) => {
      if (resp.statusCode >= 400) {
        fs.unlinkSync(localPath);
        return reject(new Error('Download failed with HTTP ' + resp.statusCode + ' from ' + url));
      }
      resp.pipe(file);
      file.on('finish', () => { file.close(); resolve(); });
    };
    https.get(url, { rejectUnauthorized: false }, (response) => {
      if (response.statusCode >= 300 && response.statusCode < 400 && response.headers.location) {
        https.get(response.headers.location, { rejectUnauthorized: false }, (redirResp) => {
          doPipe(redirResp);
        }).on('error', reject);
      } else {
        doPipe(response);
      }
    }).on('error', reject);
  });
  await downloadWithCheck(resultUrl);

  // 验证下载的文件是有效图片/视频（不是 HTML 错误页）
  const fileBuffer = fs.readFileSync(localPath);
  if (fileBuffer.length < 1000 || fileBuffer[0] === 0x3C) {
    fs.unlinkSync(localPath);
    throw new Error('Downloaded file is not a valid image/video (size=' + fileBuffer.length + ')');
  }

  console.log(`[Akool] Result downloaded: ${localPath}`);

  // 尝试上传到 OSS
  try {
    const { isOSSAvailable, uploadToOSS, getOSSBaseURL } = require('../utils/oss');
    if (isOSSAvailable()) {
      const ossKey = `uploads/results/${genId}${ext}`;
      await uploadToOSS(fs.readFileSync(localPath), ossKey);
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
