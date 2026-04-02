/**
 * Subscription Route — Apple IAP 收据验证与订阅管理
 * 
 * API:
 *   POST /api/subscription/verify   — 验证 Apple 收据并更新订阅状态
 *   GET  /api/subscription/status   — 查询当前订阅状态
 *   POST /api/subscription/restore  — 恢复订阅
 */

const { Router } = require('express');
const { getDb } = require('../data/database');
const { authMiddleware } = require('../middleware/auth');

const router = Router();

// All routes require authentication
router.use(authMiddleware);

// Apple IAP 配置
const APPLE_SHARED_SECRET = process.env.APPLE_SHARED_SECRET || '';
const APPLE_VERIFY_URL = 'https://buy.itunes.apple.com/verifyReceipt';
const APPLE_SANDBOX_URL = 'https://sandbox.itunes.apple.com/verifyReceipt';

// 产品 ID 映射（订阅套餐）
// face_swap_weekly → 周卡 $19.99
// face_swap_monthly → 月卡 $69.99
// face_swap_yearly → 年卡 $399.99
const PRODUCT_MAP = {
  'face_swap_weekly': { tier: 'weekly', limit: 50, price: 19.99 },
  'face_swap_monthly': { tier: 'monthly', limit: 200, price: 69.99 },
  'face_swap_yearly': { tier: 'yearly', limit: 999, price: 399.99 },
};

/**
 * 调用 Apple 收据验证 API
 * @param {string} receiptData - Base64 编码的收据数据
 * @param {boolean} useSandbox - 是否使用沙盒环境
 * @returns {Promise<Object>} Apple 响应
 */
async function verifyReceiptWithApple(receiptData, useSandbox = false) {
  const url = useSandbox ? APPLE_SANDBOX_URL : APPLE_VERIFY_URL;
  
  const requestBody = {
    'receipt-data': receiptData,
    'password': APPLE_SHARED_SECRET,
    'exclude-old-transactions': true,
  };

  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(requestBody),
  });

  return response.json();
}

/**
 * 解析订阅收据信息
 * @param {Object} appleResponse - Apple verifyReceipt 响应
 * @returns {Object|null} 解析后的订阅信息
 */
function parseSubscriptionInfo(appleResponse) {
  // status: 0 = 有效, 21007 = 沙盒收据发送到生产环境
  if (appleResponse.status !== 0) {
    return { valid: false, status: appleResponse.status, error: getAppleError(appleResponse.status) };
  }

  const receipt = appleResponse.receipt;
  const latestReceiptInfo = appleResponse.latest_receipt_info;

  if (!latestReceiptInfo || latestReceiptInfo.length === 0) {
    return { valid: false, error: 'No subscription found in receipt' };
  }

  // 取最新的订阅交易
  const latest = latestReceiptInfo[latestReceiptInfo.length - 1];
  
  // 解析过期时间（Apple 用毫秒时间戳）
  const expiresAt = latest.expires_date_ms 
    ? new Date(parseInt(latest.expires_date_ms)).toISOString()
    : latest.expires_date 
    ? new Date(latest.expires_date).toISOString()
    : null;

  return {
    valid: true,
    productId: latest.product_id,
    transactionId: latest.transaction_id,
    originalTransactionId: latest.original_transaction_id,
    expiresAt,
    purchaseDate: latest.purchase_date 
      ? new Date(latest.purchase_date).toISOString() 
      : null,
    isTrial: latest.is_trial_period === 'true',
    renewalDate: latest.renewal_date,
    // 订阅状态：active, expired, cancelled, billing_retry
    subscriptionStatus: getSubscriptionStatus(latest, appleResponse.pending_renewal_info),
  };
}

/**
 * 获取订阅状态
 */
function getSubscriptionStatus(latest, pendingRenewalInfo) {
  const now = Date.now();
  const expiresMs = parseInt(latest.expires_date_ms) || 0;
  
  if (expiresMs < now) {
    return 'expired';
  }

  if (pendingRenewalInfo && pendingRenewalInfo.length > 0) {
    const renewal = pendingRenewalInfo[0];
    if (renewal.auto_renew_status === '0') {
      return 'cancelled';
    }
    if (renewal.is_in_billing_retry_period === '1') {
      return 'billing_retry';
    }
  }

  return 'active';
}

/**
 * Apple 错误码映射
 */
function getAppleError(status) {
  const errors = {
    21000: 'App Store could not read the JSON object',
    21002: 'Receipt data was malformed',
    21003: 'Receipt could not be authenticated',
    21004: 'Shared secret does not match',
    21005: 'Receipt server is not currently available',
    21006: 'Receipt is valid but subscription has expired',
    21007: 'Receipt is from sandbox but sent to production',
    21008: 'Receipt is from production but sent to sandbox',
    21009: 'Receipt server had an internal error',
    21010: 'Receipt could not be authorized',
  };
  return errors[status] || `Unknown error (status: ${status})`;
}

/**
 * POST /api/subscription/verify — 验证 Apple 收据
 * Body: { receiptData: string (base64) }
 */
router.post('/verify', async (req, res) => {
  const { receiptData } = req.body;

  if (!receiptData) {
    return res.status(400).json({ success: false, error: 'receiptData is required' });
  }

  const db = getDb();
  const userId = req.userId;

  try {
    console.log(`[IAP] Verifying receipt for user: ${userId}`);

    // 1. 先用生产环境验证
    let appleResponse = await verifyReceiptWithApple(receiptData, false);

    // 2. 如果是沙盒收据（status 21007），切换到沙盒环境
    if (appleResponse.status === 21007) {
      console.log('[IAP] Sandbox receipt detected, retrying with sandbox URL');
      appleResponse = await verifyReceiptWithApple(receiptData, true);
    }

    // 3. 解析订阅信息
    const subInfo = parseSubscriptionInfo(appleResponse);

    if (!subInfo.valid) {
      console.log(`[IAP] Receipt invalid: ${subInfo.error}`);
      return res.status(400).json({
        success: false,
        error: subInfo.error || 'Receipt verification failed',
        appleStatus: subInfo.status,
      });
    }

    // 4. 获取套餐配置
    const productConfig = PRODUCT_MAP[subInfo.productId];
    if (!productConfig) {
      console.log(`[IAP] Unknown product ID: ${subInfo.productId}`);
      return res.status(400).json({
        success: false,
        error: `Unknown product: ${subInfo.productId}`,
      });
    }

    // 5. 更新用户订阅状态
    db.prepare(`
      UPDATE users SET 
        subscription_tier = ?,
        subscription_expires_at = ?,
        monthly_limit = ?,
        receipt_data = ?
      WHERE id = ?
    `).run(
      productConfig.tier,
      subInfo.expiresAt,
      productConfig.limit,
      receiptData,
      userId
    );

    console.log(`[IAP] Subscription updated: tier=${productConfig.tier}, expires=${subInfo.expiresAt}`);

    // 6. 返回订阅状态给客户端
    const user = db.prepare('SELECT id, subscription_tier, subscription_expires_at, monthly_limit FROM users WHERE id = ?').get(userId);

    res.json({
      success: true,
      data: {
        tier: user.subscription_tier,
        expiresAt: user.subscription_expires_at,
        monthlyLimit: user.monthly_limit,
        productId: subInfo.productId,
        transactionId: subInfo.transactionId,
        subscriptionStatus: subInfo.subscriptionStatus,
        isTrial: subInfo.isTrial,
        price: productConfig.price,
      },
    });

  } catch (error) {
    console.error('[IAP] Verification error:', error.message);
    res.status(500).json({
      success: false,
      error: 'Receipt verification failed: ' + error.message,
    });
  }
});

/**
 * GET /api/subscription/status — 查询订阅状态
 */
router.get('/status', (req, res) => {
  const db = getDb();
  const userId = req.userId;

  const user = db.prepare(`
    SELECT id, subscription_tier, subscription_expires_at, monthly_limit, monthly_usage, receipt_data
    FROM users WHERE id = ?
  `).get(userId);

  if (!user) {
    return res.status(404).json({ success: false, error: 'User not found' });
  }

  // 计算订阅状态
  const expiresAt = user.subscription_expires_at;
  const now = new Date();
  const isExpired = expiresAt && new Date(expiresAt) < now;

  // 如果已过期且不是 free，自动降级
  if (isExpired && user.subscription_tier !== 'free') {
    console.log(`[IAP] Subscription expired for user ${userId}, downgrading to free`);
    db.prepare(`
      UPDATE users SET subscription_tier = 'free', monthly_limit = 10
      WHERE id = ?
    `).run(userId);
    
    user.subscription_tier = 'free';
    user.monthly_limit = 10;
  }

  res.json({
    success: true,
    data: {
      tier: user.subscription_tier,
      expiresAt: user.subscription_expires_at,
      monthlyLimit: user.monthly_limit,
      monthlyUsage: user.monthly_usage,
      remaining: Math.max(0, user.monthly_limit - user.monthly_usage),
      isActive: !isExpired && user.subscription_tier !== 'free',
    },
  });
});

/**
 * POST /api/subscription/restore — 恢复订阅（从收据重新验证）
 */
router.post('/restore', async (req, res) => {
  const db = getDb();
  const userId = req.userId;

  // 从数据库读取已保存的 receipt_data
  const user = db.prepare('SELECT receipt_data FROM users WHERE id = ?').get(userId);

  if (!user || !user.receipt_data) {
    return res.status(400).json({
      success: false,
      error: 'No receipt data found. Please make a new purchase.',
    });
  }

  const receiptData = user.receipt_data;
  
  try {
    let appleResponse = await verifyReceiptWithApple(receiptData, false);
    if (appleResponse.status === 21007) {
      appleResponse = await verifyReceiptWithApple(receiptData, true);
    }

    const subInfo = parseSubscriptionInfo(appleResponse);

    if (!subInfo.valid) {
      return res.status(400).json({
        success: false,
        error: 'Subscription no longer valid',
        appleStatus: subInfo.status,
      });
    }

    const productConfig = PRODUCT_MAP[subInfo.productId];
    if (!productConfig) {
      return res.status(400).json({
        success: false,
        error: `Unknown product: ${subInfo.productId}`,
      });
    }

    // 更新状态
    db.prepare(`
      UPDATE users SET 
        subscription_tier = ?,
        subscription_expires_at = ?,
        monthly_limit = ?
      WHERE id = ?
    `).run(
      productConfig.tier,
      subInfo.expiresAt,
      productConfig.limit,
      userId
    );

    res.json({
      success: true,
      data: {
        tier: productConfig.tier,
        expiresAt: subInfo.expiresAt,
        productId: subInfo.productId,
        subscriptionStatus: subInfo.subscriptionStatus,
        price: productConfig.price,
      },
    });

  } catch (error) {
    console.error('[IAP] Restore error:', error.message);
    res.status(500).json({
      success: false,
      error: 'Restore failed: ' + error.message,
    });
  }
});

module.exports = router;