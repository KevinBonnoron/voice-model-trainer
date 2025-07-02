#!/bin/sh

# Script for generating test sentences

show_help_generate() {
  cat <<EOF
Usage: $0 generate [options]

Options:
  -o, --output PATH           Path to save generated test data
  -s, --sentences-file FILE   Path to the sentences file in jsonl format
  -c, --checkpoint-file       Path to the checkpoint file in ckpt format
  -h, --help                  Show this help message
EOF
}

run_generate() {
  if [ "$#" -eq 0 ]; then
    show_help_generate
    exit 1
  fi

  OUTPUT=
  SENTENCES_FILE=
  CHECKPOINT_FILE=

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
    -s | --sentences-file)
      if [ "$#" -gt 1 ]; then
        SENTENCES_FILE="$2"
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
      show_help_generate_test_sentences
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      show_help_generate_test_sentences
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

  if [ -z "$SENTENCES_FILE" ]; then
    echo "Error: sentences-file parameter is required" >&2
    exit 1
  elif [ ! -f "$SENTENCES_FILE" ]; then
    echo "Error: sentences-file path '$SENTENCES_FILE' does not exist" >&2
    exit 1
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
    --mount type=bind,src=$SENTENCES_FILE,dst=/workspace/sentences_file.jsonl,ro \
    --mount type=bind,src=$CHECKPOINT_FILE,dst=/workspace/checkpoint_file.ckpt,ro \
    --gpus all \
    voice-model-trainer python -u /workspace/generate-test-sentences.sh $OUTPUT $SENTENCES_FILE $CHECKPOINT_FILE
}

# If script is executed directly
if [ "${0##*/}" = "generate-test-sentences.sh" ]; then
  run_generate "$@"
fi