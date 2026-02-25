#!/bin/sh

# Script for model training
if ! type to_abs_path >/dev/null 2>&1; then
  _u="$(dirname "$0")/utils.sh"
  if [ -f "$_u" ]; then . "$_u"; elif [ -f "./utils.sh" ]; then . "./utils.sh"; elif [ -f "./src/utils.sh" ]; then . "./src/utils.sh"; fi
  unset _u
fi

show_help_train() {
  cat <<EOF
Usage: $0 train [options]

Options:
  -i, --input PATH                     Path to training data (contains metadata.csv, and wavs/ with .wav files) (required)
  -o, --output PATH                    Path to save training output (cache, config, checkpoints) (required)
  -n, --voice-name NAME                Name of the voice being trained (required)
      --audio-dir PATH                 Path to directory containing .wav files (default: <input>/wavs, LJSpeech layout)
  -e, --espeak-voice VOICE             Espeak voice for phonemization (e.g., en-us, fr-fr) [default: en-us]
  -s, --sample-rate RATE               Audio sample rate in Hz [default: 22050]
  -a, --accelerator ACCELERATOR        Hardware accelerator to use: cpu | gpu [default: gpu]
      --devices DEVICES                Number of devices to use (e.g., GPU count) [default: 1]
  -v, --validation-split SPLIT         Proportion of training data used for validation [default: 0.1]
  -b, --batch-size BATCH_SIZE          Number of samples per training batch [default: 32]
  -w, --num-workers N                  DataLoader workers for train/val [default: 0]
  -m, --max-epochs MAX_EPOCHS          Maximum number of training epochs [default: -1]
  -p, --precision PRECISION            Numerical precision: 16 | 32 | 64 | bf16 | mixed [default: 32]
      --log-every-n-steps N            Log metrics every N training steps [default: 10]
  -r, --resume-from-checkpoint FILE    Path to a checkpoint file to resume training from
  -h, --help                           Show this help message and exit
EOF
}

run_train() {
  INPUT=
  OUTPUT=
  VOICE_NAME=
  ESPEAK_VOICE="en-us"
  SAMPLE_RATE=22050
  ACCELERATOR=gpu
  DEVICES=1
  VALIDATION_SPLIT=0.1
  BATCH_SIZE=32
  NUM_WORKERS=0
  MAX_EPOCHS=-1
  PRECISION=32
  LOG_EVERY_N_STEPS=10
  RESUME_FROM_CHECKPOINT=
  AUDIO_DIR=

  if [ "$#" -eq 0 ]; then
    show_help_train
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
    -n | --voice-name)
      if [ "$#" -gt 1 ]; then
        VOICE_NAME="$2"
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
    -s | --sample-rate)
      if [ "$#" -gt 1 ]; then
        SAMPLE_RATE=$2
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
    -w | --num-workers)
      if [ "$#" -gt 1 ]; then
        NUM_WORKERS=$2
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
    --log-every-n-steps)
      if [ "$#" -gt 1 ]; then
        LOG_EVERY_N_STEPS=$2
        shift 2
      else
        echo "Error: Missing argument for $1"
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
    --audio-dir)
      if [ "$#" -gt 1 ]; then
        AUDIO_DIR="$2"
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

  if [ -z "$VOICE_NAME" ]; then
    echo "Error: voice-name parameter is required" >&2
    exit 1
  fi

  if [ -z "$AUDIO_DIR" ]; then
    AUDIO_DIR="$INPUT/wavs"
  elif [ ! -d "$AUDIO_DIR" ]; then
    echo "Error: audio-dir path '$AUDIO_DIR' does not exist" >&2
    exit 1
  fi

  INPUT=$(to_abs_path "$INPUT")
  OUTPUT=$(to_abs_path "$OUTPUT")
  [ -n "$RESUME_FROM_CHECKPOINT" ] && RESUME_FROM_CHECKPOINT=$(to_abs_path "$RESUME_FROM_CHECKPOINT")
  AUDIO_DIR=$(to_abs_path "$AUDIO_DIR")

  GPU_ARG=""
  if [ "$ACCELERATOR" = "gpu" ]; then
    GPU_ARG="--gpus all"
  fi

  CKPT_ARG=""
  CKPT_MOUNT="--mount type=bind,src=/dev/null,dst=/workspace/checkpoint.ckpt,ro"
  if [ -n "$RESUME_FROM_CHECKPOINT" ]; then
    if [ ! -f "$RESUME_FROM_CHECKPOINT" ]; then
      echo "Error: checkpoint file '$RESUME_FROM_CHECKPOINT' does not exist" >&2
      exit 1
    fi
    CKPT_MOUNT="--mount type=bind,src=$RESUME_FROM_CHECKPOINT,dst=/workspace/checkpoint.ckpt,ro"
    CKPT_ARG="--ckpt_path /workspace/checkpoint.ckpt"
  fi

  AUDIO_MOUNT=""
  AUDIO_DIR_ARG="/workspace/input/wavs"
  if [ "$AUDIO_DIR" = "$INPUT/wavs" ]; then
    AUDIO_DIR_ARG="/workspace/input/wavs"
  else
    AUDIO_MOUNT="--mount type=bind,src=$AUDIO_DIR,dst=/workspace/audio,ro"
    AUDIO_DIR_ARG="/workspace/audio"
  fi

  echo "Running training with arguments:"
  echo "  input:                 $INPUT"
  echo "  output:                $OUTPUT"
  echo "  voice-name:            $VOICE_NAME"
  echo "  audio-dir:             $AUDIO_DIR"
  echo "  espeak-voice:          $ESPEAK_VOICE"
  echo "  sample-rate:           $SAMPLE_RATE"
  echo "  accelerator:           $ACCELERATOR"
  echo "  devices:               $DEVICES"
  echo "  validation-split:      $VALIDATION_SPLIT"
  echo "  batch-size:            $BATCH_SIZE"
  echo "  num-workers:           $NUM_WORKERS"
  echo "  max-epochs:            $MAX_EPOCHS"
  echo "  precision:             $PRECISION"
  echo "  log-every-n-steps:     $LOG_EVERY_N_STEPS"
  if [ -n "$RESUME_FROM_CHECKPOINT" ]; then
    echo "  resume-from-checkpoint: $RESUME_FROM_CHECKPOINT"
  else
    echo "  resume-from-checkpoint: (none)"
  fi

  docker run \
    --rm -t --init \
    $DOCKER_PULL \
    --mount type=bind,src="$INPUT",dst=/workspace/input,ro \
    --mount type=bind,src="$OUTPUT",dst=/workspace/output \
    $AUDIO_MOUNT \
    $CKPT_MOUNT \
    --shm-size=1g \
    $GPU_ARG \
    -e PYTHONWARNINGS="ignore:does not have many workers:UserWarning" \
    $IMAGE_NAME \
    python -u /workspace/scripts/run_train.py fit \
      --data.csv_path /workspace/input/metadata.csv \
      --data.audio_dir "$AUDIO_DIR_ARG" \
      --data.cache_dir /workspace/output/cache \
      --data.config_path /workspace/output/config.json \
      --data.voice_name "$VOICE_NAME" \
      --data.espeak_voice "$ESPEAK_VOICE" \
      --model.sample_rate "$SAMPLE_RATE" \
      --data.batch_size "$BATCH_SIZE" \
      --data.num_workers "$NUM_WORKERS" \
      --data.validation_split "$VALIDATION_SPLIT" \
      --trainer.accelerator "$ACCELERATOR" \
      --trainer.devices "$DEVICES" \
      --trainer.max_epochs "$MAX_EPOCHS" \
      --trainer.precision "$PRECISION" \
      --trainer.log_every_n_steps "$LOG_EVERY_N_STEPS" \
      --trainer.default_root_dir /workspace/output \
      $CKPT_ARG
}

# If script is executed directly
if [ "${0##*/}" = "train.sh" ]; then
  run_train "$@"
fi
