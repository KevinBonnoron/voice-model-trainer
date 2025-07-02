#!/bin/sh

# Script for model training

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
        exit 1
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
    voice-model-trainer python -u /workspace/train.py $DATASET_DIR $ACCELERATOR $DEVICES $VALIDATION_SPLIT $BATCH_SIZE $MAX_EPOCHS $PRECISION $QUALITY $RESUME_FROM_CHECKPOINT
}

# If script is executed directly
if [ "${0##*/}" = "train.sh" ]; then
  run_train "$@"
fi
