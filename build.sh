#!/bin/bash

set -e

# Configuration
IMAGE_NAME="ghcr.io/kevinbonnoron/voice-model-trainer"
TAG="${1:-latest}"
BUILD_CONTEXT="."
DOCKERFILE="Docker/Dockerfile"

echo "Building Docker image..."

docker build \
  --tag "${IMAGE_NAME}:${TAG}" \
  --file "${DOCKERFILE}" \
  --progress=plain \
  "${BUILD_CONTEXT}"

echo "Image built successfully: ${IMAGE_NAME}:${TAG}"
