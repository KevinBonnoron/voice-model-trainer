#!/bin/sh

# Script for audio data preprocessing

show_help_preprocess() {
  cat <<EOF
Usage: $0 preprocess [options]

Options:
  -i, --input PATH                  Path to input data
  -o, --output PATH                 Path to save preprocessed data
  -l, --language LANGUAGE           Set the preprocess language [default: en-us]
  -s, --sample-rate SAMPLE_RATE     Set the preprocess sample rate [default: 22050]
  -m, --single-speaker VALUE        Set the single speaker mode [default: true]
  -d, --dataset-format FORMAT       Set the dataset format values (ljspeech, mycroft) [default: ljspeech]
  -w, --max-workers MAX_WORKERS     Set the number of workers to use for preprocessing [default: 1]
  -a, --audio-quality AUDIO_QUALITY Set the audio quality (high, medium, low, x_low) [default: medium]
  -h, --help                        Show this help message
EOF
}

run_preprocess() {
  INPUT=
  OUTPUT=
  LANGUAGE="en-us"
  SAMPLE_RATE=22050
  SINGLE_SPEAKER=true
  DATASET_FORMAT=ljspeech
  MAX_WORKERS=1
  AUDIO_QUALITY=medium

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
    -m | --single-speaker)
      if [ "$#" -gt 1 ]; then
        SINGLE_SPEAKER=$2
        shift 2
      else
        echo "Error: Missing argument for $1"
        exit 1
      fi
      ;;
    -d | --dataset-format)
      if [ "$#" -gt 1 ]; then
        DATASET_FORMAT=$2
        case "$DATASET_FORMAT" in
        ljspeech | mycroft) ;;
        *)
          echo "Error: Invalid dataset format '$DATASET_FORMAT'. Allowed values are: ljspeech, mycroft" >&2
          exit 1
          ;;
        esac
        shift 2
      else
        echo "Error: Missing argument for $1"
        exit 1
      fi
      ;;
    -w | --max-workers)
      if [ "$#" -gt 1 ]; then
        MAX_WORKERS=$2
        shift 2
      else
        echo "Error: Missing argument for $1"
        exit 1
      fi
      ;;
    -a | --audio-quality)
      if [ "$#" -gt 1 ]; then
        AUDIO_QUALITY=$2
        case "$AUDIO_QUALITY" in
        high | medium | low | x_low) ;;
        *)
          echo "Error: Invalid audio quality '$AUDIO_QUALITY'. Allowed values are: high, medium, low, x_low" >&2
          exit 1
          ;;
        esac
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
    voice-model-trainer python -u /workspace/preprocess.py $INPUT $OUTPUT $LANGUAGE $SAMPLE_RATE $SINGLE_SPEAKER $DATASET_FORMAT $MAX_WORKERS $AUDIO_QUALITY
}

# If script is executed directly
if [ "${0##*/}" = "preprocess.sh" ]; then
  run_preprocess "$@"
fi
