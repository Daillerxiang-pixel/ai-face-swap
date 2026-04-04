#!/usr/bin/env python3
"""
通过 SSH 上传压缩包并在服务器解压、执行 remote_install.sh。
用法（PowerShell）:
  $env:DEPLOY_SSH_PASSWORD = '你的密码'
  python scripts/deploy/remote_deploy.py

可选环境变量: DEPLOY_HOST, DEPLOY_USER（默认 root）
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

HOST = os.environ.get("DEPLOY_HOST", "159.223.152.94")
USER = os.environ.get("DEPLOY_USER", "root")
PASSWORD = os.environ.get("DEPLOY_SSH_PASSWORD")
REMOTE_TGZ = "/tmp/ai-face-swap-deploy.tgz"
APP_DIR = "/var/www/ai-face-swap"

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(os.path.dirname(SCRIPT_DIR))


def main() -> int:
    if not PASSWORD:
        print("请设置环境变量 DEPLOY_SSH_PASSWORD", file=sys.stderr)
        return 1

    # Windows 控制台默认 GBK，远程 UTF-8 日志会导致 UnicodeEncodeError
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

    tgz = os.path.join(tempfile.gettempdir(), "ai-face-swap-deploy.tgz")
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

    print(f"[SSH] 连接 {USER}@{HOST} ...")
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
chmod +x {APP_DIR}/scripts/deploy/remote_install.sh
bash {APP_DIR}/scripts/deploy/remote_install.sh
"""
        print("[SSH] 执行 remote_install.sh ...")
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

    print("[完成] 请用浏览器访问: http://test.kanashortplay.com/api/templates")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
