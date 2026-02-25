#!/bin/sh

# Script for audio data augmentation using sox
if ! type to_abs_path >/dev/null 2>&1; then
  _u="$(dirname "$0")/utils.sh"
  if [ -f "$_u" ]; then . "$_u"; elif [ -f "./utils.sh" ]; then . "./utils.sh"; elif [ -f "./src/utils.sh" ]; then . "./src/utils.sh"; fi
  unset _u
fi

show_help_augment() {
  cat <<EOF
Usage: $0 augment [options]

Augments audio files with random transformations (pitch shift, tempo change,
noise, volume) to increase dataset size. Uses sox inside Docker.

If a metadata.csv exists in the input directory, an updated metadata.csv
is generated in the output directory with entries for all augmented files.

Options:
  -i, --input PATH                    Path to input audio data (required)
  -o, --output PATH                   Path to save augmented audio files (required)
  -n, --num-augmentations N           Number of augmented copies per file [default: 3]
  -h, --help                          Show this help message
EOF
}

run_augment() {
  INPUT=
  OUTPUT=
  NUM_AUGMENTATIONS=3

  if [ "$#" -eq 0 ]; then
    show_help_augment
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
    -n | --num-augmentations)
      if [ "$#" -gt 1 ]; then
        NUM_AUGMENTATIONS=$2
        shift 2
      else
        echo "Error: Missing argument for $1"
        exit 1
      fi
      ;;
    -h | --help)
      show_help_augment
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      show_help_augment
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

  docker run \
    --rm \
    $DOCKER_PULL \
    --mount type=bind,src="$INPUT",dst=/workspace/input,ro \
    --mount type=bind,src="$OUTPUT",dst=/workspace/output \
    $IMAGE_NAME \
    sh -c '
      NUM_AUG='"$NUM_AUGMENTATIONS"'
      INPUT_DIR=/workspace/input
      OUTPUT_DIR=/workspace/output

      # Collect metadata from source if present
      HAS_META=false
      if [ -f "$INPUT_DIR/metadata.csv" ]; then
        HAS_META=true
      fi

      wav_count=0
      for wav in "$INPUT_DIR"/*.wav; do
        [ -f "$wav" ] || continue
        wav_count=$((wav_count + 1))
      done

      if [ "$wav_count" -eq 0 ]; then
        echo "Error: no .wav files found in input" >&2
        exit 1
      fi

      echo "Augmenting $wav_count file(s) with $NUM_AUG augmentation(s) each"

      # Clear output metadata
      if $HAS_META; then
        > "$OUTPUT_DIR/metadata.csv"
      fi

      for wav in "$INPUT_DIR"/*.wav; do
        [ -f "$wav" ] || continue
        stem=$(basename "$wav" .wav)
        echo "Processing: $(basename "$wav")"

        i=1
        while [ "$i" -le "$NUM_AUG" ]; do
          out_name="${stem}_aug${i}.wav"

          # Random pitch shift: -200 to +200 cents
          pitch=$(awk "BEGIN{srand(); printf \"%.0f\", (rand()*400)-200}")
          # Random tempo: 0.9 to 1.1
          tempo=$(awk "BEGIN{srand(); printf \"%.2f\", 0.9+(rand()*0.2)}")
          # Random volume: -6dB to +6dB
          vol=$(awk "BEGIN{srand(); printf \"%.2f\", 0.5+(rand()*1.5)}")

          sox "$wav" "$OUTPUT_DIR/$out_name" \
            pitch "$pitch" \
            tempo "$tempo" \
            vol "$vol"

          echo "  $out_name (pitch=${pitch}c tempo=${tempo}x vol=${vol})"

          # Append to metadata if source had one
          if $HAS_META; then
            text=$(grep "^$(basename "$wav")|" "$INPUT_DIR/metadata.csv" | cut -d"|" -f2-)
            if [ -z "$text" ]; then
              text=$(grep "^${stem}|" "$INPUT_DIR/metadata.csv" | cut -d"|" -f2-)
            fi
            if [ -n "$text" ]; then
              echo "${out_name}|${text}" >> "$OUTPUT_DIR/metadata.csv"
            fi
          fi

          i=$((i + 1))
        done
      done

      total=$((wav_count * NUM_AUG))
      echo "Done: $total augmented file(s) created"
      if $HAS_META; then
        meta_count=$(wc -l < "$OUTPUT_DIR/metadata.csv")
        echo "Wrote metadata.csv ($meta_count entries)"
      fi
    '
}

# If script is executed directly
if [ "${0##*/}" = "augment.sh" ]; then
  run_augment "$@"
fi
