#!/usr/bin/env bash
set -euo pipefail

# Copy only the DB and inside-setup.sh into a running container.
# Does NOT execute the setup inside the container.

NAME=${NAME:-kali-promptfoo-int}
DB_SOURCE=${1:-}

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is required" >&2
  exit 1
fi

if [[ -z "$DB_SOURCE" ]]; then
  DB_SOURCE="$HOME/.promptfoo/promptfoo.db"
  echo "No DB path provided. Defaulting to: $DB_SOURCE"
fi

if [[ ! -e "$DB_SOURCE" ]]; then
  echo "DB file not found: $DB_SOURCE" >&2
  exit 1
fi

if ! docker ps --format '{{.Names}}' | grep -Fx "$NAME" >/dev/null 2>&1; then
  echo "Container $NAME is not running. Start it first (start-interactive.sh)." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

docker exec "$NAME" bash -lc 'mkdir -p /root/incoming' | cat
docker cp "$DB_SOURCE" "$NAME":/root/incoming/promptfoo.db
docker cp "$SCRIPT_DIR/inside-setup.sh" "$NAME":/root/incoming/inside-setup.sh

echo "Copied into container $NAME:"
echo "  /root/incoming/promptfoo.db"
echo "  /root/incoming/inside-setup.sh"


