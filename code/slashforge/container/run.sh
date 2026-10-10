#!/usr/bin/env bash
# SlashForge course: build the check image and run check.sh in it, with no network, no host mount, no Docker
# socket, no capabilities and bounded resources. Works with Docker (Docker Desktop, or Docker Engine inside a WSL
# distribution) or Podman:
#
#   bash container/run.sh                  # docker
#   ENGINE=podman bash container/run.sh
#   ENGINE=podman bash container/run.sh clean   # removes the one image this script builds, nothing else
set -euo pipefail
cd "$(dirname "$0")/.."
ENGINE=${ENGINE:-docker}
IMAGE=localhost/learn-slashforge-check:4.4.3

if [ "${1:-}" = clean ]; then
  "$ENGINE" image rm "$IMAGE"
  exit 0
fi

"$ENGINE" build -f container/Containerfile -t "$IMAGE" .
echo "image $IMAGE: $("$ENGINE" image inspect --format '{{.Size}}' "$IMAGE") bytes"

# --rm: the container is deleted when check.sh ends; its out/ goes with it.
# No -v and no --mount: nothing of the host is visible inside.
timeout 600 "$ENGINE" run --rm \
  --network=none \
  --cap-drop=ALL --security-opt=no-new-privileges \
  --cpus=1 --memory=512m --pids-limit=256 \
  --user node \
  "$IMAGE"
