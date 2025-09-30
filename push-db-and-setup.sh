#!/usr/bin/env bash
set -euo pipefail

# Host-side helper to copy a local DB and the inside setup script into a running
# container and then execute the inside setup to install promptfoo and start it.

NAME=${NAME:-kali-promptfoo-int}
PORT=${PORT:-3000}
DB_SOURCE="${1:-}"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is required" >&2
  exit 1
fi

if [[ -z "$DB_SOURCE" ]]; then
  # Default to user's ~/.promptfoo/promptfoo.db
  DB_SOURCE="$HOME/.promptfoo/promptfoo.db"
  echo "No DB path provided. Defaulting to: $DB_SOURCE"
fi

if [[ ! -e "$DB_SOURCE" ]]; then
  echo "DB file not found: $DB_SOURCE" >&2
  exit 1
fi

# Ensure container is running
if ! docker ps --format '{{.Names}}' | grep -Fx "$NAME" >/dev/null 2>&1; then
  echo "Container $NAME is not running. Start it first (start-interactive.sh)." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Prepare incoming dir in container
docker exec "$NAME" bash -lc 'mkdir -p /root/incoming' | cat

# Copy DB and inside script
docker cp "$DB_SOURCE" "$NAME":/root/incoming/promptfoo.db
docker cp "$SCRIPT_DIR/inside-setup.sh" "$NAME":/root/incoming/inside-setup.sh

# Run inside setup
docker exec -it "$NAME" bash -lc "chmod +x /root/incoming/inside-setup.sh && /root/incoming/inside-setup.sh --db /root/incoming/promptfoo.db --port $PORT --host 0.0.0.0" | cat

echo "promptfoo should now be starting at http://localhost:$PORT"


