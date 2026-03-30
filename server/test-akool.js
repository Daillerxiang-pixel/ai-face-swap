/**
 * AKOOL API 本地调试测试脚本
 * 测试 Face Swap Pro (V4) API
 */

const https = require('https');
const fs = require('fs');
const path = require('path');

// 从 .env 加载配置
require('dotenv').config({ path: path.join(__dirname, '.env') });

const AKOOL_API_KEY = process.env.AKOOL_API_KEY;
const AKOOL_BASE_URL = 'openapi.akool.com';

console.log('=== AKOOL API 本地调试测试 ===');
console.log('API Key:', AKOOL_API_KEY ? `${AKOOL_API_KEY.substring(0, 8)}...` : '未配置');

if (!AKOOL_API_KEY) {
  console.error('错误: AKOOL_API_KEY 未配置，请在 .env 中添加');
  process.exit(1);
}

/**
 * 发送 AKOOL API 请求
 */
function akoolRequest(method, endpointPath, body = null) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;

    const options = {
      hostname: AKOOL_BASE_URL,
      path: endpointPath,
      method,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': AKOOL_API_KEY,
      },
      timeout: 120000,
    };

    if (data) {
      options.headers['Content-Length'] = Buffer.byteLength(data);
    }

    console.log(`\n>>> 请求: ${method} ${endpointPath}`);
    if (body) {
      console.log('>>> Body:', JSON.stringify(body, null, 2));
    }

    const req = https.request(options, res => {
      let resp = '';
      res.on('data', c => resp += c);
      res.on('end', () => {
        console.log(`<<< HTTP ${res.statusCode}`);
        console.log('<<< Response:', resp.substring(0, 500));
        try {
          const parsed = JSON.parse(resp);
          resolve(parsed);
        } catch (e) {
          reject(new Error(`JSON parse error: ${resp.substring(0, 200)}`));
        }
      });
    });

    req.on('error', e => {
      console.error('<<< 请求错误:', e.message);
      reject(e);
    });
    req.on('timeout', () => {
      console.error('<<< 请求超时');
      req.destroy();
      reject(new Error('Timeout'));
    });

    if (data) req.write(data);
    req.end();
  });
}

/**
 * 测试 1: 查询账户余额
 */
async function testGetCredit() {
  console.log('\n\n=== 测试 1: 查询账户余额 ===');
  try {
    const result = await akoolRequest('GET', '/api/open/v3/faceswap/quota/info');
    console.log('余额信息:', JSON.stringify(result, null, 2));
    return result;
  } catch (e) {
    console.error('测试 1 失败:', e.message);
    return null;
  }
}

/**
 * 测试 2: Face Swap Pro (V4) - 单人脸换脸
 * 使用公开的测试图片
 */
async function testFaceSwapPro() {
  console.log('\n\n=== 测试 2: Face Swap Pro (V4) ===');
  
  // 使用公开可访问的测试图片 URL
  const testSourceUrl = 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop'; // 男人脸
  const testTargetUrl = 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&h=400&fit=crop'; // 女人脸
  
  console.log('Source URL:', testSourceUrl);
  console.log('Target URL:', testTargetUrl);

  try {
    const result = await akoolRequest('POST', '/api/open/v4/faceswap/faceswapByImage', {
      sourceImage: [{ path: testSourceUrl }],
      targetImage: [{ path: testTargetUrl }],
      model_name: 'akool_faceswap_image_hq',
      face_enhance: true,
      single_face_mode: true,
    });

    console.log('提交结果:', JSON.stringify(result, null, 2));

    if (result.code === 1000) {
      const jobId = result.data?.job_id || result.data?._id;
      console.log('✅ 任务提交成功! Job ID:', jobId);
      return jobId;
    } else {
      console.log('❌ 任务提交失败:', result.msg || result.error_msg);
      return null;
    }
  } catch (e) {
    console.error('测试 2 失败:', e.message);
    return null;
  }
}

/**
 * 测试 3: 查询任务结果
 */
async function testGetResult(jobId) {
  console.log('\n\n=== 测试 3: 查询任务结果 ===');
  if (!jobId) {
    console.log('跳过: 没有 Job ID');
    return null;
  }

  console.log('查询 Job ID:', jobId);

  try {
    const result = await akoolRequest('GET', `/api/open/v3/faceswap/result/listbyids?_ids=${jobId}`);
    console.log('查询结果:', JSON.stringify(result, null, 2));

    if (result.data?.result?.[0]) {
      const job = result.data.result[0];
      const status = job.faceswap_status;
      const statusMap = { 1: '队列中', 2: '处理中', 3: '成功', 4: '失败' };
      console.log('状态:', statusMap[status] || status);
      
      if (status === 3 && job.url) {
        console.log('✅ 换脸成功! 结果 URL:', job.url);
        return job.url;
      } else if (status === 4) {
        console.log('❌ 换脸失败');
        return null;
      } else {
        console.log('⏳ 任务仍在处理中，稍后请再次查询');
        return null;
      }
    }
    return null;
  } catch (e) {
    console.error('测试 3 失败:', e.message);
    return null;
  }
}

/**
 * 测试 4: Face Detection API
 */
async function testFaceDetection() {
  console.log('\n\n=== 测试 4: Face Detection API ===');
  
  const testImageUrl = 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop';
  console.log('检测图片 URL:', testImageUrl);

  try {
    const result = await akoolRequest('POST', '/interface/detect-api/detect_faces', {
      url: testImageUrl,
      single_face: true,
    });

    console.log('检测结果:', JSON.stringify(result, null, 2));
    
    if (result.faces_obj) {
      console.log('✅ 人脸检测成功!');
      return result.faces_obj;
    } else {
      console.log('❌ 未检测到人脸');
      return null;
    }
  } catch (e) {
    console.error('测试 4 失败:', e.message);
    return null;
  }
}

/**
 * 主测试流程
 */
async function main() {
  console.log('开始测试 AKOOL API...\n');
  
  // 测试 1: 查询余额
  const creditResult = await testGetCredit();
  
  // 测试 2: 提交换脸任务
  const jobId = await testFaceSwapPro();
  
  // 测试 3: 查询结果（等待 10 秒后查询）
  if (jobId) {
    console.log('\n等待 10 秒后查询结果...');
    await new Promise(r => setTimeout(r, 10000));
    const resultUrl = await testGetResult(jobId);
    
    // 如果还在处理，再等 20 秒查询
    if (!resultUrl) {
      console.log('\n再等待 20 秒...');
      await new Promise(r => setTimeout(r, 20000));
      await testGetResult(jobId);
    }
  }
  
  // 测试 4: 人脸检测
  await testFaceDetection();
  
  console.log('\n\n=== 测试完成 ===');
  console.log('如果测试 2 成功提交任务，请手动再次调用 testGetResult(jobId) 查询最终结果');
}

main().catch(e => console.error('主流程错误:', e));