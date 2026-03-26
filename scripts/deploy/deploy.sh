#!/bin/bash
# AI 换图 - Linux 服务器部署脚本
# 服务器：Ubuntu 22.04 x64
# 目标路径：/var/www/ai-face-swap

set -e

APP_NAME="ai-face-swap"
APP_DIR="/var/www/ai-face-swap"
LOG_DIR="/var/log/ai-face-swap"
BACKUP_DIR="/var/www/backups/ai-face-swap"

echo "========================================"
echo "  AI 换图 - 服务器部署脚本"
echo "  目标：$APP_DIR"
echo "========================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 1. 检查环境
echo ""
log_info "步骤 1/7: 检查环境..."

if ! command -v node &> /dev/null; then
    log_error "Node.js 未安装"
    exit 1
fi
log_info "Node.js 版本：$(node --version)"

if ! command -v pm2 &> /dev/null; then
    log_warn "PM2 未安装，正在安装..."
    sudo npm install -g pm2
fi
log_info "PM2 版本：$(pm2 --version)"

# 2. 创建目录
echo ""
log_info "步骤 2/7: 创建目录..."
sudo mkdir -p "$APP_DIR"
sudo mkdir -p "$LOG_DIR"
sudo mkdir -p "$BACKUP_DIR"
sudo chown -R $USER:$USER "$APP_DIR"
sudo chown -R $USER:$USER "$LOG_DIR"
sudo chown -R $USER:$USER "$BACKUP_DIR"

# 3. 备份数据库
echo ""
log_info "步骤 3/7: 备份数据库..."
if [ -f "$APP_DIR/server/data/face_swap.db" ]; then
    BACKUP_FILE="$BACKUP_DIR/face_swap-$(date +%Y%m%d-%H%M%S).db"
    cp "$APP_DIR/server/data/face_swap.db" "$BACKUP_FILE"
    log_info "数据库已备份：$BACKUP_FILE"
else
    log_warn "数据库文件不存在，跳过备份"
fi

# 4. 更新代码
echo ""
log_info "步骤 4/7: 更新代码..."
cd "$APP_DIR"

if [ -d ".git" ]; then
    git pull origin main
    log_info "代码已更新"
else
    log_warn "非 Git 仓库，请手动上传代码"
fi

# 5. 安装依赖
echo ""
log_info "步骤 5/7: 安装依赖..."
cd "$APP_DIR/server"
npm install --production
log_info "依赖安装完成"

# 6. 检查环境变量
echo ""
log_info "步骤 6/7: 检查环境变量..."
if [ ! -f "$APP_DIR/.env" ]; then
    log_warn ".env 文件不存在"
    if [ -f "$APP_DIR/.env.example" ]; then
        cp "$APP_DIR/.env.example" "$APP_DIR/.env"
        log_warn "已从 .env.example 复制，请编辑 .env 填入 API 密钥"
        log_warn "按任意键继续..."
        read -n 1 -s
    fi
else
    log_info ".env 文件存在"
fi

# 7. 重启服务
echo ""
log_info "步骤 7/7: 重启服务..."
cd "$APP_DIR"
pm2 stop "$APP_NAME" 2>/dev/null || true
pm2 delete "$APP_NAME" 2>/dev/null || true
pm2 start ecosystem.config.js
pm2 save

echo ""
echo "========================================"
log_info "部署完成！"
echo "========================================"
echo ""
echo "服务状态：pm2 status $APP_NAME"
echo "查看日志：pm2 logs $APP_NAME"
echo "重启服务：pm2 restart $APP_NAME"
echo "停止服务：pm2 stop $APP_NAME"
echo ""

# 健康检查
log_info "执行健康检查..."
sleep 3
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8080/api/templates 2>/dev/null || echo "000")
if [ "$RESPONSE" = "200" ]; then
    log_info "✓ 健康检查通过 (HTTP $RESPONSE)"
else
    log_error "✗ 健康检查失败 (HTTP $RESPONSE)"
    log_warn "请检查日志：pm2 logs $APP_NAME"
fi
