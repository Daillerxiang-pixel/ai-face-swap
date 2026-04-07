#!/usr/bin/env bash
# 部署后执行一次即可：把项目根目录的 .env 复制到 server/.env，避免只改了一处读不到。
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -f "$ROOT/.env" ]]; then
  cp -f "$ROOT/.env" "$ROOT/server/.env"
  chmod 600 "$ROOT/server/.env" 2>/dev/null || true
  echo "OK: synced $ROOT/.env -> $ROOT/server/.env"
else
  echo "Skip: no $ROOT/.env"
  exit 0
fi
