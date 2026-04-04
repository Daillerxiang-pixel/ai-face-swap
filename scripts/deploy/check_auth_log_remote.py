#!/usr/bin/env python3
"""SSH 到服务器，统计 Nginx 最近 N 分钟内 /api/auth/* 请求。"""
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
MINUTES = int(os.environ.get("LOG_MINUTES", "30"))


def build_script(minutes: int) -> str:
    return f"""import re
from datetime import datetime, timezone, timedelta
cutoff = datetime.now(timezone.utc) - timedelta(minutes={minutes})
path = "/var/log/nginx/ai-face-swap-access.log"
try:
    with open(path, errors="ignore") as f:
        lines = f.readlines()[-80000:]
except FileNotFoundError:
    print("LOG_MISSING", path)
    raise SystemExit(1)
rx = re.compile(r"\\[(\\d{{2}}/\\w{{3}}/\\d{{4}}:\\d{{2}}:\\d{{2}}:\\d{{2}}) ([+-]\\d{{4}})\\]")
auth_paths = ("/api/auth/login", "/api/auth/register", "/api/auth/apple")
hits = []
for line in lines:
    if not any(p in line for p in auth_paths):
        continue
    m = rx.search(line)
    if not m:
        continue
    try:
        ts = datetime.strptime(m.group(1) + " " + m.group(2), "%d/%b/%Y:%H:%M:%S %z")
    except ValueError:
        continue
    if ts >= cutoff:
        hits.append((ts, line.rstrip()))
hits.sort(key=lambda x: x[0])
print("WINDOW_UTC_LAST_MINUTES", {minutes})
print("AUTH_REQUEST_COUNT", len(hits))
for ts, line in hits[-120:]:
    print(ts.isoformat(), "|", line[:240])
"""


def main() -> int:
    if not PASSWORD:
        print("Set DEPLOY_SSH_PASSWORD", file=sys.stderr)
        return 1
    if hasattr(sys.stdout, "reconfigure"):
        try:
            sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        except Exception:
            pass
    c = paramiko.SSHClient()
    c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    c.connect(HOST, username=USER, password=PASSWORD, timeout=45, allow_agent=False, look_for_keys=False)
    try:
        stdin, out, err = c.exec_command("python3 -", get_pty=False)
        stdin.write(build_script(MINUTES))
        stdin.channel.shutdown_write()
        sys.stdout.write(out.read().decode("utf-8", errors="replace"))
        se = err.read().decode("utf-8", errors="replace")
        if se:
            sys.stderr.write(se)
        return out.channel.recv_exit_status()
    finally:
        c.close()


if __name__ == "__main__":
    raise SystemExit(main())
