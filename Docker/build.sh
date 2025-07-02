#!/bin/bash

set -e

# Configuration
IMAGE_NAME="voice-model-trainer"
TAG="${1:-latest}"
BUILD_CONTEXT="."
DOCKERFILE="Dockerfile"

PUID=$(id -u)
PGID=$(id -g)

if [ "$PUID" -eq 0 ]; then
  PUID=1000
  PGID=1000
fi

echo "🔨 Building Docker image..."

docker build \
  --build-arg UID="$PUID" \
  --build-arg GID="$PGID" \
  --tag "${IMAGE_NAME}:${TAG}" \
  --file "${DOCKERFILE}" \
  --progress=plain \
  "${BUILD_CONTEXT}"

echo "✅ Image built successfully: ${IMAGE_NAME}:${TAG}"
