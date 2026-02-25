#!/bin/sh

# Script for model export
if ! type to_abs_path >/dev/null 2>&1; then
  _u="$(dirname "$0")/utils.sh"
  if [ -f "$_u" ]; then . "$_u"; elif [ -f "./utils.sh" ]; then . "./utils.sh"; elif [ -f "./src/utils.sh" ]; then . "./src/utils.sh"; fi
  unset _u
fi

DEFAULT_SAMPLE_TEXT="Hello, this is a sample from your voice model."

show_help_export() {
  cat <<EOF
Usage: $0 export [options]

Options:
  -o, --output PATH           Path to save exported data
  -c, --checkpoint-file       Path to the checkpoint file (auto-detects latest from output if omitted)
  -f, --format FORMAT         Export format: onnx, generator, sample [default: onnx]
  -t, --sample-text TEXT      For format sample: text for sample.wav (default sentence if omitted)
  -e, --espeak-voice VOICE   For format sample: espeak voice for config (default: en-us)
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
  SAMPLE_TEXT=
  ESPEAK_VOICE=en-us

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
        onnx | generator | sample) ;;
        *)
          echo "Error: Invalid format '$FORMAT'. Allowed values are: onnx, generator, sample" >&2
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
    -t | --sample-text)
      if [ "$#" -gt 1 ]; then
        SAMPLE_TEXT="$2"
        shift 2
      else
        echo "Error: Missing argument for $1"
        exit 1
      fi
      ;;
    -e | --espeak-voice)
      if [ "$#" -gt 1 ]; then
        ESPEAK_VOICE="$2"
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

  # Auto-detect latest checkpoint if not specified
  if [ -z "$CHECKPOINT_FILE" ]; then
    CHECKPOINT_FILE=$(find "$OUTPUT/lightning_logs" -name "*.ckpt" -type f 2>/dev/null \
      | sort -t= -k2 -n -r \
      | head -1)
    if [ -z "$CHECKPOINT_FILE" ]; then
      echo "Error: no checkpoint found in '$OUTPUT/lightning_logs'. Use --checkpoint-file to specify one." >&2
      exit 1
    fi
    echo "Auto-detected checkpoint: $CHECKPOINT_FILE"
  elif [ ! -f "$CHECKPOINT_FILE" ]; then
    echo "Error: checkpoint-file path '$CHECKPOINT_FILE' does not exist" >&2
    exit 1
  fi

  OUTPUT=$(to_abs_path "$OUTPUT")
  CHECKPOINT_FILE=$(to_abs_path "$CHECKPOINT_FILE")

  if [ "$FORMAT" = "sample" ] && [ -z "$SAMPLE_TEXT" ]; then
    SAMPLE_TEXT="$DEFAULT_SAMPLE_TEXT"
  fi

  # Pull once upfront, then run containers without pulling again
  if [ "${VOICE_TRAINER_PULL:-always}" != "never" ]; then
    docker pull "$IMAGE_NAME" || true
  fi

  case "$FORMAT" in
  onnx)
    docker run \
      --rm \
      --mount type=bind,src="$OUTPUT",dst=/workspace/output \
      --mount type=bind,src="$CHECKPOINT_FILE",dst=/workspace/checkpoint.ckpt,ro \
      --gpus all \
      $IMAGE_NAME \
      python -u -m piper.train.export_onnx \
        --checkpoint /workspace/checkpoint.ckpt \
        --output-file /workspace/output/model.onnx
    ;;
  sample)
    docker run \
      --rm \
      --mount type=bind,src="$OUTPUT",dst=/workspace/output \
      --mount type=bind,src="$CHECKPOINT_FILE",dst=/workspace/checkpoint.ckpt,ro \
      --gpus all \
      $IMAGE_NAME \
      python -u -m piper.train.export_onnx \
        --checkpoint /workspace/checkpoint.ckpt \
        --output-file /workspace/output/model.onnx
    docker run \
      --rm \
      --mount type=bind,src="$OUTPUT",dst=/workspace/output \
      --mount type=bind,src="$CHECKPOINT_FILE",dst=/workspace/checkpoint.ckpt,ro \
      $IMAGE_NAME \
      python -u /workspace/scripts/write_onnx_config.py \
        --checkpoint /workspace/checkpoint.ckpt \
        --output-dir /workspace/output \
        --espeak-voice "$ESPEAK_VOICE"
    docker run \
      --rm \
      --mount type=bind,src="$OUTPUT",dst=/workspace/output \
      $IMAGE_NAME \
      python -u -m piper -m /workspace/output/model.onnx -f /workspace/output/sample.wav -- "$SAMPLE_TEXT"
    ;;
  generator)
    docker run \
      --rm \
      --mount type=bind,src="$OUTPUT",dst=/workspace/output \
      --mount type=bind,src="$CHECKPOINT_FILE",dst=/workspace/checkpoint.ckpt,ro \
      --gpus all \
      $IMAGE_NAME \
      python -u -m piper.train.export_generator \
        --checkpoint /workspace/checkpoint.ckpt \
        --generator /workspace/output/model.generator.pt
    ;;
  esac
}

# If script is executed directly
if [ "${0##*/}" = "export.sh" ]; then
  run_export "$@"
fi
