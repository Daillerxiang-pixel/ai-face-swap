#!/usr/bin/env python3
"""
正式机轻量部署 — 与测试服使用**同一套排除规则**打 tar，保证「测过什么就发什么」。

流程：仓库根目录 git rev-parse → tar（排除 node_modules/.git/app_temp/…/server/.env）→
上传 159.223.152.94 → 解压到 /var/www/ai-face-swap → npm → pm2 restart → curl 校验。

密码：环境变量 DEPLOY_SSH_PASSWORD 或 F:\\work\\server-deploy\\ai-face-swap\\credentials.local.env

用法:
  python scripts/deploy/prod_light_deploy.py
  python scripts/deploy/prod_light_deploy.py --no-bundle   # 已手动打好 %TEMP%\\ai-face-swap-deploy.tgz
"""
from __future__ import annotations

import os
import subprocess
import sys
import tempfile

try:
    import paramiko
except ImportError:
    print("pip install paramiko", file=sys.stderr)
    sys.exit(1)

DEFAULT_CREDENTIALS = r"F:\work\server-deploy\ai-face-swap\credentials.local.env"
# 正式机固定 IP；勿用通用 DEPLOY_HOST（本机常指向测试机导致误发）
HOST = os.environ.get("AI_FACE_SWAP_PROD_HOST", "159.223.152.94")
REMOTE_TGZ = "/tmp/ai-face-swap-deploy.tgz"
APP_DIR = "/var/www/ai-face-swap"
TGZ_NAME = "ai-face-swap-deploy.tgz"

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(os.path.dirname(SCRIPT_DIR))


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


def _git_head() -> str:
    try:
        r = subprocess.run(
            ["git", "rev-parse", "HEAD"],
            cwd=PROJECT_ROOT,
            capture_output=True,
            text=True,
            timeout=30,
            check=False,
        )
        return (r.stdout or "").strip() or "(no git)"
    except Exception:
        return "(git error)"


def _bundle() -> str:
    tgz = os.path.join(tempfile.gettempdir(), TGZ_NAME)
    commit = _git_head()
    print(f"[bundle] Git HEAD = {commit}", flush=True)
    print(f"[bundle] writing {tgz}", flush=True)
    subprocess.run(
        [
            "tar",
            "-czf",
            tgz,
            "--exclude=node_modules",
            "--exclude=.git",
            "--exclude=app_temp",
            "--exclude=uploads",
            "--exclude=logs",
            "--exclude=server/.env",
            "--exclude=*.apk",
            "-C",
            PROJECT_ROOT,
            ".",
        ],
        check=True,
    )
    print(f"[bundle] ok ({os.path.getsize(tgz)} bytes)", flush=True)
    return tgz


def main() -> int:
    _load_credentials_file()
    password = os.environ.get("DEPLOY_SSH_PASSWORD")
    if not password:
        print(
            "Set DEPLOY_SSH_PASSWORD or create " + DEFAULT_CREDENTIALS,
            file=sys.stderr,
        )
        return 1

    bundle_first = "--no-bundle" not in sys.argv
    tgz = os.path.join(tempfile.gettempdir(), TGZ_NAME)
    if bundle_first:
        tgz = _bundle()
    elif not os.path.isfile(tgz):
        print(f"Missing {tgz} (run without --no-bundle to create)", file=sys.stderr)
        return 1

    if hasattr(sys.stdout, "reconfigure"):
        try:
            sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        except Exception:
            pass

    print(f"[SFTP] {tgz} -> {HOST}:{REMOTE_TGZ} ({os.path.getsize(tgz)} bytes) ...", flush=True)
    c = paramiko.SSHClient()
    c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    c.connect(
        HOST,
        username="root",
        password=password,
        timeout=300,
        banner_timeout=120,
        auth_timeout=120,
        allow_agent=False,
        look_for_keys=False,
    )
    sftp = c.open_sftp()
    sftp.put(tgz, REMOTE_TGZ)
    sftp.close()
    print("[SSH] extract + npm install + pm2 restart ...", flush=True)

    install = f"""set -euo pipefail
mkdir -p {APP_DIR}
tar -xzf {REMOTE_TGZ} -C {APP_DIR}
cd {APP_DIR}/server && npm install --production
cd {APP_DIR} && pm2 restart ai-face-swap --update-env
sleep 4
curl -s -o /dev/null -w "templates_http:%{{http_code}}\\n" http://127.0.0.1:8080/api/templates
echo "deploy_ok"
"""
    stdin, stdout, stderr = c.exec_command(install, get_pty=False, timeout=600)
    out = stdout.read().decode("utf-8", errors="replace")
    err = stderr.read().decode("utf-8", errors="replace")
    print(out)
    if err:
        print(err, file=sys.stderr)
    code = stdout.channel.recv_exit_status()
    c.close()
    if code == 0 and "templates_http:200" in out:
        print("[done] 正式服与当前仓库提交一致（与测试服同一打包方式）。", flush=True)
    return code


if __name__ == "__main__":
    raise SystemExit(main())
