#!/bin/sh

# -----------------------------------------------------------------------------
# Script Name: export.sh
#
# Description:
#   Entry point for exporting data
#
# Usage:
#   ./export.sh <output> <checkpoint_file> <format>
#
# Arguments:
#   <output>            Directory where generated audio files will be saved
#   <checkpoint_file>   Path to the model checkpoint file to use for generation
#   <format>            Format of the exported file
#
# Example:
#   ./export.sh ./output ./dataset/*.ckpt onnx
# -----------------------------------------------------------------------------

OUTPUT=$1
CHECKPOINT_FILE=$2
FORMAT=$3

cat <<EOF
Exporting with arguments:
- output:             $OUTPUT
- checkpoint-file:    $CHECKPOINT_FILE
- format:             $FORMAT
EOF

# Main
cd piper/src/python
python3 -m piper_train.export_onnx \
  /workspace/checkpoint_file.ckpt \
  /workspace/output/model.unoptimized.onnx
onnxsim "/workspace/output/model.unoptimized.onnx" "/workspace/output/model.onnx"
rm -f "/workspace/output/model.unoptimized.onnx"
