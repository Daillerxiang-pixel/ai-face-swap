#!/usr/bin/env python3
"""将本机仓库 server/.env 同步到正式机（覆盖远程 server/.env），并 pm2 restart。用于腾讯云/OSS 等与测试机一致的密钥。"""
import os
import sys

try:
    import paramiko
except ImportError:
    sys.exit("pip install paramiko")

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LOCAL_ENV = os.path.join(ROOT, "server", ".env")
REMOTE = "/var/www/ai-face-swap/server/.env"
CRED = r"F:\work\server-deploy\ai-face-swap\credentials.local.env"
HOST = "159.223.152.94"


def pw():
    if os.path.isfile(CRED):
        with open(CRED, encoding="utf-8") as f:
            for line in f:
                if line.strip().startswith("DEPLOY_SSH_PASSWORD="):
                    return line.split("=", 1)[1].strip().strip('"').strip("'")
    return os.environ.get("DEPLOY_SSH_PASSWORD")


def main():
    if not os.path.isfile(LOCAL_ENV):
        print("Missing", LOCAL_ENV, file=sys.stderr)
        return 1
    p = pw()
    if not p:
        print("Need credentials", file=sys.stderr)
        return 1
    c = paramiko.SSHClient()
    c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    c.connect(HOST, username="root", password=p, timeout=90, allow_agent=False, look_for_keys=False)
    sftp = c.open_sftp()
    sftp.put(LOCAL_ENV, REMOTE)
    sftp.close()
    c.exec_command("cd /var/www/ai-face-swap && pm2 restart ai-face-swap --update-env")
    print("[ok] server/.env synced to prod, pm2 restart triggered")
    c.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
