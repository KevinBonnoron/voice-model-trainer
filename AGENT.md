# Agent.md

This file provides guidance when working with code in this repository.

## Project Overview

Voice model training pipeline built on the Piper TTS framework (OHF-Voice/piper1-gpl). Shell scripts orchestrate a Docker container that runs `piper.train` modules and utility scripts for data preparation, training, and model export.

## Commands

### Docker image
The image `ghcr.io/kevinbonnoron/voice-model-trainer` is built and pushed to GHCR by GitHub Actions on each push to `main`. Scripts use `$IMAGE_NAME` from `src/utils.sh` (override with `VOICE_TRAINER_IMAGE` env var for local builds).

```bash
./build.sh          # Optional local build (tags both local and GHCR names)
```

### Run the pipeline
```bash
./run.sh augment --input <dir> --output <dir> [--num-augmentations 3] [--sample-rate 22050]
./run.sh metadata --input <dir> --output <dir> [--model small] [--language fr] [--device cpu]
./run.sh train --input <dir> --output <dir> --voice-name <name> [--audio-dir <dir>] [--espeak-voice en-us] [--sample-rate 22050] [--accelerator cpu|gpu] [--max-epochs N] [--batch-size N]
./run.sh export --output <dir> --checkpoint-file <file.ckpt> [--format onnx|generator|sample] [--sample-text "…"]
```

### Run tests
```bash
./test.sh                    # All tests
./test/run_tests.sh run      # Single suite (run, augment, metadata, train, export)
./test/test_run.sh           # Individual test file directly
```

## Architecture

Two-layer design:

1. **Shell layer** (`run.sh` → `src/*.sh`) — CLI entry point, command normalization, argument parsing/validation, Docker invocation with volume mounts
2. **Docker layer** (inside container) — `piper.train` modules for training/export, utility scripts (`augment.py`, `transcribe.py`) for data preparation

### Docker volume conventions
- Input: mounted read-only at `/workspace/input`
- Output: mounted read-write at `/workspace/output`
- Checkpoints: read-only mounts when resuming training

### Testing
Shell-based test framework in `test/` with custom assertion library (`test/test_framework.sh`). Assertions include `assert_equal`, `assert_success`, `assert_failure`, `assert_file_exists`, `assert_dir_exists`, `capture_output`, and temp resource helpers.
