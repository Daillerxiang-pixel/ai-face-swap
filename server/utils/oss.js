/**
 * 阿里云 OSS 工具模块
 * 懒加载：首次调用时才初始化客户端，确保环境变量已加载
 *
 * OSS_BUCKET 须为「Bucket 名称」本身（如 aihuantu），不要填完整域名或 URL，
 * 否则 ali-oss 会报：The bucket must be conform to the specifications
 */

let _client = null;
let _normalizedBucket = null;

/**
 * 从误填的完整域名中提取 bucket 名
 * 例：https://aihuantu.oss-cn-beijing.aliyuncs.com → aihuantu
 */
function normalizeBucketName(raw) {
  if (!raw || typeof raw !== 'string') return '';
  let s = raw
    .replace(/^\uFEFF/, '')
    .replace(/\r|\n/g, '')
    .trim();
  if ((s.startsWith('"') && s.endsWith('"')) || (s.startsWith("'") && s.endsWith("'"))) {
    s = s.slice(1, -1).trim();
  }
  if (s.startsWith('http://') || s.startsWith('https://')) {
    try {
      const host = new URL(s).hostname;
      const m = host.match(/^([a-z0-9][a-z0-9-]*)\.oss-[a-z0-9-]+\.aliyuncs\.com$/i);
      if (m) return m[1].toLowerCase();
    } catch (_) {
      /* ignore */
    }
  }
  const m2 = s.match(/^([a-z0-9][a-z0-9-]*)\.oss-[a-z0-9-]+\.aliyuncs\.com$/i);
  if (m2) return m2[1].toLowerCase();
  return s.toLowerCase();
}

/**
 * 控制台有时只写 cn-beijing；公网 Host 须为 bucket.oss-cn-beijing.aliyuncs.com
 */
function normalizeOSSRegion(raw) {
  if (!raw || typeof raw !== 'string') return '';
  let s = raw.replace(/\r|\n/g, '').trim();
  if ((s.startsWith('"') && s.endsWith('"')) || (s.startsWith("'") && s.endsWith("'"))) {
    s = s.slice(1, -1).trim();
  }
  if (/^cn-[a-z0-9-]+$/i.test(s)) {
    return `oss-${s.toLowerCase()}`;
  }
  return s.toLowerCase();
}

/** 阿里云 Bucket 命名：3–63 位，小写字母、数字、连字符，不能以连字符开头/结尾 */
function isValidBucketName(name) {
  if (!name || typeof name !== 'string') return false;
  if (name.length < 3 || name.length > 63) return false;
  return /^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$/.test(name);
}

/**
 * 结构化报告：供启动日志、npm run verify:oss、CI 使用（不发起网络请求）
 */
function getOSSConfigReport() {
  const hasKeys = !!(process.env.OSS_ACCESS_KEY_ID && process.env.OSS_ACCESS_KEY_SECRET);
  const bucketRaw = process.env.OSS_BUCKET || '';
  const bucket = normalizeBucketName(bucketRaw);
  const region = normalizeOSSRegion(process.env.OSS_REGION && String(process.env.OSS_REGION).trim());

  if (!hasKeys) {
    return {
      ok: false,
      code: 'NO_KEYS',
      message: '未配置 OSS_ACCESS_KEY_ID 或 OSS_ACCESS_KEY_SECRET',
      bucket: null,
      region: region || null,
      baseUrl: '',
    };
  }
  if (!isValidBucketName(bucket)) {
    return {
      ok: false,
      code: 'BAD_BUCKET',
      message: `OSS_BUCKET 无效（当前: ${JSON.stringify(bucketRaw) || '空'}），应只填名称如 aihuantu，勿填完整域名`,
      bucket,
      region: region || null,
      baseUrl: '',
    };
  }
  if (!region) {
    return {
      ok: false,
      code: 'NO_REGION',
      message: '未配置 OSS_REGION（示例: oss-cn-beijing）',
      bucket,
      region: null,
      baseUrl: '',
    };
  }
  const baseUrl = `https://${bucket}.${region}.aliyuncs.com`;
  return {
    ok: true,
    code: 'OK',
    message: 'OSS 配置完整',
    bucket,
    region,
    baseUrl,
  };
}

function ossIsFullyConfigured() {
  return getOSSConfigReport().ok;
}

function logOSSStartupStatus() {
  const r = getOSSConfigReport();
  if (r.ok) {
    console.log(`[OSS] 已启用 公网基址: ${r.baseUrl} (bucket=${r.bucket})`);
  } else {
    console.warn(`[OSS] 未启用 — ${r.message}`);
    console.warn('[OSS] 上传将使用本地 uploads/；若 REQUIRE_OSS=1 则进程会拒绝启动');
  }
}

function getClient() {
  if (_client) return _client;

  if (!ossIsFullyConfigured()) {
    if (process.env.OSS_ACCESS_KEY_ID) {
      const raw = process.env.OSS_BUCKET;
      const nb = normalizeBucketName(raw || '');
      if (raw && !isValidBucketName(nb)) {
        console.warn(
          `[OSS] OSS_BUCKET 无效或不符合规范（当前: ${JSON.stringify(raw)}）。请只填写 Bucket 名称，勿填完整 URL。已禁用 OSS。`
        );
      } else if (!process.env.OSS_REGION || !String(process.env.OSS_REGION).trim()) {
        console.warn('[OSS] 未配置 OSS_REGION，已禁用 OSS');
      }
    }
    return null;
  }

  const OSS = require('ali-oss');
  const bucket = normalizeBucketName(process.env.OSS_BUCKET || '');
  _normalizedBucket = bucket;

  const region = normalizeOSSRegion(String(process.env.OSS_REGION || '').trim());
  /** 区域级 endpoint，如 oss-cn-beijing.aliyuncs.com（不要填带 bucket 子域名的访问域名） */
  const rawEp = process.env.OSS_ENDPOINT && String(process.env.OSS_ENDPOINT).trim();
  let endpointHost = null;
  if (rawEp) {
    try {
      const h = rawEp.replace(/^https?:\/\//i, '').split('/')[0];
      // 若误填成 aihuantu.oss-xxx.aliyuncs.com，忽略，避免 SDK 把整段当 bucket
      if (h && !h.toLowerCase().startsWith(`${bucket.toLowerCase()}.`)) {
        endpointHost = h;
      }
    } catch (_) {
      /* ignore */
    }
  }

  const opts = {
    region,
    accessKeyId: process.env.OSS_ACCESS_KEY_ID,
    accessKeySecret: process.env.OSS_ACCESS_KEY_SECRET,
    bucket,
  };
  if (endpointHost) {
    opts.endpoint = endpointHost;
  }

  _client = new OSS(opts);

  console.log(`[OSS] 客户端初始化成功: ${bucket}@${region}${endpointHost ? ` endpoint=${endpointHost}` : ''}`);
  return _client;
}

// 公网访问 URL（用于生成前端图片链接）
function getOSSBaseURL() {
  const bucket = _normalizedBucket || normalizeBucketName(process.env.OSS_BUCKET || '');
  const region = normalizeOSSRegion(process.env.OSS_REGION && String(process.env.OSS_REGION).trim());
  if (!bucket || !region || !isValidBucketName(bucket)) return '';
  return `https://${bucket}.${region}.aliyuncs.com`;
}

/**
 * DB 中的路径或 URL → 前端可直接加载的地址（OSS 开启时拼公网域名；否则保持 /uploads 相对路径供 APP 走 API 域）
 */
function toPublicMediaUrl(dbPath) {
  if (dbPath == null || dbPath === '') return null;
  const s = String(dbPath).trim();
  if (s.startsWith('http://') || s.startsWith('https://')) return s;
  if (ossIsFullyConfigured()) {
    const base = getOSSBaseURL();
    if (base) {
      const p = s.startsWith('/') ? s : `/${s}`;
      return base + p;
    }
  }
  return s.startsWith('/') ? s : `/${s}`;
}

/**
 * 上传 Buffer 到 OSS
 * @param {Buffer} buffer
 * @param {string} objectKey  如 uploads/xxx.png
 * @param {string} mimeType
 * @returns {Promise<string>} 完整公网 URL
 */
async function uploadToOSS(buffer, objectKey, mimeType) {
  const client = getClient();
  if (!client) throw new Error('OSS 未配置');

  await client.put(objectKey, buffer, {
    mime: mimeType,
    headers: { 'Cache-Control': 'public, max-age=86400' },
  });

  const url = getOSSBaseURL() + '/' + objectKey;
  console.log(`[OSS] 上传成功: ${url}`);
  return url;
}

/**
 * 删除 OSS 文件
 */
async function deleteFromOSS(objectKey) {
  const client = getClient();
  if (!client) return;

  try {
    await client.delete(objectKey);
    console.log(`[OSS] 删除成功: ${objectKey}`);
  } catch (err) {
    console.error(`[OSS] 删除失败: ${objectKey}`, err.message);
  }
}

/**
 * 获取 OSS 公网 URL
 */
function getOSSUrl(objectKey) {
  return getOSSBaseURL() + '/' + objectKey;
}

/**
 * 上传 Buffer 到指定目录
 */
async function uploadBuffer(buffer, dir, filename, mimeType) {
  const objectKey = `${dir}/${filename}`;
  const url = await uploadToOSS(buffer, objectKey, mimeType);
  return { url, key: objectKey };
}

/**
 * 是否启用 OSS（密钥、Bucket 名、Region 均有效时才为 true）
 */
function isOSSAvailable() {
  return ossIsFullyConfigured();
}

module.exports = {
  uploadToOSS,
  deleteFromOSS,
  getOSSUrl,
  uploadBuffer,
  isOSSAvailable,
  getOSSBaseURL,
  toPublicMediaUrl,
  normalizeBucketName,
  normalizeOSSRegion,
  isValidBucketName,
  getOSSConfigReport,
  logOSSStartupStatus,
};
