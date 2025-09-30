#!/usr/bin/env bash
set -euo pipefail

# Start a Kali container interactively with a name and port mapping.

NAME=${NAME:-kali-promptfoo-int}
PORT=${PORT:-3000}

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is required" >&2
  exit 1
fi

if docker ps -a --format '{{.Names}}' | grep -Fx "$NAME" >/dev/null 2>&1; then
  echo "Container $NAME already exists. Starting and attaching..."
  docker start "$NAME" | cat
  echo "Ensure port mapping: host $PORT -> container 3000"
  echo "Attach with: docker exec -it $NAME bash"
  exit 0
fi

docker run -it --name "$NAME" -p "$PORT:3000" kalilinux/kali-rolling bash


