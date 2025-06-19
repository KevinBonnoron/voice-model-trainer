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
  generate-test-sentences   Generate test audio from checkpoint
  export                    Export onnx file

Use '$0 <command> --help' for more information on a command.
EOF
}

show_help_preprocess() {
  cat <<EOF
Usage: $0 preprocess [options]

Options:
  -i, --input PATH                 Path to input data
  -o, --output PATH                Path to save preprocessed data
  -l, --language LANGUAGE          Set the preprocess language [default: en-us]
  -s, --sample-rate SAMPLE_RATE    Set the preprocess sample rate [default: 22050]
  -m, --multiple-speaker VALUE     Set the multiple speaker mode [default: false]
  -f, --format FORMAT              Set the dataset format [default: ljspeech]
  -h, --help                       Show this help message
EOF
}

show_help_train() {
  cat <<EOF
Usage: $0 train [options]

Options:
  -d, --dataset-dir PATH                     Path to the dataset directory (required)
  -a, --accelerator ACCELERATOR              Hardware accelerator to use: cpu | gpu [default: gpu]
      --devices DEVICES                      Number of devices to use (e.g., GPU count) [default: 1]
  -v, --validation-split VALIDATION_SPLIT    Proportion of training data used for validation [default: 0.0]
  -b, --batch-size BATCH_SIZE                Number of samples per training batch [default: 32]
  -m, --max-epochs MAX_EPOCHS                Maximum number of training epochs [default: 10000]
  -p, --precision PRECISION                  Numerical precision: 16 | 32 | 64 | bf16 | mixed [default: 32]
  -q, --quality QUALITY                      Quality/size of the model [default: medium]
  -r, --resume-from-checkpoint FILE          Path to a checkpoint file to resume training from
  -h, --help                                 Show this help message and exit
EOF
}

show_help_generate_test_sentences() {
  cat <<EOF
Usage: $0 generate-test-sentences [options]

Options:
  -o, --output PATH           Path to save generated test data
  -s, --sentences-file FILE   Path to the sentences file in jsonl format
  -c, --checkpoint-file       Path to the checkpoint file in ckpt format
  -h, --help                  Show this help message
EOF
}

show_help_export() {
  cat <<EOF
Usage: $0 export [options]

Options:
  -o, --output PATH           Path to save exported data
  -c, --checkpoint-file       Path to the checkpoint file in ckpt format
  -f, --format FORMAT         Exported format: onnx [default: onnx]
  -h, --help                  Show this help message
EOF
}

run_preprocess() {
  INPUT=
  OUTPUT=
  LANGUAGE="en-us"
  SAMPLE_RATE=22050
  MULTIPLE_SPEAKER=false
  FORMAT=ljspeech

  if [ "$#" -eq 0 ]; then
    show_help_preprocess
    exit 1
  fi

  while [ "$#" -gt 0 ]; do
    case "$1" in
    -i | --input)
      if [ "$#" -gt 1 ]; then
        INPUT="$2"
        shift 2
      else
        echo "Error: Missing argument for $1"
        exit 1
      fi
      ;;
    -o | --output)
      if [ "$#" -gt 1 ]; then
        OUTPUT="$2"
        shift 2
      else
        echo "Error: Missing argument for $1"
        exit 1
      fi
      ;;
    -l | --language)
      if [ "$#" -gt 1 ]; then
        LANGUAGE="$2"
        shift 2
      else
        echo "Error: Missing argument for $1"
        exit
      fi
      ;;
    -s | --sample-rate)
      if [ "$#" -gt 1 ]; then
        SAMPLE_RATE=$2
        shift 2
      else
        echo "Error: Missing argument for $1"
        exit 1
      fi
      ;;
    -m | --multiple-speaker)
      if [ "$#" -gt 1 ]; then
        MULTIPLE_SPEAKER=$2
        shift 2
      else
        echo "Error: Missing argument for $1"
        exit 1
      fi
      ;;
    -f | --format)
      if [ "$#" -gt 1 ]; then
        FORMAT=$2
        shift 2
      else
        echo "Error: Missing argument for $1"
        exit 1
      fi
      ;;
    -h | --help)
      show_help_preprocess
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      show_help_preprocess
      exit 1
      ;;
    esac
  done

  if [ -z "$INPUT" ]; then
    echo "Error: input parameter is required" >&2
    exit 1
  elif [ ! -d "$INPUT" ]; then
    echo "Error: input path '$INPUT' does not exist" >&2
    exit 1
  fi

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

  docker run \
    --rm \
    --mount type=bind,src=$INPUT,dst=/workspace/input,ro \
    --mount type=bind,src=$OUTPUT,dst=/workspace/output \
    --gpus all \
    voice-model-trainer /workspace/pre-process.sh $INPUT $OUTPUT $LANGUAGE $SAMPLE_RATE $MULTIPLE_SPEAKER $FORMAT
}

run_train() {
  DATASET_DIR=
  ACCELERATOR=gpu
  DEVICES=1
  VALIDATION_SPLIT=0.0
  BATCH_SIZE=32
  MAX_EPOCHS=10000
  PRECISION=32
  QUALITY=medium
  RESUME_FROM_CHECKPOINT=

  if [ "$#" -eq 0 ]; then
    show_help_train
    exit 1
  fi

  while [ "$#" -gt 0 ]; do
    case "$1" in
    -d | --dataset-dir)
      if [ "$#" -gt 1 ]; then
        DATASET_DIR="$2"
        shift 2
      else
        echo "Error: Missing argument for $1"
        exit 1
      fi
      ;;
    -a | --accelerator)
      if [ "$#" -gt 1 ]; then
        ACCELERATOR=$2
        case "$ACCELERATOR" in
        cpu | gpu) ;;
        *)
          echo "Error: Invalid accelerator '$ACCELERATOR'. Allowed values are: cpu, gpu" >&2
          exit 1
          ;;
        esac

        shift 2
      else
        echo "Error: Missing argument for $1"
        exit 1
      fi
      ;;
    --devices)
      if [ "$#" -gt 1 ]; then
        DEVICES="$2"
        shift 2
      else
        echo "Error: Missing argument for $1"
        exit
      fi
      ;;
    -v | --validation-split)
      if [ "$#" -gt 1 ]; then
        VALIDATION_SPLIT=$2
        shift 2
      else
        echo "Error: Missing argument for $1"
        exit 1
      fi
      ;;
    -b | --batch-size)
      if [ "$#" -gt 1 ]; then
        BATCH_SIZE=$2
        shift 2
      else
        echo "Error: Missing argument for $1"
        exit 1
      fi
      ;;
    -m | --max-epochs)
      if [ "$#" -gt 1 ]; then
        MAX_EPOCHS=$2
        shift 2
      else
        echo "Error: Missing argument for $1"
        exit 1
      fi
      ;;
    -p | --precision)
      if [ "$#" -gt 1 ]; then
        PRECISION=$2

        case "$PRECISION" in
        16 | 32 | 64 | bf16 | mixed) ;;
        *)
          echo "Error: Invalid precision '$PRECISION'. Allowed values are: 16, 32, 64, bf16, mixed" >&2
          exit 1
          ;;
        esac

        shift 2
      else
        echo "Error: Missing argument for $1" >&2
        exit 1
      fi
      ;;
    -q | --quality)
      if [ "$#" -gt 1 ]; then
        QUALITY=$2

        case "$QUALITY" in
        x-low | medium | high) ;;
        *)
          echo "Error: Invalid quality '$QUALITY'. Allowed values are: x-low, medium, high" >&2
          exit 1
          ;;
        esac

        shift 2
      else
        echo "Error: Missing argument for $1" >&2
        exit 1
      fi
      ;;
    -r | --resume-from-checkpoint)
      if [ "$#" -gt 1 ]; then
        RESUME_FROM_CHECKPOINT=$2
        shift 2
      else
        echo "Error: Missing argument for $1"
        exit 1
      fi
      ;;
    -h | --help)
      show_help_train
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      show_help_train
      exit 1
      ;;
    esac
  done

  if [ -z "$DATASET_DIR" ]; then
    echo "Error: dataset-dir parameter is required" >&2
    exit 1
  elif [ ! -d "$DATASET_DIR" ]; then
    echo "Error: dataset-dir path '$DATASET_DIR' does not exist" >&2
    exit 1
  fi

  docker run \
    --rm \
    --mount type=bind,src=$DATASET_DIR,dst=/workspace/output \
    --mount type=bind,src=${RESUME_FROM_CHECKPOINT:-/dev/null},dst=/workspace/checkpoint.ckpt,ro \
    --shm-size=1g \
    --gpus all \
    voice-model-trainer /workspace/train.sh $DATASET_DIR $ACCELERATOR $DEVICES $VALIDATION_SPLIT $BATCH_SIZE $MAX_EPOCHS $PRECISION $QUALITY $RESUME_FROM_CHECKPOINT
}

run_generate_test_sentences() {
  if [ "$#" -eq 0 ]; then
    show_help_generate_test_sentences
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
        exit
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
    voice-model-trainer /workspace/generate-test-sentences.sh $OUTPUT $SENTENCES_FILE $CHECKPOINT_FILE
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
        SENTENCES_FILE="$2"
        shift 2
      else
        echo "Error: Missing argument for $1"
        exit
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
    voice-model-trainer /workspace/export.sh $OUTPUT $CHECKPOINT_FILE $FORMAT
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
  run_preprocess "$@"
  ;;
train)
  run_train "$@"
  ;;
generate-test-sentences)
  run_generate_test_sentences "$@"
  ;;
export)
  run_export "$@"
  ;;
*)
  echo "Unknown command: $COMMAND"
  show_help_general
  exit 1
  ;;
esac
