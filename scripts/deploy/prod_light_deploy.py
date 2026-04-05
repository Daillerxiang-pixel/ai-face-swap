#!/usr/bin/env python3
"""
正式机轻量部署：本机打好 %TEMP%\\ai-face-swap-deploy.tgz 后上传、解压、npm、pm2。
密码优先级：环境变量 DEPLOY_SSH_PASSWORD > F:\\work\\server-deploy\\ai-face-swap\\credentials.local.env
用法（PowerShell）:
  cd 仓库根目录
  tar ... ai-face-swap-deploy.tgz  （与 remote_deploy.py 排除项一致）
  python scripts/deploy/prod_light_deploy.py
"""
from __future__ import annotations

import os
import sys
import tempfile

try:
    import paramiko
except ImportError:
    print("pip install paramiko", file=sys.stderr)
    sys.exit(1)

DEFAULT_CREDENTIALS = r"F:\work\server-deploy\ai-face-swap\credentials.local.env"
HOST = os.environ.get("DEPLOY_HOST", "159.223.152.94")
REMOTE_TGZ = "/tmp/ai-face-swap-deploy.tgz"
APP_DIR = "/var/www/ai-face-swap"


def _load_credentials_file() -> None:
    path = os.environ.get("DEPLOY_CREDENTIALS_FILE", DEFAULT_CREDENTIALS)
    if not os.path.isfile(path):
        return
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, val = line.partition("=")
            key, val = key.strip(), val.strip().strip('"').strip("'")
            if key and key not in os.environ:
                os.environ[key] = val


def main() -> int:
    _load_credentials_file()
    password = os.environ.get("DEPLOY_SSH_PASSWORD")
    if not password:
        print(
            "Set DEPLOY_SSH_PASSWORD or create "
            + DEFAULT_CREDENTIALS,
            file=sys.stderr,
        )
        return 1

    tgz = os.path.join(tempfile.gettempdir(), "ai-face-swap-deploy.tgz")
    if not os.path.isfile(tgz):
        print(f"Missing {tgz} — create tarball first (see docs/SERVER-DEPLOY.md)", file=sys.stderr)
        return 1

    if hasattr(sys.stdout, "reconfigure"):
        try:
            sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        except Exception:
            pass

    print(f"[SFTP] uploading {tgz} -> {HOST}:{REMOTE_TGZ} ...", flush=True)
    c = paramiko.SSHClient()
    c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    c.connect(
        HOST,
        username="root",
        password=password,
        timeout=180,
        allow_agent=False,
        look_for_keys=False,
    )
    sftp = c.open_sftp()
    sftp.put(tgz, REMOTE_TGZ)
    sftp.close()
    print("[SSH] extract + npm + pm2 ...", flush=True)

    install = f"""set -euo pipefail
mkdir -p {APP_DIR}
tar -xzf {REMOTE_TGZ} -C {APP_DIR}
cd {APP_DIR}/server && npm install --production
cd {APP_DIR} && pm2 restart ai-face-swap --update-env
sleep 3
curl -s -o /dev/null -w "templates_http:%{{http_code}}\\n" http://127.0.0.1:8080/api/templates
"""
    stdin, stdout, stderr = c.exec_command(install, get_pty=False)
    out = stdout.read().decode("utf-8", errors="replace")
    err = stderr.read().decode("utf-8", errors="replace")
    print(out)
    if err:
        print(err, file=sys.stderr)
    code = stdout.channel.recv_exit_status()
    c.close()
    return code


if __name__ == "__main__":
    raise SystemExit(main())
