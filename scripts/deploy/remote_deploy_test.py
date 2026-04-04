#!/usr/bin/env python3
"""
上传压缩包到测试服务器并执行 remote_install_test.sh（与 ibooks 同机安全：独立目录/端口/PM2/Nginx 站点）。

用法（PowerShell）:
  $env:DEPLOY_SSH_PASSWORD = '密码'
  $env:DEPLOY_HOST = '39.102.100.123'   # 可选，默认即测试机
  python scripts/deploy/remote_deploy_test.py

可选: DEPLOY_USER（默认 root）
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
REMOTE_TGZ = "/tmp/ai-face-swap-test-deploy.tgz"
APP_DIR = "/var/www/ai-face-swap-test"

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(os.path.dirname(SCRIPT_DIR))


def main() -> int:
    if not PASSWORD:
        print("请设置环境变量 DEPLOY_SSH_PASSWORD", file=sys.stderr)
        return 1

    if hasattr(sys.stdout, "reconfigure"):
        try:
            sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        except Exception:
            pass
    if hasattr(sys.stderr, "reconfigure"):
        try:
            sys.stderr.reconfigure(encoding="utf-8", errors="replace")
        except Exception:
            pass

    tgz = os.path.join(tempfile.gettempdir(), "ai-face-swap-test-deploy.tgz")
    print(f"[本地] 打包 -> {tgz}")
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

    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    print(f"[SSH] 连接 {USER}@{HOST}（测试机，勿与 ibooks 端口混淆：本实例 8082）...")
    try:
        client.connect(
            HOST,
            username=USER,
            password=PASSWORD,
            timeout=45,
            allow_agent=False,
            look_for_keys=False,
        )
    except Exception as e:
        print(f"[SSH] 连接失败: {e}", file=sys.stderr)
        return 1

    try:
        sftp = client.open_sftp()
        print(f"[SFTP] 上传 -> {REMOTE_TGZ}")
        sftp.put(tgz, REMOTE_TGZ)
        sftp.close()

        install = f"""set -euo pipefail
mkdir -p {APP_DIR}
tar -xzf {REMOTE_TGZ} -C {APP_DIR}
chmod +x {APP_DIR}/scripts/deploy/remote_install_test.sh
bash {APP_DIR}/scripts/deploy/remote_install_test.sh
"""
        print("[SSH] 执行 remote_install_test.sh ...")
        stdin, stdout, stderr = client.exec_command(install, get_pty=False)
        out = stdout.read().decode("utf-8", errors="replace")
        sys.stdout.write(out)
        err = stderr.read().decode("utf-8", errors="replace")
        if err:
            print(err, file=sys.stderr)
        code = stdout.channel.recv_exit_status()
        if code != 0:
            print(f"[SSH] 退出码: {code}", file=sys.stderr)
            return code
    finally:
        client.close()

    print("[完成] 浏览器访问: http://test1.kanashortplay.com/api/templates（DNS 生效且证书签发后为 HTTPS）")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
