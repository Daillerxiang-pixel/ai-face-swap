#!/usr/bin/env python3
"""配置 Nginx + 尝试 Let's Encrypt（需在服务器上已有 /var/www/ai-face-swap）。"""
from __future__ import annotations

import os
import sys

try:
    import paramiko
except ImportError:
    print("pip install paramiko", file=sys.stderr)
    sys.exit(1)

HOST = os.environ.get("DEPLOY_HOST", "159.223.152.94")
USER = os.environ.get("DEPLOY_USER", "root")
PASSWORD = os.environ.get("DEPLOY_SSH_PASSWORD")
DOMAIN = os.environ.get("DEPLOY_DOMAIN", "test.kanashortplay.com")
EMAIL = os.environ.get("CERT_EMAIL", "deploy@kanashortplay.com")

REMOTE = f"""set -e
APP=/var/www/ai-face-swap
mkdir -p /var/www/certbot
cp "$APP/config/nginx-bootstrap-http.conf" /etc/nginx/sites-available/ai-face-swap.conf
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/ai-face-swap.conf /etc/nginx/sites-enabled/ai-face-swap.conf
nginx -t
systemctl reload nginx
set +e
certbot certonly --webroot -w /var/www/certbot -d {DOMAIN} --non-interactive --agree-tos --email {EMAIL} --expand
CERT_OK=$?
set -e
if [ "$CERT_OK" -eq 0 ] && [ -f "/etc/letsencrypt/live/{DOMAIN}/fullchain.pem" ]; then
  cp "$APP/config/nginx-prod.conf" /etc/nginx/sites-available/ai-face-swap.conf
  nginx -t
  systemctl reload nginx
  echo "HTTPS_OK"
else
  echo "HTTPS_SKIP (check DNS A record -> this server)"
fi
curl -s -o /dev/null -w "HTTP_LOCAL %{{http_code}}\\n" http://127.0.0.1/api/templates -H "Host: {DOMAIN}"
"""


def main() -> int:
    if not PASSWORD:
        print("Set DEPLOY_SSH_PASSWORD", file=sys.stderr)
        return 1
    if hasattr(sys.stdout, "reconfigure"):
        try:
            sys.stdout.reconfigure(encoding="utf-8", errors="replace")
            sys.stderr.reconfigure(encoding="utf-8", errors="replace")
        except Exception:
            pass
    c = paramiko.SSHClient()
    c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    c.connect(HOST, username=USER, password=PASSWORD, timeout=120, allow_agent=False, look_for_keys=False)
    try:
        _, out, err = c.exec_command(REMOTE, get_pty=False)
        sys.stdout.write(out.read().decode("utf-8", errors="replace"))
        se = err.read().decode("utf-8", errors="replace")
        if se:
            sys.stderr.write(se)
        return out.channel.recv_exit_status()
    finally:
        c.close()


if __name__ == "__main__":
    raise SystemExit(main())
