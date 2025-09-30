#!/usr/bin/env bash
set -euo pipefail

# This script is intended to be executed INSIDE the Kali container.
# It ensures Node.js/npm and the latest promptfoo, optionally
# preloads a SQLite DB, and starts `promptfoo view`.

PORT=3000
HOST_BIND="0.0.0.0"  # Ignored for current promptfoo; kept for compatibility
DB_PATH=""
USER_HOME="${HOME:-/root}"
PROMPTFOO_DIR="$USER_HOME/.promptfoo"
LOG_FILE="$USER_HOME/promptfoo-view.log"

usage() {
  echo "Usage: $0 [--db /path/to/promptfoo.db] [--port 3000] [--host 0.0.0.0]" >&2
  echo "Note: --host is ignored; promptfoo binds appropriately when port is exposed." >&2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--db)
      DB_PATH=${2:-}
      shift 2
      ;;
    -p|--port)
      PORT=${2:-3000}
      shift 2
      ;;
    --host)
      HOST_BIND=${2:-0.0.0.0}
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

# Ensure promptfoo runs with unblocking disabled in this session
export PROMPTFOO_DISABLE_UNBLOCKING=true

echo "[inside-setup] Ensuring Node.js and promptfoo are available..."
export DEBIAN_FRONTEND=noninteractive
SUDO=""
if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
fi

# Install Node.js 20 only if node is missing or too old
NEED_NODE_INSTALL=1
if command -v node >/dev/null 2>&1; then
  NODE_VER_RAW=$(node -v 2>/dev/null || echo "")
  NODE_MAJOR=$(echo "$NODE_VER_RAW" | sed -n 's/^v\([0-9]\+\).*/\1/p')
  if [ -n "$NODE_MAJOR" ] && [ "$NODE_MAJOR" -ge 18 ]; then
    NEED_NODE_INSTALL=0
  fi
fi

if [ "$NEED_NODE_INSTALL" -eq 1 ]; then
  $SUDO apt-get update
  $SUDO apt-get install -y curl ca-certificates gnupg
  if [ -n "$SUDO" ]; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  else
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  fi
  $SUDO apt-get install -y nodejs
fi

if ! command -v promptfoo >/dev/null 2>&1; then
  npm install -g promptfoo
fi

mkdir -p "$PROMPTFOO_DIR"

# Determine DB source if not explicitly provided
if [[ -z "$DB_PATH" ]]; then
  if [[ -f "./promptfoo.db" ]]; then
    DB_PATH="./promptfoo.db"
  elif [[ -f "/root/incoming/promptfoo.db" ]]; then
    DB_PATH="/root/incoming/promptfoo.db"
  elif [[ -f "/root/incoming/db.sqlite" ]]; then
    DB_PATH="/root/incoming/db.sqlite"
  elif [[ -f "/root/incoming/preloaded.db" ]]; then
    DB_PATH="/root/incoming/preloaded.db"
  fi
fi

if [[ -n "$DB_PATH" ]]; then
  if [[ ! -f "$DB_PATH" ]]; then
    echo "[inside-setup] Provided DB path does not exist: $DB_PATH" >&2
    exit 1
  fi
  echo "[inside-setup] Using DB: $DB_PATH"
  cp -f "$DB_PATH" "$PROMPTFOO_DIR/promptfoo.db"
fi

echo "[inside-setup] Starting promptfoo view on port ${PORT}..."
nohup promptfoo view -p "${PORT}" -y >"$LOG_FILE" 2>&1 &
sleep 1
echo "[inside-setup] promptfoo launched. Logs: $LOG_FILE"
echo "[inside-setup] Access from host at: http://localhost:${PORT} (ensure docker port mapping)"


