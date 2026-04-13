/**
 * 管理后台 API 根路径 — 按当前域名自动选择：
 *
 *   正式服  www.deepfaceswap.tech/admin  →  API 在 api.deepfaceswap.tech
 *   测试服  test1.kanashortplay.com/admin →  API 同域 test1.kanashortplay.com
 *   本地    localhost / 127.0.0.1         →  相对路径 /api/admin
 *
 * 若需强制指定，在本文件加载前设 window.ADMIN_API_BASE = '...'
 */
(function () {
  if (typeof window.ADMIN_API_BASE !== 'undefined') return;

  var host = location.hostname;
  if (host === 'www.deepfaceswap.tech' || host === 'deepfaceswap.tech') {
    window.ADMIN_API_BASE = 'https://api.deepfaceswap.tech/api/admin';
  } else {
    window.ADMIN_API_BASE = '/api/admin';
  }
})();

function getAdminApiBase() {
  return String(window.ADMIN_API_BASE || '/api/admin').replace(/\/$/, '');
}
