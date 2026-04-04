#!/bin/bash
# 在已与 ibooks 等共存的 Ubuntu 服务器上「仅新增」ai-face-swap 测试实例。
# - 目录：/var/www/ai-face-swap-test
# - PM2：ai-face-swap-test
# - 端口：8082（ibooks 使用 8081，请勿占用）
# - Nginx：新增 sites-available/ai-face-swap-test1.conf，不删除 default、不覆盖其他站点
# - 防火墙：不执行 ufw --force enable（避免影响已有策略）
#
# 环境变量：DEPLOY_DOMAIN（默认 test1.kanashortplay.com）、CERT_EMAIL、TEST_PORT（默认 8082）

set -euo pipefail

APP_DIR="/var/www/ai-face-swap-test"
DOMAIN="${DEPLOY_DOMAIN:-test1.kanashortplay.com}"
CERT_EMAIL="${CERT_EMAIL:-deploy@kanashortplay.com}"
TEST_PORT="${TEST_PORT:-8082}"
PM2_NAME="ai-face-swap-test"

export DEBIAN_FRONTEND=noninteractive

echo "[1/6] apt 基础包（已安装时会跳过）..."
apt-get update -y
apt-get install -y curl git nginx certbot openssl build-essential python3

echo "[2/6] Node.js 22 + PM2..."
if ! command -v node >/dev/null 2>&1; then
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
  apt-get install -y nodejs
fi
if ! command -v pm2 >/dev/null 2>&1; then
  npm install -g pm2
fi

mkdir -p "$APP_DIR/server/data" "$APP_DIR/uploads" "$APP_DIR/logs" \
  /var/www/certbot /var/www/backups/ai-face-swap-test

echo "[3/6] npm install (server)..."
cd "$APP_DIR/server"
npm install --production

echo "[4/6] server/.env（测试环境独立库与密钥）..."
if [ ! -f .env ]; then
  if [ -f "$APP_DIR/.env.example" ]; then
    cp "$APP_DIR/.env.example" .env
  elif [ -f .env.example ]; then
    cp .env.example .env
  else
    echo "NODE_ENV=production
PORT=$TEST_PORT
JWT_SECRET=$(openssl rand -hex 32)
" > .env
  fi
fi
if grep -q '^JWT_SECRET=请' .env 2>/dev/null || ! grep -q '^JWT_SECRET=' .env 2>/dev/null; then
  sed -i "s/^JWT_SECRET=.*/JWT_SECRET=$(openssl rand -hex 32)/" .env || \
    echo "JWT_SECRET=$(openssl rand -hex 32)" >> .env
fi
sed -i 's/^NODE_ENV=.*/NODE_ENV=production/' .env 2>/dev/null || echo "NODE_ENV=production" >> .env
grep -q '^PORT=' .env && sed -i "s/^PORT=.*/PORT=$TEST_PORT/" .env || echo "PORT=$TEST_PORT" >> .env

echo "[5/6] PM2（仅管理本测试进程，不影响 ibooks-server）..."
cd "$APP_DIR"
export NODE_ENV=production
pm2 delete "$PM2_NAME" 2>/dev/null || true
pm2 start ecosystem.test.config.js --env production
pm2 save
pm2 startup systemd -u root --hp /root 2>/dev/null || true

echo "[6/6] Nginx（新增站点文件，不删除 sites-enabled/default）..."
mkdir -p /var/www/certbot
cp "$APP_DIR/config/nginx-bootstrap-test1-http.conf" /etc/nginx/sites-available/ai-face-swap-test1.conf
ln -sf /etc/nginx/sites-available/ai-face-swap-test1.conf /etc/nginx/sites-enabled/ai-face-swap-test1.conf
nginx -t
systemctl reload nginx

echo "跳过 ufw（与 ibooks 等同机时请沿用现有安全组/防火墙策略）。"
echo "尝试申请 SSL（需 DNS: $DOMAIN -> 本机公网 IP，且 80 端口可达）..."
set +e
certbot certonly --webroot -w /var/www/certbot -d "$DOMAIN" \
  --non-interactive --agree-tos --email "$CERT_EMAIL" --expand
CERT_OK=$?
set -e

if [ "$CERT_OK" -eq 0 ] && [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
  echo "启用 HTTPS 配置 (config/nginx-test1.conf)..."
  cp "$APP_DIR/config/nginx-test1.conf" /etc/nginx/sites-available/ai-face-swap-test1.conf
  nginx -t
  systemctl reload nginx
else
  echo "证书未签发，继续使用 HTTP bootstrap。请检查 DNS 后手动："
  echo "  certbot certonly --webroot -w /var/www/certbot -d $DOMAIN"
  echo "  cp $APP_DIR/config/nginx-test1.conf /etc/nginx/sites-available/ai-face-swap-test1.conf && nginx -t && systemctl reload nginx"
fi

echo "健康检查: curl -s http://127.0.0.1:${TEST_PORT}/api/templates"
curl -s -o /dev/null -w "HTTP %{http_code}\n" "http://127.0.0.1:${TEST_PORT}/api/templates" || true
echo "完成。"
