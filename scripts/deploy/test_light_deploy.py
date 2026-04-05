#!/usr/bin/env python3
"""
测试机轻量部署 — 与 prod_light_deploy.py **同一 tar 包**（先运行 prod 打包或共用 %TEMP%\\ai-face-swap-deploy.tgz）。

使用本机 SSH 公钥连接 root@39.102.100.123（不设密码时用默认密钥）。

用法:
  python scripts/deploy/test_light_deploy.py
  python scripts/deploy/test_light_deploy.py --no-bundle   # 已有 tgz
"""
from __future__ import annotations

import os
import subprocess
import sys
import tempfile

HOST = os.environ.get("AI_FACE_SWAP_TEST_HOST", "39.102.100.123")
REMOTE_TGZ = "/tmp/ai-face-swap-deploy.tgz"
APP_DIR = "/var/www/ai-face-swap-test"
TGZ_NAME = "ai-face-swap-deploy.tgz"
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(os.path.dirname(SCRIPT_DIR))


def _bundle() -> str:
    tgz = os.path.join(tempfile.gettempdir(), TGZ_NAME)
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
    return tgz


def main() -> int:
    bundle_first = "--no-bundle" not in sys.argv
    tgz = os.path.join(tempfile.gettempdir(), TGZ_NAME)
    if bundle_first:
        print("[bundle] writing", tgz, flush=True)
        tgz = _bundle()
    elif not os.path.isfile(tgz):
        print(f"Missing {tgz}", file=sys.stderr)
        return 1

    print(f"[scp] {tgz} -> {HOST}:{REMOTE_TGZ}", flush=True)
    subprocess.run(
        ["scp", "-o", "BatchMode=yes", "-o", "StrictHostKeyChecking=accept-new", tgz, f"root@{HOST}:{REMOTE_TGZ}"],
        check=True,
    )
    remote = f"""set -euo pipefail
mkdir -p {APP_DIR}
tar -xzf {REMOTE_TGZ} -C {APP_DIR}
cd {APP_DIR}/server && npm install --production
cd {APP_DIR} && pm2 restart ai-face-swap-test --update-env
sleep 3
curl -s -o /dev/null -w "templates_http:%{{http_code}}\\n" http://127.0.0.1:8082/api/templates
echo test_deploy_ok
"""
    r = subprocess.run(
        ["ssh", "-o", "BatchMode=yes", f"root@{HOST}", remote],
        capture_output=False,
        text=True,
    )
    if r.returncode == 0:
        print("[done] 测试服代码与当前仓库打包一致。", flush=True)
    return r.returncode


if __name__ == "__main__":
    raise SystemExit(main())
