#!/usr/bin/env python3

"""
Script Name: export.py

Description:
    Entry point for exporting data

Usage:
    python export.py <output> <checkpoint_file> <format>

Arguments:
    <output>            Directory where generated audio files will be saved
    <checkpoint_file>   Path to the model checkpoint file to use for generation
    <format>            Format of the exported file (onnx, torchscript, generator)

Example:
    python export.py ./output ./dataset/*.ckpt onnx
"""

import argparse
import subprocess
import sys
import os


def main():
    """Main function to handle argument parsing and command execution."""
    
    # Set up argument parser
    parser = argparse.ArgumentParser(
        description="Entry point for exporting data",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    
    # Required arguments
    parser.add_argument("output", help="Directory where generated audio files will be saved")
    parser.add_argument("checkpoint_file", help="Path to the model checkpoint file to use for generation")
    parser.add_argument("format", choices=["onnx", "torchscript", "generator"], 
                       help="Format of the exported file (onnx, torchscript, generator)")
    
    # Parse arguments
    args = parser.parse_args()
    
    # Display running arguments
    print("Exporting with arguments:")
    print(f"- output:             {args.output}")
    print(f"- checkpoint-file:    {args.checkpoint_file}")
    print(f"- format:             {args.format}")
    
    # Change to the piper source directory
    piper_dir = "piper/src/python"
    if os.path.exists(piper_dir):
        os.chdir(piper_dir)
    else:
        print(f"Warning: Directory {piper_dir} not found, staying in current directory")
    
    try:
        if args.format == "onnx":
            # Export to ONNX format
            print("Exporting to ONNX format...")
            
            # Export unoptimized ONNX
            export_cmd = [
                "python3", "-m", "piper_train.export_onnx",
                "/workspace/checkpoint_file.ckpt",
                "/workspace/output/model.unoptimized.onnx"
            ]
            subprocess.run(export_cmd, check=True)
            
            # Optimize ONNX
            optimize_cmd = [
                "onnxsim",
                "/workspace/output/model.unoptimized.onnx",
                "/workspace/output/model.onnx"
            ]
            subprocess.run(optimize_cmd, check=True)
            
            # Remove unoptimized file
            if os.path.exists("/workspace/output/model.unoptimized.onnx"):
                os.remove("/workspace/output/model.unoptimized.onnx")
                
        elif args.format == "torchscript":
            # Export to TorchScript format
            print("Exporting to TorchScript format...")
            export_cmd = [
                "python3", "-m", "piper_train.export_torchscript",
                "/workspace/checkpoint_file.ckpt",
                "/workspace/output/model.torchscript.pt"
            ]
            subprocess.run(export_cmd, check=True)
            
        elif args.format == "generator":
            # Export to generator format
            print("Exporting to generator format...")
            export_cmd = [
                "python3", "-m", "piper_train.export_generator",
                "/workspace/checkpoint_file.ckpt",
                "/workspace/output/model.generator.pt"
            ]
            subprocess.run(export_cmd, check=True)
            
        print(f"Export completed successfully to {args.format} format")
        return 0
        
    except subprocess.CalledProcessError as e:
        print(f"Error during export: {e}")
        return e.returncode
    except FileNotFoundError as e:
        print(f"Error: Required command not found - {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main()) 