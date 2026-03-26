#!/bin/bash
# ============================================
# AI换图 — 一键部署脚本
# 目标: Ubuntu 22.04 x64
# 服务器: 39.102.100.123
# 生成时间: 2026-03-23
# ============================================

set -euo pipefail

# ---- 颜色 ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }
info() { echo -e "${CYAN}[→]${NC} $1"; }

# ---- 配置 ----
APP_NAME="ai-face-swap"
APP_DIR="/var/www/ai-face-swap"
APP_PORT=8080
NODE_VERSION="22"
PM2_APP="$APP_NAME"

echo ""
echo "=========================================="
echo "  AI换图 — 环境安装 & 首次部署"
echo "  服务器: $(hostname) ($(uname -m))"
echo "=========================================="
echo ""

# ---- Step 1: 系统更新 ----
info "Step 1/7: 系统更新"
sudo apt-get update -y
sudo apt-get upgrade -y
log "系统更新完成"

# ---- Step 2: 安装基础工具 ----
info "Step 2/7: 安装基础工具"
sudo apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    nginx \
    ufw \
    certbot \
    python3-certbot-nginx
log "基础工具安装完成"

# ---- Step 3: 安装 Node.js 22 ----
info "Step 3/7: 安装 Node.js $NODE_VERSION"
if command -v node &> /dev/null; then
    NODE_VER=$(node -v | sed 's/v//' | cut -d. -f1)
    if [ "$NODE_VER" -ge "$NODE_VERSION" ]; then
        log "Node.js 已安装: $(node -v)，跳过"
    else
        warn "Node.js 版本过低: $(node -v)，需要 v$NODE_VERSION+，重新安装..."
        curl -fsSL https://deb.nodesource.com/setup_$NODE_VERSION.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
else
    curl -fsSL https://deb.nodesource.com/setup_$NODE_VERSION.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi
log "Node.js $(node -v) / npm $(npm -v)"

# ---- Step 4: 安装 PM2 ----
info "Step 4/7: 安装 PM2"
if ! command -v pm2 &> /dev/null; then
    sudo npm install -g pm2
    pm2 startup systemd -u root --hp /root 2>/dev/null || true
    log "PM2 安装完成: $(pm2 -v)"
else
    log "PM2 已安装: $(pm2 -v)"
fi

# ---- Step 5: 创建应用目录 ----
info "Step 5/7: 创建应用目录"
sudo mkdir -p "$APP_DIR/server/data"
sudo mkdir -p "$APP_DIR/uploads"
sudo mkdir -p /var/log/$APP_NAME
log "目录创建完成: $APP_DIR"

# ---- Step 6: 初始化 Git 仓库（如果没有） ----
info "Step 6/7: 检查 Git 仓库"
if [ ! -d "$APP_DIR/.git" ]; then
    warn "目录不是 Git 仓库，请手动 clone 或上传代码"
    warn "  cd $APP_DIR && git init"
    warn "  或: git clone <your-repo-url> $APP_DIR"
else
    log "Git 仓库已存在"
fi

# ---- Step 7: 安装依赖 ----
info "Step 7/7: 安装项目依赖"
if [ -f "$APP_DIR/package.json" ]; then
    cd "$APP_DIR"
    npm install --production
    log "依赖安装完成"
else
    warn "package.json 不存在，请先上传代码后执行: cd $APP_DIR && npm install --production"
fi

echo ""
echo "=========================================="
echo -e "  ${GREEN}环境安装完成！${NC}"
echo "=========================================="
echo ""
echo "后续步骤："
echo "  1. 上传代码到 $APP_DIR"
echo "  2. 配置 .env 文件"
echo "  3. 启动服务: pm2 start ecosystem.config.js"
echo "  4. 配置 Nginx: sudo cp config/nginx.conf /etc/nginx/conf.d/ai-face-swap.conf"
echo "  5. 测试: sudo nginx -t && sudo nginx -s reload"
echo ""
