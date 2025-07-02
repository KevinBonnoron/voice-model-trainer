#!/bin/sh

# Script for model export

show_help_export() {
  cat <<EOF
Usage: $0 export [options]

Options:
  -o, --output PATH           Path to save exported data
  -c, --checkpoint-file       Path to the checkpoint file in ckpt format
  -f, --format FORMAT         Exported format (onnx, torchscript, generator) [default: onnx]
  -h, --help                  Show this help message
EOF
}

run_export() {
  if [ "$#" -eq 0 ]; then
    show_help_export
    exit 1
  fi

  OUTPUT=
  CHECKPOINT_FILE=
  FORMAT=onnx

  while [ "$#" -gt 0 ]; do
    case "$1" in
    -o | --output)
      if [ "$#" -gt 1 ]; then
        OUTPUT="$2"
        shift 2
      else
        echo "Error: Missing argument for $1"
        exit 1
      fi
      ;;
    -f | --format)
      if [ "$#" -gt 1 ]; then
        FORMAT="$2"
        case "$FORMAT" in
        onnx | torchscript | generator) ;;
        *)
          echo "Error: Invalid format '$FORMAT'. Allowed values are: onnx, torchscript, generator" >&2
          exit 1
        esac
        shift 2
      else
        echo "Error: Missing argument for $1"
        exit 1
      fi
      ;;
    -c | --checkpoint-file)
      if [ "$#" -gt 1 ]; then
        CHECKPOINT_FILE=$2
        shift 2
      else
        echo "Error: Missing argument for $1"
        exit 1
      fi
      ;;
    -h | --help)
      show_help_export
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      show_help_export
      exit 1
      ;;
    esac
  done

  if [ -z "$OUTPUT" ]; then
    echo "Error: output parameter is required" >&2
    exit 1
  elif [ ! -d "$OUTPUT" ]; then
    echo "Output directory '$OUTPUT' does not exist, creating it..."
    mkdir -p "$OUTPUT" || {
      echo "Error: failed to create output directory '$OUTPUT'" >&2
      exit 1
    }
  fi

  if [ -z "$CHECKPOINT_FILE" ]; then
    echo "Error: checkpoint-file parameter is required" >&2
    exit 1
  elif [ ! -f "$CHECKPOINT_FILE" ]; then
    echo "Error: checkpoint-file path '$CHECKPOINT_FILE' does not exist" >&2
    exit 1
  fi

  docker run \
    --rm \
    --mount type=bind,src=$OUTPUT,dst=/workspace/output \
    --mount type=bind,src=$CHECKPOINT_FILE,dst=/workspace/checkpoint_file.ckpt,ro \
    --gpus all \
    voice-model-trainer python -u /workspace/export.sh $OUTPUT $CHECKPOINT_FILE $FORMAT
}

# If script is executed directly
if [ "${0##*/}" = "export.sh" ]; then
  run_export "$@"
fi