/**
 * 阿里云 OSS 工具模块
 * 懒加载：首次调用时才初始化客户端，确保环境变量已加载
 */

let _client = null;

function getClient() {
  if (_client) return _client;

  if (!process.env.OSS_ACCESS_KEY_ID || !process.env.OSS_ACCESS_KEY_SECRET) {
    console.warn('[OSS] 未配置 OSS_ACCESS_KEY_ID/OSS_ACCESS_KEY_SECRET，OSS 功能不可用');
    return null;
  }

  const OSS = require('ali-oss');
  _client = new OSS({
    region: process.env.OSS_REGION,           // oss-cn-beijing
    accessKeyId: process.env.OSS_ACCESS_KEY_ID,
    accessKeySecret: process.env.OSS_ACCESS_KEY_SECRET,
    bucket: process.env.OSS_BUCKET,           // aihuantu
    // 不传 endpoint，ali-oss 会自动拼接 https://aihuantu.oss-cn-beijing.aliyuncs.com
  });

  console.log(`[OSS] 客户端初始化成功: ${process.env.OSS_BUCKET}@${process.env.OSS_REGION}`);
  return _client;
}

// 公网访问 URL（用于生成前端图片链接）
function getOSSBaseURL() {
  const bucket = process.env.OSS_BUCKET;
  const region = process.env.OSS_REGION; // oss-cn-beijing
  return bucket && region ? `https://${bucket}.${region}.aliyuncs.com` : '';
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

  const result = await client.put(objectKey, buffer, {
    mime: mimeType,
    headers: { 'Cache-Control': 'public, max-age=86400' },
  });

  // result.url 可能是内网域名，用公网 URL 替换
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
 * 检查 OSS 是否可用
 */
function isOSSAvailable() {
  return !!(process.env.OSS_ACCESS_KEY_ID && process.env.OSS_ACCESS_KEY_SECRET);
}

module.exports = {
  uploadToOSS,
  deleteFromOSS,
  getOSSUrl,
  uploadBuffer,
  isOSSAvailable,
  getOSSBaseURL,
};
