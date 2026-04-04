#!/bin/bash
# 在 Ubuntu 服务器上执行：依赖安装、PM2、Nginx、可选 Let's Encrypt
# 假定代码已解压到 /var/www/ai-face-swap

set -euo pipefail

APP_DIR="/var/www/ai-face-swap"
DOMAIN="${DEPLOY_DOMAIN:-test.kanashortplay.com}"
CERT_EMAIL="${CERT_EMAIL:-deploy@kanashortplay.com}"

export DEBIAN_FRONTEND=noninteractive

echo "[1/6] apt 基础包..."
apt-get update -y
apt-get install -y curl git nginx ufw certbot openssl build-essential python3

echo "[2/6] Node.js 22 + PM2..."
if ! command -v node >/dev/null 2>&1; then
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
  apt-get install -y nodejs
fi
if ! command -v pm2 >/dev/null 2>&1; then
  npm install -g pm2
fi

mkdir -p "$APP_DIR/server/data" "$APP_DIR/uploads" /var/log/ai-face-swap /var/www/certbot /var/www/backups/ai-face-swap

echo "[3/6] npm install (server)..."
cd "$APP_DIR/server"
npm install --production

echo "[4/6] server/.env..."
if [ ! -f .env ]; then
  if [ -f "$APP_DIR/.env.example" ]; then
    cp "$APP_DIR/.env.example" .env
  elif [ -f .env.example ]; then
    cp .env.example .env
  else
    echo "NODE_ENV=production
PORT=8080
JWT_SECRET=$(openssl rand -hex 32)
" > .env
  fi
fi
if grep -q '^JWT_SECRET=请' .env 2>/dev/null || ! grep -q '^JWT_SECRET=' .env 2>/dev/null; then
  sed -i "s/^JWT_SECRET=.*/JWT_SECRET=$(openssl rand -hex 32)/" .env || \
    echo "JWT_SECRET=$(openssl rand -hex 32)" >> .env
fi
sed -i 's/^NODE_ENV=.*/NODE_ENV=production/' .env 2>/dev/null || echo "NODE_ENV=production" >> .env
grep -q '^PORT=' .env || echo "PORT=8080" >> .env

echo "[5/6] PM2..."
cd "$APP_DIR"
export NODE_ENV=production
pm2 delete ai-face-swap 2>/dev/null || true
pm2 start ecosystem.config.js --env production
pm2 save
pm2 startup systemd -u root --hp /root 2>/dev/null || true

echo "[6/6] Nginx + 防火墙..."
cp "$APP_DIR/config/nginx-bootstrap-http.conf" /etc/nginx/sites-available/ai-face-swap.conf
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/ai-face-swap.conf /etc/nginx/sites-enabled/ai-face-swap.conf
nginx -t
systemctl reload nginx

ufw allow OpenSSH || true
ufw allow 'Nginx Full' || true
ufw --force enable || true

echo "尝试申请 SSL（需域名 A 记录指向本机且 80 可达）..."
set +e
certbot certonly --webroot -w /var/www/certbot -d "$DOMAIN" \
  --non-interactive --agree-tos --email "$CERT_EMAIL" --expand
CERT_OK=$?
set -e

if [ "$CERT_OK" -eq 0 ] && [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
  echo "启用 HTTPS 配置 (nginx-prod.conf)..."
  cp "$APP_DIR/config/nginx-prod.conf" /etc/nginx/sites-available/ai-face-swap.conf
  nginx -t
  systemctl reload nginx
else
  echo "证书未签发，继续使用 HTTP。请检查 DNS 后手动执行："
  echo "  certbot certonly --webroot -w /var/www/certbot -d $DOMAIN"
  echo "  cp $APP_DIR/config/nginx-prod.conf /etc/nginx/sites-available/ai-face-swap.conf && nginx -t && systemctl reload nginx"
fi

echo "健康检查: curl -s http://127.0.0.1:8080/api/templates"
curl -s -o /dev/null -w "HTTP %{http_code}\n" "http://127.0.0.1:8080/api/templates" || true
echo "完成。"
