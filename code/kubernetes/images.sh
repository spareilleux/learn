#!/usr/bin/env bash
# Kubernetes course: builds the two APIs of the WSL containers course, pulls the helper images, and loads them all
# into the kind cluster learn-k8s. Lessons 2 to 4 use them with imagePullPolicy: Never.
# kind load docker-image fails when Docker uses the containerd image store ("ctr: content digest …: not found",
# kubernetes-sigs/kind#3795), so the images go through an archive of the node's platform instead.
set -euo pipefail
cd "$(dirname "$0")"
platform=${PLATFORM:-linux/amd64}
docker build -f ../wsl-containers/csharp-api/Containerfile -t csharp-api:1.0 ../wsl-containers/csharp-api
docker build -f ../wsl-containers/java-reactor-api/Containerfile -t java-reactor-api:1.0 ../wsl-containers/java-reactor-api
# Lesson 3's rolling update: the same build under a second tag
docker tag csharp-api:1.0 csharp-api:1.1
docker pull --platform "$platform" busybox:1.38.0
docker pull --platform "$platform" curlimages/curl:8.22.0
archive=$(mktemp -d)/learn-k8s-images.tar
docker save --platform "$platform" -o "$archive" csharp-api:1.0 csharp-api:1.1 java-reactor-api:1.0 busybox:1.38.0 curlimages/curl:8.22.0
kind load image-archive --name learn-k8s "$archive"
rm -f "$archive"
