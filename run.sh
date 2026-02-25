#!/bin/sh

# Resolve repo root so utils work when run.sh is sourced (e.g. from tests) or run from any cwd
if [ -f "./src/utils.sh" ]; then
  . "./src/utils.sh"
else
  . "$(dirname "$0")/src/utils.sh"
fi

normalize_command() {
  case "$1" in
  train | training) echo "train" ;;
  -h | --help | help | "") echo "help" ;;
  *) echo "$1" ;;
  esac
}

show_help_general() {
  cat <<EOF
Usage: $0 <command> [options]

Commands (aliases allowed):
  augment                   Augment audio data with random transformations
  metadata                  Generate metadata.csv from audio files and transcriptions
  train                     Train a voice model (aliases: training)
  export                    Export a trained model to onnx or generator format

Use '$0 <command> --help' for more information on a command.
EOF
}

# Main
COMMAND=$(normalize_command "$1")

if [ "$#" -gt 0 ]; then
  shift
fi

case "$COMMAND" in
help)
  show_help_general
  ;;
augment)
  . "./src/augment.sh"
  run_augment "$@"
  ;;
metadata)
  . "./src/metadata.sh"
  run_metadata "$@"
  ;;
train)
  . "./src/train.sh"
  run_train "$@"
  ;;
export)
  . "./src/export.sh"
  run_export "$@"
  ;;
*)
  echo "Unknown command: $COMMAND"
  show_help_general
  exit 1
  ;;
esac
