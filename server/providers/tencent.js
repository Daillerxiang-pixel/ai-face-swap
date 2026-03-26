/**
 * Tencent Cloud Face Fusion Provider
 * 用于图片换脸 — 腾讯云人脸融合 API
 */

const tencentcloud = require('tencentcloud-sdk-nodejs');
const fs = require('fs');
const path = require('path');

const ACTIVITY_ID = process.env.TENCENT_ACTIVITY_ID || 'at_2035634829506617344';
const DEFAULT_MODEL_ID = process.env.TENCENT_MODEL_ID || 'mt_2035635381514772480';

let faceClient = null;
function getClient() {
  if (faceClient) return faceClient;
  faceClient = new tencentcloud.facefusion.v20181201.Client({
    credential: {
      secretId: process.env.TENCENT_SECRET_ID,
      secretKey: process.env.TENCENT_SECRET_KEY,
    },
    region: 'ap-guangzhou',
  });
  return faceClient;
}

/**
 * 生成图片换脸
 * @param {Object} ctx
 * @param {string} ctx.sourceFilePath - 源图片文件路径
 * @param {Object} ctx.template - 模板记录
 * @param {string} ctx.genId - 生成记录 ID
 * @returns {Promise<{resultPath: string, resultUrl: string}>}
 */
async function generate(ctx) {
  const { sourceFilePath, template, genId } = ctx;

  const sourceBase64 = fs.readFileSync(sourceFilePath).toString('base64');
  const client = getClient();

  console.log(`[Tencent] Face fusion: gen=${genId}, template=${template.name}, model=${template.provider_model_id || DEFAULT_MODEL_ID}`);

  const resp = await client.FaceFusion({
    ProjectId: ACTIVITY_ID,
    ModelId: template.provider_model_id || DEFAULT_MODEL_ID,
    Image: sourceBase64,
    RspImgType: 'base64',
  });

  const resultBase64 = resp.Image;
  if (!resultBase64) {
    throw new Error('腾讯云融合结果为空');
  }

  // 保存结果
  const resultDir = path.join(__dirname, '..', '..', 'uploads', 'results');
  if (!fs.existsSync(resultDir)) fs.mkdirSync(resultDir, { recursive: true });
  const resultPath = path.join(resultDir, `${genId}.png`);
  fs.writeFileSync(resultPath, Buffer.from(resultBase64, 'base64'));

  return {
    resultPath,
    resultUrl: `/uploads/results/${genId}.png`,
  };
}

/**
 * 查询是否需要轮询（腾讯云是同步的，不需要）
 */
function isAsync() {
  return false;
}

/**
 * 轮询异步任务状态（腾讯云不需要）
 */
async function poll(/* predictionId */) {
  throw new Error('Tencent provider is synchronous, poll() should not be called');
}

module.exports = { generate, isAsync, poll };
