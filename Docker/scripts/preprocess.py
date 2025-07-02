#!/usr/bin/env python3

"""
Script Name: preprocess.py

Description:
    Launches the preprocessing step for training a voice model using piper_train.

Usage:
    python preprocess.py <input> <output> <language> <sample_rate> <single_speaker> <dataset_format> <max_workers> <audio_quality>

Arguments:
    <input>              Path to the raw dataset directory containing source audio and transcripts
    <output>             Path where the preprocessed dataset will be saved
    <language>           Language code (e.g., en-us, fr-fr)
    <sample_rate>        Audio sample rate in Hz (e.g., 22050, 44100)
    <single_speaker>     Set single speaker mode
    <dataset_format>     Set the dataset format (eg: ljspeech, mycroft)
    <max_workers>        Number of workers to use for preprocessing
    <audio_quality>      Audio quality (eg: high, medium, low)

Example:
    python preprocess.py en-us 22050

Notes:
    - Expects input data to be in /workspace/input
    - Preprocessed output will be written to /workspace/output
    - Must be run inside the appropriate Docker container or environment
"""

import argparse
import subprocess
import sys


def main():
    """Main function to handle argument parsing and command execution."""
    
    # Set up argument parser
    parser = argparse.ArgumentParser(
        description="Launch preprocessing step for training a voice model using piper_train",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    
    # Required arguments
    parser.add_argument("input", help="Path to the raw dataset directory containing source audio and transcripts")
    parser.add_argument("output", help="Path where the preprocessed dataset will be saved")
    parser.add_argument("language", help="Language code (e.g., en-us, fr-fr)")
    parser.add_argument("sample_rate", type=int, help="Audio sample rate in Hz (e.g., 22050, 44100)")
    parser.add_argument("single_speaker", help="Set single speaker mode")
    parser.add_argument("dataset_format", help="Set the dataset format (eg: ljspeech, mycroft)")
    parser.add_argument("max_workers", type=int, help="Number of workers to use for preprocessing")
    parser.add_argument("audio_quality", help="Audio quality (eg: high, medium, low)")
    
    # Parse arguments
    args = parser.parse_args()
    
    # Display running arguments
    print("Running preprocessing with arguments:")
    print(f"- input:           {args.input}")
    print(f"- output:          {args.output}")
    print(f"- language:        {args.language}")
    print(f"- sample-rate:     {args.sample_rate}")
    print(f"- single-speaker   {args.single_speaker}")
    print(f"- dataset-format   {args.dataset_format}")
    print(f"- max-workers      {args.max_workers}")
    print(f"- audio-quality    {args.audio_quality}")
    
    # Build command arguments
    cmd_args = [
        "python", "-m", "piper_train.preprocess",
        "--language", args.language,
        "--input-dir", "/workspace/input",
        "--output-dir", "/workspace/output",
        "--dataset-format", args.dataset_format,
        "--sample-rate", str(args.sample_rate),
        "--max-workers", str(args.max_workers)
    ]
    
    # Add single speaker flag if specified
    if args.single_speaker.lower() == "true":
        cmd_args.append("--single-speaker")
    
    # Execute the command
    try:
        result = subprocess.run(cmd_args, check=True)
        return result.returncode
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {e}")
        return e.returncode
    except FileNotFoundError:
        print("Error: python command not found")
        return 1


if __name__ == "__main__":
    sys.exit(main()) 