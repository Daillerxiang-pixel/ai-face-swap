#!/usr/bin/env python3
"""在已解压代码的服务器上执行 npm install + PM2 启动（避免 PowerShell 解析 $(...)）。"""
from __future__ import annotations

import os
import sys

try:
    import paramiko
except ImportError:
    print("pip install paramiko", file=sys.stderr)
    sys.exit(1)

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(os.path.dirname(SCRIPT_DIR))

HOST = os.environ.get("DEPLOY_HOST", "159.223.152.94")
USER = os.environ.get("DEPLOY_USER", "root")
PASSWORD = os.environ.get("DEPLOY_SSH_PASSWORD")

REMOTE = r"""set -e
APP=/var/www/ai-face-swap
cd "$APP/server"
npm install --production
cd "$APP"
if [ ! -f server/.env ]; then
  if [ -f .env.example ]; then cp .env.example server/.env; fi
fi
if ! grep -q '^JWT_SECRET=' server/.env 2>/dev/null; then
  echo "JWT_SECRET=$(openssl rand -hex 32)" >> server/.env
fi
grep -q '^NODE_ENV=' server/.env || echo "NODE_ENV=production" >> server/.env
grep -q '^PORT=' server/.env || echo "PORT=8080" >> server/.env
export NODE_ENV=production
command -v pm2 >/dev/null || npm install -g pm2
pm2 delete ai-face-swap 2>/dev/null || true
pm2 start ecosystem.config.js --env production
pm2 save
sleep 2
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://127.0.0.1:8080/api/templates || true
pm2 logs ai-face-swap --lines 25 --nostream || true
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
    c.connect(
        HOST,
        username=USER,
        password=PASSWORD,
        timeout=120,
        allow_agent=False,
        look_for_keys=False,
    )
    try:
        eco = os.path.join(PROJECT_ROOT, "ecosystem.config.js")
        if os.path.isfile(eco):
            sftp = c.open_sftp()
            sftp.put(eco, "/var/www/ai-face-swap/ecosystem.config.js")
            sftp.close()
        _, out, err = c.exec_command(REMOTE, get_pty=False)
        so = out.read().decode("utf-8", errors="replace")
        se = err.read().decode("utf-8", errors="replace")
        sys.stdout.write(so)
        if se:
            sys.stderr.write(se)
        return out.channel.recv_exit_status()
    finally:
        c.close()


if __name__ == "__main__":
    raise SystemExit(main())
