#!/bin/sh

# Shared utilities for voice-model-trainer scripts.
# Source this from run.sh so all command scripts can use these functions.

# Docker image to use for all commands.
# Override with VOICE_TRAINER_IMAGE env var for local builds (e.g., VOICE_TRAINER_IMAGE=voice-model-trainer).
IMAGE_NAME="${VOICE_TRAINER_IMAGE:-ghcr.io/kevinbonnoron/voice-model-trainer}"

# Pull policy: always check registry for a newer image before running.
# Set VOICE_TRAINER_PULL=never to skip (useful for local/offline builds).
DOCKER_PULL="--pull ${VOICE_TRAINER_PULL:-always}"

# Converts a path to an absolute path (works for files and directories).
# Docker bind mounts require absolute paths; use this for any path passed to --mount.
to_abs_path() {
  path="$1"
  [ -z "$path" ] && return 0
  case "$path" in
    /*) echo "$path"; return ;;
  esac
  if [ -d "$path" ]; then
    (cd -P "$path" && pwd)
  else
    dir=$(dirname "$path")
    base=$(basename "$path")
    if [ "$dir" = "." ]; then
      echo "$(pwd)/$base"
    else
      echo "$(cd -P "$dir" && pwd)/$base"
    fi
  fi
}
