#!/usr/bin/env python3

"""
Script Name: train.py

Description:
    Launches training of a voice model using the piper_train module.

Usage:
    python train.py <dataset_dir> <accelerator> <devices> <validation_split> <batch_size> <max_epochs> <precision> <quality> [resume_from_checkpoint]

Arguments:
    <dataset_dir>             Path to preprocessed dataset (inside container: usually /workspace/output)
    <accelerator>             Hardware backend: cpu | gpu
    <devices>                 Number of devices to use (e.g., 1, 2, etc.)
    <validation_split>        Fraction of training data used for validation (e.g., 0.0 or 0.1)
    <batch_size>              Size of each training batch
    <max_epochs>              Maximum number of epochs to train for
    <precision>               Precision level: 16 | 32 | 64 | bf16 | mixed
    <quality>                 Quality setting
    [resume_from_checkpoint]  Optional path to a checkpoint file to resume training

Example:
    python train.py /workspace/output gpu 1 0.1 32 10000 32 high /workspace/checkpoints/last.ckpt

Notes:
    - This script assumes it is run inside the Docker container.
    - All paths must be accessible from within the container.
"""

import argparse
import subprocess
import sys
import os


def main():
    """Main function to handle argument parsing and command execution."""
    
    # Set up argument parser
    parser = argparse.ArgumentParser(
        description="Launch training of a voice model using the piper_train module",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    
    # Required arguments
    parser.add_argument("dataset_dir", help="Path to preprocessed dataset (inside container: usually /workspace/output)")
    parser.add_argument("accelerator", choices=["cpu", "gpu"], help="Hardware backend: cpu | gpu")
    parser.add_argument("devices", type=int, help="Number of devices to use (e.g., 1, 2, etc.)")
    parser.add_argument("validation_split", type=float, help="Fraction of training data used for validation (e.g., 0.0 or 0.1)")
    parser.add_argument("batch_size", type=int, help="Size of each training batch")
    parser.add_argument("max_epochs", type=int, help="Maximum number of epochs to train for")
    parser.add_argument("precision", choices=["16", "32", "64", "bf16", "mixed"], help="Precision level: 16 | 32 | 64 | bf16 | mixed")
    parser.add_argument("quality", help="Quality setting")
    
    # Optional arguments
    parser.add_argument("--resume-from-checkpoint", help="Optional path to a checkpoint file to resume training")
    
    # Parse arguments
    args = parser.parse_args()
    
    # Display running arguments
    print("Running training with arguments:")
    print(f"- dataset-dir:            {args.dataset_dir}")
    print(f"- accelerator:            {args.accelerator}")
    print(f"- devices:                {args.devices}")
    print(f"- validation-split:       {args.validation_split}")
    print(f"- batch-size:             {args.batch_size}")
    print(f"- max-epochs:             {args.max_epochs}")
    print(f"- precision:              {args.precision}")
    print(f"- quality:                {args.quality}")
    print(f"- resume-from-checkpoint: {args.resume_from_checkpoint}")
    
    # Build command arguments
    cmd_args = [
        "python3", "-m", "piper_train",
        "--dataset-dir", "/workspace/output",
        "--accelerator", args.accelerator,
        "--devices", str(args.devices),
        "--batch-size", str(args.batch_size),
        "--validation-split", str(args.validation_split),
        "--num-test-examples", "0",
        "--max_epochs", str(args.max_epochs),
        "--log_every_n_steps", "1",
        "--quality", args.quality,
        "--precision", args.precision
    ]
    
    # Add resume from checkpoint if provided
    if args.resume_from_checkpoint:
        cmd_args.extend(["--resume_from_checkpoint", "/workspace/checkpoint.ckpt"])
    
    # Execute the command
    try:
        print(f"Executing: {' '.join(cmd_args)}")
        result = subprocess.run(cmd_args, check=True)
        return result.returncode
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {e}")
        return e.returncode
    except FileNotFoundError:
        print("Error: python3 command not found")
        return 1


if __name__ == "__main__":
    sys.exit(main()) 