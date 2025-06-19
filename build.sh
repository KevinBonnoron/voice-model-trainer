#!/bin/sh

echo "Building image..."
cd Docker
docker build -t voice-model-trainer .
