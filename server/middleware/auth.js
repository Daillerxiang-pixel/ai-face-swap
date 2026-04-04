const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'aihuantu-jwt-secret-2026';

function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ success: false, error: 'Not authenticated' });
  }
  try {
    const decoded = jwt.verify(authHeader.replace('Bearer ', ''), JWT_SECRET);
    req.userId = decoded.userId;
    next();
  } catch (err) {
    return res.status(401).json({ success: false, error: 'Invalid or expired token' });
  }
}

/** 若带合法 Bearer 则设置 req.userId，否则继续（不 401）— 用于 multipart 等需兼容匿名场景 */
function optionalAuthMiddleware(req, res, next) {
  req.userId = undefined;
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    try {
      const decoded = jwt.verify(authHeader.replace('Bearer ', ''), JWT_SECRET);
      req.userId = decoded.userId;
    } catch (_) {
      /* 忽略无效 token，按匿名处理 */
    }
  }
  next();
}

module.exports = { authMiddleware, optionalAuthMiddleware };
