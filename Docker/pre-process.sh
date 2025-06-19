#!/bin/sh

# -----------------------------------------------------------------------------
# Script Name: pre-process.sh
#
# Description:
#   Launches the preprocessing step for training a voice model using piper_train.
#
# Usage:
#   ./pre-process.sh <input> <output> <language> <sample_rate> <multiple_speaker> <format>
#
# Arguments:
#   <input>              Path to the raw dataset directory containing source audio and transcripts
#   <output>             Path where the preprocessed dataset will be saved
#   <language>           Language code (e.g., en-us, fr-fr)
#   <sample_rate>        Audio sample rate in Hz (e.g., 22050, 44100)
#   <multiple_speaker>   Set multiple speaker mode
#   <format>             Set the dataset format
#
# Example:
#   ./pre-process.sh en-us 22050
#
# Notes:
#   - Expects input data to be in /workspace/input
#   - Preprocessed output will be written to /workspace/output
#   - Must be run inside the appropriate Docker container or environment
# -----------------------------------------------------------------------------

INPUT=$1
OUTPUT=$2
LANGUAGE=$3
SAMPLE_RATE=$4
MULTIPLE_SPEAKER=$5
DATASET_FORMAT=$6

cat <<EOF
Running preprocessing with arguments:
- input:           $INPUT
- output:          $OUTPUT
- language:        $LANGUAGE
- sample-rate:     $SAMPLE_RATE
- multiple-speaker $MULTIPLE_SPEAKER
- dataset-format   $DATASET_FORMAT
EOF

# Main
cd piper/src/python
python3 -m piper_train.preprocess \
  --language $LANGUAGE \
  --input-dir /workspace/input \
  --output-dir /workspace/output \
  --dataset-format $DATASET_FORMAT \
  --single-speaker \
  --sample-rate $SAMPLE_RATE
