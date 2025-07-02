#!/bin/sh

normalize_command() {
  case "$1" in
  pre-process | pre-processing | preprocessing) echo "preprocess" ;;
  train | training) echo "train" ;;
  -h | --help | help | "") echo "help" ;;
  *) echo "$1" ;;
  esac
}

show_help_general() {
  cat <<EOF
Usage: $0 <command> [options]

Commands (aliases allowed):
  preprocess                Run preprocessing (aliases: pre-process, pre-processing, preprocessing)
  train                     Train the model (aliases: training)
  generate                  Generate audio from checkpoint and sentences file
  export                    Export onnx file

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
preprocess)
  . "./src/preprocess.sh"
  run_preprocess "$@"
  ;;
train)
  . "./src/train.sh"
  run_train "$@"
  ;;
generate)
  . "./src/generate.sh"
  run_generate "$@"
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
