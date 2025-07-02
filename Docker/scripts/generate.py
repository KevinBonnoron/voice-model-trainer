#!/usr/bin/env python3

"""
Script Name: generate.py

Description:
    Entry point for generating test sentences

Usage:
    python generate.py <output> <sentences_file> <checkpoint_file>

Arguments:
    <output>            Directory where generated audio files will be saved
    <sentences_file>    Path to the text file containing sentences to synthesize
    <checkpoint_file>   Path to the model checkpoint file to use for generation

Example:
    python generate.py ./output ./piper/etc/test_sentences/test_en-us.jsonl ./dataset/*.ckpt
"""

import argparse
import subprocess
import sys
import os


def main():
    """Main function to handle argument parsing and command execution."""
    
    # Set up argument parser
    parser = argparse.ArgumentParser(
        description="Entry point for generating test sentences",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    
    # Required arguments
    parser.add_argument("output", help="Directory where generated audio files will be saved")
    parser.add_argument("sentences_file", help="Path to the text file containing sentences to synthesize")
    parser.add_argument("checkpoint_file", help="Path to the model checkpoint file to use for generation")
    
    # Parse arguments
    args = parser.parse_args()
    
    # Display running arguments
    print("Generating test sentences with arguments:")
    print(f"- sentences-file:     {args.sentences_file}")
    print(f"- checkpoint-file:    {args.checkpoint_file}")
    
    # Change to the piper source directory
    piper_dir = "piper/src/python"
    if os.path.exists(piper_dir):
        os.chdir(piper_dir)
    else:
        print(f"Warning: Directory {piper_dir} not found, staying in current directory")
    
    # Execute the command
    try:
        # Build the command to pipe sentences file to the inference module
        cmd_args = [
            "python3", "-m", "piper_train.infer",
            "--sample-rate", "22050",
            "--checkpoint", "/workspace/checkpoint_file.ckpt",
            "--output-dir", "/workspace/output"
        ]
        
        print(f"Executing: cat /workspace/sentences_file.jsonl | {' '.join(cmd_args)}")
        
        # Read sentences file and pipe to the command
        with open("/workspace/sentences_file.jsonl", "r") as sentences_file:
            result = subprocess.run(
                cmd_args,
                stdin=sentences_file,
                check=True
            )
        
        return result.returncode
        
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {e}")
        return e.returncode
    except FileNotFoundError as e:
        print(f"Error: Required file or command not found - {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main()) 