/**
 * Provider Registry — 多 Provider 统一管理
 * 
 * 架构设计：
 *   每个 Provider 实现 { generate(ctx), isAsync(), poll(predictionId) }
 *   generate() → 同步返回结果 或 异步返回 { predictionId }
 *   isAsync() → true 时使用 poll() 轮询状态
 *   poll() → 返回 { status, progress, resultUrl?, error? }
 * 
 * 扩展新 Provider 只需：
 *   1. 在 providers/ 下创建新文件
 *   2. 在此注册
 *   3. 模板中设置 provider 字段
 */

const tencent = require('./tencent');
const replicate = require('./replicate');
const akool = require('./akool');

const providers = {
  tencent: {
    name: '腾讯云人脸融合',
    type: 'image',       // 支持: image, video, both
    async: false,
    module: tencent,
  },
  replicate: {
    name: 'Replicate AI',
    type: 'video',       // 支持: image, video, both
    async: true,
    module: replicate,
  },
  akool: {
    name: 'Akool Face Swap',
    type: 'both',        // 支持: image + video
    async: true,         // Akool 全部是异步的
    module: akool,
  },
};

/**
 * 根据 provider 名称获取 provider 实例
 */
function getProvider(name) {
  const p = providers[name];
  if (!p) {
    throw new Error(`未知的 Provider: ${name}，可用: ${Object.keys(providers).join(', ')}`);
  }
  return p;
}

/**
 * 列出所有 provider（用于 API 返回）
 */
function listProviders() {
  return Object.entries(providers).map(([key, val]) => ({
    id: key,
    name: val.name,
    type: val.type,
    async: val.async,
  }));
}

/**
 * 调用 provider 的 generate 方法
 */
async function callGenerate(providerName, ctx) {
  const provider = getProvider(providerName);
  return provider.module.generate(ctx);
}

/**
 * 调用 provider 的 poll 方法
 */
async function callPoll(providerName, predictionId) {
  const provider = getProvider(providerName);
  if (!provider.async) {
    throw new Error(`Provider "${providerName}" 是同步模式，不支持 poll()`);
  }
  return provider.module.poll(predictionId);
}

/**
 * 下载异步结果到本地（仅异步 provider）
 */
async function downloadAsyncResult(providerName, url, genId) {
  const provider = getProvider(providerName);
  if (provider.module.downloadResult) {
    return provider.module.downloadResult(url, genId);
  }
  return null;
}

module.exports = { getProvider, listProviders, callGenerate, callPoll, downloadAsyncResult, providers };
