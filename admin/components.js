// =============================================
// AI换图 管理后台 - PC端公共组件库
// =============================================

const API_BASE = '/api/admin';

// ---- Toast ----
const Toast = {
  container: null,
  init() {
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.id = 'toast-container';
      this.container.style.cssText = 'position:fixed;top:16px;right:16px;z-index:9999;display:flex;flex-direction:column;gap:8px;';
      document.body.appendChild(this.container);
    }
  },
  show(message, type = 'success', duration = 3000) {
    this.init();
    const colors = { success:'#10b981', error:'#ef4444', warning:'#f59e0b', info:'#3b82f6' };
    const el = document.createElement('div');
    el.style.cssText = `background:${colors[type]};color:#fff;padding:10px 16px;border-radius:8px;font-size:14px;box-shadow:0 4px 12px rgba(0,0,0,.15);transform:translateX(120%);transition:transform .3s;min-width:240px;`;
    el.textContent = message;
    this.container.appendChild(el);
    requestAnimationFrame(() => el.style.transform = 'translateX(0)');
    setTimeout(() => { el.style.transform = 'translateX(120%)'; setTimeout(() => el.remove(), 300); }, duration);
  },
  success(msg) { this.show(msg, 'success'); },
  error(msg) { this.show(msg, 'error'); },
  warning(msg) { this.show(msg, 'warning'); },
  info(msg) { this.show(msg, 'info'); }
};

// ---- API ----
const API = {
  getToken() { return localStorage.getItem('admin_token'); },
  getHeaders() {
    return { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + this.getToken() };
  },
  async request(method, url, data = null) {
    const opts = { method, headers: this.getHeaders() };
    if (data && method !== 'GET') opts.body = JSON.stringify(data);
    const res = await fetch(API_BASE + url, opts);
    if (res.status === 401) {
      localStorage.removeItem('admin_token');
      localStorage.removeItem('admin_info');
      Toast.error('登录已过期');
      setTimeout(() => location.href = 'login.html', 800);
      throw new Error('Unauthorized');
    }
    const json = await res.json();
    if (!json.success) throw new Error(json.error || '请求失败');
    return json.data;
  },
  get(url) { return this.request('GET', url); },
  post(url, data) { return this.request('POST', url, data); },
  put(url, data) { return this.request('PUT', url, data); },
  del(url) { return this.request('DELETE', url); }
};

// ---- Auth ----
function checkAuth() {
  if (!API.getToken()) { location.href = 'login.html'; return false; }
  return true;
}

// ---- Layout ----
function renderSidebar(activeKey) {
  const admin = JSON.parse(localStorage.getItem('admin_info') || '{}');
  const items = [
    { key: 'dashboard', label: '仪表盘', icon: 'M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6', href: 'index.html' },
    { key: 'users', label: '用户管理', icon: 'M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z', href: 'users.html' },
    { key: 'templates', label: '模板管理', icon: 'M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z', href: 'templates.html' },
    { key: 'plans', label: '套餐管理', icon: 'M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10', href: 'plans.html' },
    { key: 'generations', label: '生成记录', icon: 'M13 10V3L4 14h7v7l9-11h-7z', href: 'generations.html' },
    { key: 'orders', label: '订单管理', icon: 'M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2', href: 'orders.html' }
  ];
  return `<div class="flex h-screen">
  <aside style="width:240px;min-width:240px;background:linear-gradient(180deg,#1e293b,#0f172a);" class="flex flex-col text-white">
    <div class="h-14 flex items-center px-5 border-b border-white/10 flex-shrink-0">
      <div class="w-7 h-7 rounded-lg bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center mr-2.5 flex-shrink-0">
        <svg class="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
      </div>
      <span class="text-base font-bold tracking-wide">AI换图后台</span>
    </div>
    <nav class="flex-1 py-3 px-3 overflow-y-auto">
      <ul class="space-y-0.5">
        ${items.map(i => `<li>
          <a href="${i.href}" class="flex items-center gap-2.5 px-3 py-2 rounded-lg text-sm transition-colors ${activeKey === i.key ? 'bg-indigo-600/90 text-white shadow' : 'text-gray-400 hover:text-white hover:bg-white/5'}">
            <svg class="w-4.5 h-4.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="${i.icon}"/></svg>
            <span>${i.label}</span>
          </a>
        </li>`).join('')}
      </ul>
    </nav>
    <div class="px-3 py-3 border-t border-white/10">
      <a href="#" onclick="event.preventDefault();localStorage.removeItem('admin_token');localStorage.removeItem('admin_info');location.href='login.html';"
         class="flex items-center gap-2.5 px-3 py-2 rounded-lg text-sm text-red-400 hover:bg-red-500/10 hover:text-red-300 transition-colors">
        <svg class="w-4.5 h-4.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/></svg>
        <span>退出登录</span>
      </a>
    </div>
  </aside>
  <div class="flex-1 flex flex-col min-w-0">`;
}

function renderTopbar(title) {
  const admin = JSON.parse(localStorage.getItem('admin_info') || '{}');
  return `  <header class="h-14 bg-white border-b border-gray-200 flex items-center justify-between px-6 flex-shrink-0">
    <h1 class="text-base font-semibold text-gray-800">${title}</h1>
    <div class="flex items-center gap-3">
      <span class="text-xs text-gray-400" id="clock"></span>
      <div class="flex items-center gap-2 pl-3 border-l border-gray-200">
        <div class="w-7 h-7 rounded-full bg-indigo-500 flex items-center justify-center text-white text-xs font-bold">${(admin.username || 'A').charAt(0).toUpperCase()}</div>
        <span class="text-sm text-gray-600">${admin.nickname || admin.username || 'Admin'}</span>
      </div>
    </div>
  </header>
  <main class="flex-1 overflow-auto p-6 bg-gray-50">`;
}

function renderFooter() {
  return `  </main></div></div>`;
}

// ---- Components ----
function statusBadge(status) {
  const m = {
    completed: { t:'完成', c:'bg-green-100 text-green-700' },
    failed: { t:'失败', c:'bg-red-100 text-red-700' },
    processing: { t:'处理中', c:'bg-blue-100 text-blue-700' },
    pending: { t:'待处理', c:'bg-yellow-100 text-yellow-700' },
    cancelled: { t:'已取消', c:'bg-gray-100 text-gray-500' },
    success: { t:'成功', c:'bg-green-100 text-green-700' },
    paid: { t:'已支付', c:'bg-green-100 text-green-700' },
    free: { t:'免费', c:'bg-gray-100 text-gray-500' },
    monthly: { t:'月度', c:'bg-blue-100 text-blue-700' },
    yearly: { t:'年度', c:'bg-purple-100 text-purple-700' },
    active: { t:'上架', c:'bg-green-100 text-green-700' },
    offline: { t:'下架', c:'bg-gray-100 text-gray-500' },
    image: { t:'图片', c:'bg-cyan-100 text-cyan-700' },
    video: { t:'视频', c:'bg-pink-100 text-pink-700' }
  };
  const s = m[status] || { t: status || '-', c:'bg-gray-100 text-gray-500' };
  return `<span class="inline-block px-2 py-0.5 rounded text-xs font-medium ${s.c}">${s.t}</span>`;
}

function renderPagination(page, total, pageSize, fnName) {
  const pages = Math.ceil(total / pageSize);
  if (pages <= 1) return `<div class="text-xs text-gray-400 mt-4">共 ${total} 条</div>`;
  let btns = '';
  for (let i = 1; i <= pages; i++) {
    if (pages > 7 && i > 2 && i < pages - 1 && Math.abs(i - page) > 1) {
      if (i === 3 || i === pages - 2) btns += `<span class="px-2 text-gray-400">...</span>`;
      continue;
    }
    btns += `<button onclick="${fnName}(${i})" class="px-3 py-1 text-sm rounded border ${i===page?'bg-indigo-600 text-white border-indigo-600':'text-gray-600 border-gray-300 hover:bg-gray-50'}">${i}</button>`;
  }
  return `<div class="flex items-center justify-between mt-4 text-sm">
    <span class="text-gray-500">共 ${total} 条记录</span>
    <div class="flex items-center gap-1">
      <button onclick="${fnName}(${page-1})" ${page<=1?'disabled':''} class="px-3 py-1 text-sm rounded border border-gray-300 text-gray-600 hover:bg-gray-50 disabled:text-gray-300 disabled:cursor-not-allowed">上一页</button>
      ${btns}
      <button onclick="${fnName}(${page+1})" ${page>=pages?'disabled':''} class="px-3 py-1 text-sm rounded border border-gray-300 text-gray-600 hover:bg-gray-50 disabled:text-gray-300 disabled:cursor-not-allowed">下一页</button>
    </div>
  </div>`;
}

function loadingSpinner() {
  return `<div class="flex items-center justify-center py-20"><div class="w-8 h-8 border-3 border-indigo-200 border-t-indigo-600 rounded-full animate-spin"></div><span class="ml-3 text-sm text-gray-400">加载中...</span></div>`;
}

function emptyState(msg = '暂无数据') {
  return `<div class="text-center py-16 text-gray-400"><svg class="w-12 h-12 mx-auto mb-3 opacity-40" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"/></svg><p class="text-sm">${msg}</p></div>`;
}

function confirmDialog(msg, onOk) {
  const el = document.createElement('div');
  el.className = 'fixed inset-0 bg-black/40 z-[9998] flex items-center justify-center';
  el.onclick = e => { if (e.target === el) el.remove(); };
  el.innerHTML = `<div class="bg-white rounded-xl shadow-xl w-96 p-6">
    <h3 class="text-base font-semibold text-gray-800 mb-2">确认操作</h3>
    <p class="text-sm text-gray-500 mb-5">${msg}</p>
    <div class="flex justify-end gap-2">
      <button onclick="this.closest('.fixed').remove()" class="px-4 py-1.5 text-sm border border-gray-300 rounded-lg text-gray-600 hover:bg-gray-50">取消</button>
      <button id="_cfm" class="px-4 py-1.5 text-sm bg-red-500 text-white rounded-lg hover:bg-red-600">确认</button>
    </div></div>`;
  document.body.appendChild(el);
  el.querySelector('#_cfm').onclick = () => { el.remove(); onOk(); };
}

function formatDate(s) {
  if (!s) return '-';
  return new Date(s).toLocaleString('zh-CN', { year:'numeric', month:'2-digit', day:'2-digit', hour:'2-digit', minute:'2-digit' });
}

function pageHead(title) {
  return `<!DOCTYPE html><html lang="zh-CN"><head>
<meta charset="UTF-8"><meta name="viewport" content="width=1280">
<title>${title} - AI换图管理后台</title>
<script src="https://cdn.tailwindcss.com"></script>
<style>
[x-cloak]{display:none!important}
body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI','PingFang SC','Microsoft YaHei',sans-serif;font-size:14px;margin:0}
::-webkit-scrollbar{width:5px;height:5px}
::-webkit-scrollbar-thumb{background:#d1d5db;border-radius:3px}
table{border-collapse:collapse}
th{background:#f8fafc;font-weight:500;text-align:left;color:#64748b;font-size:13px;padding:10px 12px;border-bottom:1px solid #e5e7eb;white-space:nowrap}
td{padding:10px 12px;border-bottom:1px solid #f1f5f9;color:#374151;font-size:13px}
tbody tr{transition:background .15s}
tbody tr:hover{background:#f8fafc}
.btn{display:inline-flex;align-items:center;gap:4px;padding:5px 12px;border-radius:6px;font-size:13px;cursor:pointer;transition:all .15s;border:none;outline:none}
.btn-primary{background:#6366f1;color:#fff}.btn-primary:hover{background:#4f46e5}
.btn-danger{background:#fee2e2;color:#dc2626}.btn-danger:hover{background:#fecaca}
.btn-ghost{background:transparent;color:#6366f1}.btn-ghost:hover{background:#eef2ff}
.btn-sm{padding:3px 8px;font-size:12px}
input,select,textarea{font-size:13px;padding:7px 10px;border:1px solid #e5e7eb;border-radius:6px;outline:none;transition:border .15s}
input:focus,select:focus,textarea:focus{border-color:#6366f1;box-shadow:0 0 0 2px rgba(99,102,241,.1)}
.modal-overlay{position:fixed;inset:0;background:rgba(0,0,0,.4);z-index:999;display:flex;align-items:center;justify-content:center}
.modal-overlay .modal{background:#fff;border-radius:12px;box-shadow:0 20px 60px rgba(0,0,0,.15);width:520px;max-height:80vh;overflow-y:auto}
.modal .modal-header{padding:16px 20px;border-bottom:1px solid #e5e7eb;display:flex;align-items:center;justify-content:between}
.modal .modal-body{padding:20px}
.modal .modal-footer{padding:12px 20px;border-top:1px solid #e5e7eb;display:flex;justify-content:flex-end;gap:8px}
.form-group{margin-bottom:14px}
.form-group label{display:block;font-size:13px;color:#374151;margin-bottom:4px;font-weight:500}
.form-group input,.form-group select,.form-group textarea{width:100%;box-sizing:border-box}
</style>
<script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
<script src="components.js"></script>
</head><body class="h-screen overflow-hidden bg-gray-50">`;
}
