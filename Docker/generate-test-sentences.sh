#!/bin/sh

# -----------------------------------------------------------------------------
# Script Name: generate-test-sentences.sh
#
# Description:
#   Entry point for generating test sentences
#
# Usage:
#   ./generate-test-sentences.sh <output> <sentences_file> <checkpoint_file>
#
# Arguments:
#   <output>            Directory where generated audio files will be saved
#   <sentences_file>    Path to the text file containing sentences to synthesize
#   <checkpoint_file>   Path to the model checkpoint file to use for generation
#
# Example:
#   ./generate-test-sentences.sh ./output ./piper/etc/test_sentences/test_en-us.jsonl ./dataset/*.ckpt
# -----------------------------------------------------------------------------

OUTPUT=$1
SENTENCES_FILE=$2
CHECKPOINT_FILE=$3

cat <<EOF
Generating test sentences with arguments:
- sentences-file:     $SENTENCES_FILE
- checkpoint-file:    $CHECKPOINT_FILE
EOF

# Main
cd piper/src/python
cat /workspace/sentences_file.jsonl |
  python3 -m piper_train.infer \
    --sample-rate 22050 \
    --checkpoint /workspace/checkpoint_file.ckpt \
    --output-dir /workspace/output
