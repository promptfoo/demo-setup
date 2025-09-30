#!/usr/bin/env bash
set -euo pipefail

# Copy only the DB and inside-setup.sh into a running container.
# Does NOT execute the setup inside the container.

NAME=${NAME:-kali-promptfoo-int}
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DB_SOURCE="$SCRIPT_DIR/promptfoo.db"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is required" >&2
  exit 1
fi

if [[ ! -e "$DB_SOURCE" ]]; then
  echo "DB file not found next to this script: $DB_SOURCE" >&2
  echo "Place your promptfoo.db in: $SCRIPT_DIR" >&2
  exit 1
fi

if ! docker ps --format '{{.Names}}' | grep -Fx "$NAME" >/dev/null 2>&1; then
  echo "Container $NAME is not running. Start it first (start-interactive.sh)." >&2
  exit 1
fi

TMP_DIR="/tmp/promptfoo"
docker exec "$NAME" bash -lc "mkdir -p '$TMP_DIR'" | cat
docker cp "$DB_SOURCE" "$NAME":"$TMP_DIR"/promptfoo.db
docker cp "$SCRIPT_DIR/inside-setup.sh" "$NAME":"$TMP_DIR"/inside-setup.sh

echo "Copied into container $NAME:"
echo "  $TMP_DIR/promptfoo.db"
echo "  $TMP_DIR/inside-setup.sh"


