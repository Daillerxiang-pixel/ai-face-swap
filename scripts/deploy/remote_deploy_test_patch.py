#!/usr/bin/env python3
"""
测试机补丁部署 — 仅上传少量文件（admin 批量导入相关），包体小，不易断线。

用法:
  $env:DEPLOY_SSH_PASSWORD = '...'
  python scripts/deploy/remote_deploy_test_patch.py
"""
from __future__ import annotations

import os
import subprocess
import sys
import tempfile

try:
    import paramiko
except ImportError:
    print("需要: pip install paramiko", file=sys.stderr)
    sys.exit(1)

HOST = os.environ.get("DEPLOY_HOST", "39.102.100.123")
USER = os.environ.get("DEPLOY_USER", "root")
PASSWORD = os.environ.get("DEPLOY_SSH_PASSWORD")
REMOTE_TGZ = "/tmp/ai-face-swap-test-patch.tgz"
APP_DIR = "/var/www/ai-face-swap-test"

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(os.path.dirname(SCRIPT_DIR))

PATCH_PATHS = [
    "server/routes/admin.js",
    "server/routes/admin-template-import.js",
    "server/index.js",
    "server/package.json",
    "admin/templates.html",
    "admin/components.js",
]


def main() -> int:
    if not PASSWORD:
        print("请设置环境变量 DEPLOY_SSH_PASSWORD", file=sys.stderr)
        return 1

    if hasattr(sys.stdout, "reconfigure"):
        try:
            sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        except Exception:
            pass

    tgz = os.path.join(tempfile.gettempdir(), "ai-face-swap-test-patch.tgz")
    print(f"[本地] 打包补丁 -> {tgz}", flush=True)
    args = ["tar", "-czf", tgz, "-C", PROJECT_ROOT] + PATCH_PATHS
    subprocess.run(args, check=True)
    size = os.path.getsize(tgz)
    print(f"[本地] 包大小 {size} 字节", flush=True)

    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    print(f"[SSH] 连接 {USER}@{HOST} …", flush=True)
    try:
        client.connect(
            HOST,
            username=USER,
            password=PASSWORD,
            timeout=60,
            allow_agent=False,
            look_for_keys=False,
        )
    except Exception as e:
        print(f"[SSH] 连接失败: {e}", file=sys.stderr)
        return 1

    try:
        sftp = client.open_sftp()
        print(f"[SFTP] 上传 -> {REMOTE_TGZ}", flush=True)
        sftp.put(tgz, REMOTE_TGZ)
        sftp.close()

        install = f"""set -euo pipefail
cd {APP_DIR}
tar -xzf {REMOTE_TGZ}
cd {APP_DIR}/server && npm install --production
cd {APP_DIR} && pm2 restart ai-face-swap-test --update-env
sleep 2
curl -s -o /dev/null -w "api:%{{http_code}}\\n" http://127.0.0.1:8082/api/templates || true
echo PATCH_OK
"""
        print("[SSH] 解压 + npm + pm2 …", flush=True)
        stdin, stdout, stderr = client.exec_command(install, get_pty=True)
        for line in iter(stdout.readline, ""):
            sys.stdout.write(line)
            sys.stdout.flush()
        err = stderr.read().decode("utf-8", errors="replace")
        if err:
            print(err, file=sys.stderr)
        code = stdout.channel.recv_exit_status()
        if code != 0:
            print(f"[SSH] 退出码: {code}", file=sys.stderr)
            return code
    finally:
        client.close()

    print("[完成] https://test1.kanashortplay.com/admin/templates.html", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
