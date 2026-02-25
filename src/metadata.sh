#!/bin/sh

# Script for generating metadata.csv with automatic Whisper transcription
if ! type to_abs_path >/dev/null 2>&1; then
  _u="$(dirname "$0")/utils.sh"
  if [ -f "$_u" ]; then . "$_u"; elif [ -f "./utils.sh" ]; then . "./utils.sh"; elif [ -f "./src/utils.sh" ]; then . "./src/utils.sh"; fi
  unset _u
fi

show_help_metadata() {
  cat <<EOF
Usage: $0 metadata [options]

Generate a metadata.csv file for piper voice training from audio files.
Expects a wavs/ subdirectory inside the input directory containing .wav files.

If a metadata.csv already exists in the input directory, only missing
transcriptions are generated. If no metadata.csv exists, all .wav files
are transcribed using OpenAI's Whisper model (requires Docker).

Output format is pipe-delimited: filename.wav|transcription text

Options:
  -i, --input PATH              Path to dataset directory (must contain wavs/) (required)
  -o, --output PATH             Path to save generated metadata.csv (required)
  -m, --model MODEL             Whisper model: tiny, base, small, medium, large [default: small]
  -l, --language LANG           Language code (e.g., en, fr) [default: auto-detect]
  -d, --device DEVICE           Device for inference: cpu, cuda [default: cpu]
  -h, --help                    Show this help message
EOF
}

run_metadata() {
  INPUT=
  OUTPUT=
  MODEL=small
  LANGUAGE=
  DEVICE=cpu

  if [ "$#" -eq 0 ]; then
    show_help_metadata
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
    -m | --model)
      if [ "$#" -gt 1 ]; then
        MODEL="$2"
        case "$MODEL" in
        tiny | base | small | medium | large) ;;
        *)
          echo "Error: Invalid model '$MODEL'. Allowed values are: tiny, base, small, medium, large" >&2
          exit 1
          ;;
        esac
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
    -d | --device)
      if [ "$#" -gt 1 ]; then
        DEVICE="$2"
        case "$DEVICE" in
        cpu | cuda) ;;
        *)
          echo "Error: Invalid device '$DEVICE'. Allowed values are: cpu, cuda" >&2
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
      show_help_metadata
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      show_help_metadata
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

  INPUT=$(to_abs_path "$INPUT")
  OUTPUT=$(to_abs_path "$OUTPUT")

  # Verify wavs/ subdirectory exists
  if [ ! -d "$INPUT/wavs" ]; then
    echo "Error: '$INPUT/wavs' directory not found. Expected a wavs/ subdirectory with .wav files." >&2
    exit 1
  fi

  # Count available .wav files
  wav_count=0
  for wav in "$INPUT/wavs"/*.wav; do
    [ -f "$wav" ] || continue
    wav_count=$((wav_count + 1))
  done

  if [ "$wav_count" -eq 0 ]; then
    echo "Error: no .wav files found in '$INPUT/wavs'" >&2
    exit 1
  fi

  echo "Found $wav_count .wav file(s) in wavs/"

  # Collect existing transcriptions from metadata.csv (if present)
  existing_count=0
  EXISTING_ENTRIES=""
  TRANSCRIBED_FILES=""

  if [ -f "$INPUT/metadata.csv" ]; then
    echo "Found existing metadata.csv, checking for missing transcriptions..."
    while IFS='|' read -r filename rest; do
      [ -z "$filename" ] && continue
      [ -z "$rest" ] && continue
      existing_count=$((existing_count + 1))
      EXISTING_ENTRIES="${EXISTING_ENTRIES}${filename}|${rest}
"
      # Extract just the basename (handle both "wavs/001.wav" and "001.wav" formats)
      bare_name=$(basename "$filename")
      TRANSCRIBED_FILES="${TRANSCRIBED_FILES}${bare_name}
"
    done < "$INPUT/metadata.csv"
    echo "  $existing_count existing transcription(s)"
  fi

  # Find .wav files missing from metadata.csv
  MISSING_FILES=""
  missing_count=0
  for wav in "$INPUT/wavs"/*.wav; do
    [ -f "$wav" ] || continue
    bare_name=$(basename "$wav")
    if ! echo "$TRANSCRIBED_FILES" | grep -qx "$bare_name"; then
      MISSING_FILES="${MISSING_FILES}${bare_name} "
      missing_count=$((missing_count + 1))
    fi
  done

  # Write output metadata.csv
  OUTPUT_FILE="$OUTPUT/metadata.csv"

  if [ "$missing_count" -eq 0 ]; then
    echo "All .wav files already have transcriptions, nothing to transcribe."
    # Just copy existing entries to output
    printf "%s" "$EXISTING_ENTRIES" > "$OUTPUT_FILE"
    echo "Wrote $existing_count entries to $OUTPUT_FILE"
    return 0
  fi

  echo "$missing_count .wav file(s) need transcription, launching Whisper ($MODEL model)..."

  # Build Docker command for Whisper transcription
  GPU_ARG=""
  if [ "$DEVICE" = "cuda" ]; then
    GPU_ARG="--gpus all"
  fi

  LANG_ARG=""
  if [ -n "$LANGUAGE" ]; then
    LANG_ARG="--language $LANGUAGE"
  fi

  TEMP_TRANSCRIPTIONS="$OUTPUT/.new_transcriptions.csv"

  docker run \
    --rm \
    $DOCKER_PULL \
    --mount type=bind,src="$INPUT",dst=/workspace/input,ro \
    --mount type=bind,src="$OUTPUT",dst=/workspace/output \
    $GPU_ARG \
    $IMAGE_NAME \
    python -u /workspace/scripts/transcribe.py \
      --input-dir /workspace/input/wavs \
      --output-file /workspace/output/.new_transcriptions.csv \
      --model "$MODEL" \
      --device "$DEVICE" \
      $LANG_ARG \
      --files $MISSING_FILES

  if [ $? -ne 0 ]; then
    echo "Error: Whisper transcription failed" >&2
    rm -f "$TEMP_TRANSCRIPTIONS"
    exit 1
  fi

  # Merge existing entries + new transcriptions
  new_count=0
  if [ -f "$TEMP_TRANSCRIPTIONS" ]; then
    new_count=$(wc -l < "$TEMP_TRANSCRIPTIONS")
  fi

  # Write final metadata.csv: existing entries first, then new ones
  > "$OUTPUT_FILE"
  if [ -n "$EXISTING_ENTRIES" ]; then
    printf "%s" "$EXISTING_ENTRIES" >> "$OUTPUT_FILE"
  fi
  if [ -f "$TEMP_TRANSCRIPTIONS" ]; then
    cat "$TEMP_TRANSCRIPTIONS" >> "$OUTPUT_FILE"
  fi

  rm -f "$TEMP_TRANSCRIPTIONS"

  total=$((existing_count + new_count))
  echo "Done: $existing_count existing + $new_count transcribed = $total total entries"
  echo "Wrote $total entries to $OUTPUT_FILE"
}

# If script is executed directly
if [ "${0##*/}" = "metadata.sh" ]; then
  run_metadata "$@"
fi
