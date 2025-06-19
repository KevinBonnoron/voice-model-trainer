#!/bin/sh

# -----------------------------------------------------------------------------
# Script Name: train.sh
#
# Description:
#   Launches training of a voice model using the piper_train module.
#
# Usage:
#   ./train.sh <dataset_dir> <accelerator> <devices> <validation_split> <batch_size> <max_epochs> <precision> <quality> [resume_from_checkpoint]
#
# Arguments:
#   <dataset_dir>             Path to preprocessed dataset (inside container: usually /workspace/output)
#   <accelerator>             Hardware backend: cpu | gpu
#   <devices>                 Number of devices to use (e.g., 1, 2, etc.)
#   <validation_split>        Fraction of training data used for validation (e.g., 0.0 or 0.1)
#   <batch_size>              Size of each training batch
#   <max_epochs>              Maximum number of epochs to train for
#   <precision>               Precision level: 16 | 32 | 64 | bf16 | mixed
#   [quality]                 Optional quality
#   [resume_from_checkpoint]  Optional path to a checkpoint file to resume training
#
# Example:
#   ./train.sh /workspace/output gpu 1 0.1 32 10000 32 /workspace/checkpoints/last.ckpt
#
# Notes:
#   - This script assumes it is run inside the Docker container.
#   - All paths must be accessible from within the container.
# -----------------------------------------------------------------------------

DATASET_DIR=${1}
ACCELERATOR=${2}
DEVICES=${3}
VALIDATION_SPLIT=${4}
BATCH_SIZE=${5}
MAX_EPOCHS=${6}
PRECISION=${7}
QUALITY=${8}
RESUME_FROM_CHECKPOINT=${9}

cat <<EOF
Running training with arguments:
- dataset-dir:            $DATASET_DIR
- accelerator:            $ACCELERATOR
- devices:                $DEVICES
- validation-split:       $VALIDATION_SPLIT
- batch-size:             $BATCH_SIZE
- max-epochs:             $MAX_EPOCHS
- precision:              $PRECISION
- quality:                $QUALITY
- resume-from-checkpoint: $RESUME_FROM_CHECKPOINT
EOF

CMD="python3 -m piper_train \
  --dataset-dir /workspace/output \
  --accelerator $ACCELERATOR \
  --devices $DEVICES \
  --batch-size $BATCH_SIZE \
  --validation-split $VALIDATION_SPLIT \
  --num-test-examples 0 \
  --max_epochs $MAX_EPOCHS \
  --log_every_n_steps 1 \
  --quality $QUALITY
  --precision $PRECISION"

if [ -n "$RESUME_FROM_CHECKPOINT" ]; then
  CMD="$CMD --resume_from_checkpoint /workspace/checkpoint.ckpt"
fi

# Main
cd piper/src/python
eval $CMD
