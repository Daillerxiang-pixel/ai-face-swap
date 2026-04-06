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

function assertAkoolConfigured() {
  const k = AKOOL_API_KEY.trim();
  if (!k) {
    throw new Error('Akool 未配置：请在 .env 中设置 AKOOL_API_KEY（Akool 控制台 API Key）');
  }
  if (k.includes('你的') || k.toLowerCase().includes('placeholder')) {
    throw new Error('Akool API Key 仍为占位符：请替换为 Akool 开放平台真实 x-api-key');
  }
}

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

/** 判断 URL 是否像视频（预览误填成 mp4 时不能当图片做人脸检测） */
function isProbablyVideoUrl(url) {
  if (!url || typeof url !== 'string') return false;
  const u = url.split('?')[0].toLowerCase();
  return u.endsWith('.mp4') || u.endsWith('.webm') || u.endsWith('.mov') || u.endsWith('.m3u8');
}

/**
 * 人脸检测（用于 V3 API 获取 opts 参数）
 * @param {string} imageUrl - 图片或视频 URL（视频见 https://docs.akool.com/ai-tools-suite/face-detection/detect-faces）
 * @param {{ isVideo?: boolean, numFrames?: number }} [options]
 * @returns {Promise<{landmarks_str: string, crop_landmarks: string, face_url?: string}>}
 */
async function detectFaces(imageUrl, options = {}) {
  const body = {
    url: imageUrl,
    single_face: true,
    return_face_url: true,
  };
  if (options.isVideo) {
    body.num_frames = options.numFrames != null ? options.numFrames : 10;
  }

  const result = await akoolRequest('POST', ENDPOINTS.faceDetect, body);

  const faces = result.faces_obj?.['0'];
  if (!faces || !faces.landmarks_str || faces.landmarks_str.length === 0) {
    throw new Error('未检测到人脸');
  }

  return {
    landmarks_str: faces.landmarks_str?.[0],
    crop_landmarks: faces.crop_landmarks?.[0],
    face_url: faces.face_urls?.[0] ?? faces.face_url,
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

  if (!_id) {
    throw new Error('Akool 未返回任务 _id，无法轮询结果（请检查接口返回）');
  }

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

  // 目标人脸：specifyvideo **必须**同时带 sourceImage + targetImage + modifyVideo（见官方 OpenAPI required）
  // 若 preview_url 与 video 同为 .mp4，不能对 mp4 当「图片」去 detect，应对 **视频 URL** 调 detect（支持 num_frames）
  let targetPreviewUrl = template.preview_url ? String(template.preview_url).trim() : '';
  if (targetPreviewUrl && !targetPreviewUrl.startsWith('http')) {
    try {
      const { getOSSBaseURL } = require('../utils/oss');
      const base = getOSSBaseURL();
      if (base) {
        targetPreviewUrl = base + (targetPreviewUrl.startsWith('/') ? '' : '/') + targetPreviewUrl;
      }
    } catch (e) { /* ignore */ }
  }

  let targetDetect = null;
  if (targetPreviewUrl && !isProbablyVideoUrl(targetPreviewUrl)) {
    console.log(`[Akool Video] Detecting target face from preview image: ${targetPreviewUrl}`);
    try {
      targetDetect = await detectFaces(targetPreviewUrl);
      console.log(`[Akool Video] Target landmarks (preview): ${targetDetect.crop_landmarks || targetDetect.landmarks_str}`);
    } catch (e) {
      console.warn(`[Akool Video] Target detect from preview image failed: ${e.message}, will use video URL`);
    }
  } else if (targetPreviewUrl && isProbablyVideoUrl(targetPreviewUrl)) {
    console.log('[Akool Video] preview_url is video, skipping as still image for detection');
  }

  if (!targetDetect) {
    console.log(`[Akool Video] Detecting target face from modifyVideo (video): ${videoUrl}`);
    targetDetect = await detectFaces(videoUrl, { isVideo: true, numFrames: 10 });
    console.log(`[Akool Video] Target landmarks (video): ${targetDetect.crop_landmarks || targetDetect.landmarks_str}`);
  }

  const sourceEntry = {
    path: sourceDetect.face_url || sourceUrl,
  };
  const srcOpts = sourceDetect.crop_landmarks || sourceDetect.landmarks_str;
  if (srcOpts) sourceEntry.opts = srcOpts;

  if (!targetDetect.face_url) {
    throw new Error(
      '视频目标人脸检测未返回裁剪脸图 URL（face_urls）。请确认视频中人脸清晰、Detect 已开启 return_face_url，或稍后重试'
    );
  }
  const targetEntry = { path: targetDetect.face_url };
  const tgtOpts = targetDetect.crop_landmarks || targetDetect.landmarks_str;
  if (tgtOpts) targetEntry.opts = tgtOpts;

  const requestBody = {
    sourceImage: [sourceEntry],
    targetImage: [targetEntry],
    face_enhance: 1,
    modifyVideo: videoUrl,
    webhookUrl: '',
  };

  const result = await akoolRequest('POST', ENDPOINTS.videoV3, requestBody);
  
  // ⚠️ 重要：返回 _id 用于后续查询结果，不是 job_id
  const _id = result.data?._id;
  const jobId = result.data?.job_id;

  if (!_id) {
    throw new Error('Akool 未返回任务 _id，无法轮询结果（请检查接口返回）');
  }

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
  assertAkoolConfigured();
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
function normalizeAkoolStatus(raw) {
  const n = Number(raw);
  return Number.isFinite(n) ? n : NaN;
}

/** 从 Akool result 条目中取可展示的错误文案（失败时接口可能带 error_msg / msg 等） */
function akoolJobErrorMessage(job) {
  const parts = [
    job.error_msg,
    job.errorMsg,
    job.msg,
    job.message,
    job.fail_reason,
    job.failReason,
  ].filter(Boolean);
  const s = parts.map(x => String(x).trim()).find(Boolean);
  if (s && !/^success$/i.test(s)) return s;
  return '';
}

/** 成功时结果可能在 url，部分视频场景字段名不同 */
function akoolResultUrl(job) {
  const u = job.url || job.video_url || job.result_url || job.output_url;
  return typeof u === 'string' && u.startsWith('http') ? u : '';
}

async function poll(predictionId) {
  if (predictionId == null || String(predictionId).trim() === '') {
    return { status: 'failed', error: '任务 ID 无效（prediction_id 为空），无法查询 Akool 结果' };
  }

  const result = await akoolRequest('GET', `${ENDPOINTS.getResult}?_ids=${encodeURIComponent(predictionId)}`);

  if (!result.data || !result.data.result || result.data.result.length === 0) {
    // 结果为空可能是：1. 任务仍在处理，2. 使用了错误的 ID（job_id 而非 _id）
    return { status: 'processing', progress: 30 };
  }

  const job = result.data.result[0];
  const faceswapStatus = normalizeAkoolStatus(job.faceswap_status);

  // 1=队列中, 2=处理中, 3=成功, 4=失败（接口偶发字符串，必须用 Number）
  switch (faceswapStatus) {
    case 1:
      return { status: 'processing', progress: 20 };
    case 2:
      return { status: 'processing', progress: 60 };
    case 3: {
      const outUrl = akoolResultUrl(job);
      if (!outUrl) {
        console.warn('[Akool] success but no URL in job:', JSON.stringify(job).slice(0, 800));
        return { status: 'failed', error: 'Akool 返回成功但缺少结果 URL，请稍后重试或联系支持' };
      }
      return {
        status: 'completed',
        progress: 100,
        resultUrl: outUrl,
      };
    }
    case 4: {
      const detail = akoolJobErrorMessage(job);
      const msg = detail
        ? `Akool 处理失败：${detail}`
        : 'Akool 换脸处理失败（任务已结束）。若控制台已扣费，多为任务受理后处理失败，请以 Akool 后台说明为准或联系其客服。';
      console.warn('[Akool] faceswap_status=4', JSON.stringify(job).slice(0, 800));
      return { status: 'failed', error: msg };
    }
    default:
      console.warn('[Akool] unknown faceswap_status', job.faceswap_status, 'job=', JSON.stringify(job).slice(0, 400));
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
