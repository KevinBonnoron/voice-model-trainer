# Voice Model Trainer

[![Docker Build](https://github.com/KevinBonnoron/voice-model-trainer/actions/workflows/docker.yml/badge.svg)](https://github.com/KevinBonnoron/voice-model-trainer/actions/workflows/docker.yml)
[![Release](https://github.com/KevinBonnoron/voice-model-trainer/actions/workflows/release.yml/badge.svg)](https://github.com/KevinBonnoron/voice-model-trainer/actions/workflows/release.yml)

A voice model training pipeline built on the [Piper TTS](https://github.com/OHF-Voice/piper1-gpl) framework. Train custom text-to-speech voices from your own audio recordings using a simple CLI that orchestrates everything inside Docker — no local Python setup required.

## Features

- **Data augmentation** — pitch shift, tempo change, and volume variation to expand small datasets
- **Metadata generation** — auto-transcribe audio files using Whisper, or use existing transcriptions
- **Model training** — GPU-accelerated training with checkpoint resumption
- **Model export** — ONNX export with optional sample audio generation
- **Fully containerized** — all heavy processing runs inside Docker

## Requirements

- [Docker](https://docs.docker.com/get-docker/)
- A POSIX-compatible shell (bash, zsh, sh)

## Quick Start

The pre-built Docker image is pulled automatically from GHCR on first run. You can also pull it manually:

```bash
docker pull ghcr.io/kevinbonnoron/voice-model-trainer
```

Then run the full pipeline:

```bash
# 1. Generate metadata (auto-transcribes .wav files using Whisper)
./run.sh metadata -i ./my-dataset -o ./my-dataset

# 2. Review and correct transcriptions in my-dataset/metadata.csv

# 3. (Optional) Augment the dataset
./run.sh augment -i ./my-dataset -o ./dataset-augmented -n 3

# 4. Train the model
./run.sh train -i ./dataset-augmented -o ./training -n my-voice

# 5. Export to ONNX
./run.sh export -o ./model -c ./training/lightning_logs/version_0/checkpoints/last.ckpt
```

## Usage

### `metadata` — Generate metadata.csv

Generates a `metadata.csv` for training. Expects a `wavs/` subdirectory with `.wav` files.

If no `metadata.csv` exists, all audio files are automatically transcribed using [OpenAI Whisper](https://github.com/openai/whisper) (requires Docker). If a `metadata.csv` already exists, only missing transcriptions are generated.

```bash
./run.sh metadata -i <input-dir> -o <output-dir> [-m small] [-l fr] [-d cpu]
```

| Option | Description |
|--------|-------------|
| `-i, --input PATH` | Dataset directory containing `wavs/` **(required)** |
| `-o, --output PATH` | Directory to write `metadata.csv` **(required)** |
| `-m, --model MODEL` | Whisper model: `tiny`, `base`, `small`, `medium`, `large` (default: `small`) |
| `-l, --language LANG` | Language code, e.g. `en`, `fr` (default: auto-detect) |
| `-d, --device DEVICE` | `cpu` or `cuda` (default: `cpu`) |

**Behavior:**

- **No `metadata.csv`** — transcribes all `.wav` files in `wavs/` using Whisper
- **Partial `metadata.csv`** — transcribes only `.wav` files missing from the CSV
- **Complete `metadata.csv`** — no transcription needed, copies entries to output

### `augment` — Augment audio data

Creates augmented copies of each audio file with random pitch, tempo, and volume variations.

```bash
./run.sh augment -i <input-dir> -o <output-dir> [-n 3]
```

| Option | Description |
|--------|-------------|
| `-i, --input PATH` | Directory with source audio **(required)** |
| `-o, --output PATH` | Directory for augmented files **(required)** |
| `-n, --num-augmentations N` | Copies per file (default: `3`) |

If a `metadata.csv` exists in the input directory, an updated one is generated in the output with entries for all augmented files.

### `train` — Train a voice model

```bash
./run.sh train -i <input-dir> -o <output-dir> -n <voice-name> [options]
```

| Option | Description |
|--------|-------------|
| `-i, --input PATH` | Training data directory **(required)** |
| `-o, --output PATH` | Output directory **(required)** |
| `-n, --voice-name NAME` | Voice name **(required)** |
| `--audio-dir PATH` | Custom audio directory (default: `<input>/wavs`) |
| `-e, --espeak-voice VOICE` | Phonemization voice (default: `en-us`) |
| `-s, --sample-rate RATE` | Sample rate in Hz (default: `22050`) |
| `-a, --accelerator` | `cpu` or `gpu` (default: `gpu`) |
| `--devices N` | Number of devices (default: `1`) |
| `-v, --validation-split` | Validation proportion (default: `0.1`) |
| `-b, --batch-size N` | Batch size (default: `32`) |
| `-w, --num-workers N` | DataLoader workers (default: `0`) |
| `-m, --max-epochs N` | Max epochs (default: `-1`, unlimited) |
| `-p, --precision` | `16`, `32`, `64`, `bf16`, or `mixed` (default: `32`) |
| `--log-every-n-steps N` | Logging frequency (default: `10`) |
| `-r, --resume-from-checkpoint FILE` | Resume from a checkpoint |

**Example:**

```bash
./run.sh train -i ./dataset -o ./training -n my-voice -a gpu -b 16 -m 1000
```

### `export` — Export a trained model

```bash
./run.sh export -o <output-dir> [-c <checkpoint>] [-f onnx|generator|sample]
```

| Option | Description |
|--------|-------------|
| `-o, --output PATH` | Output directory **(required)** |
| `-c, --checkpoint-file FILE` | Checkpoint file (auto-detected if omitted) |
| `-f, --format FORMAT` | `onnx`, `generator`, or `sample` (default: `onnx`) |
| `-t, --sample-text TEXT` | Text for sample generation (format `sample` only) |
| `-e, --espeak-voice VOICE` | Espeak voice for config (default: `en-us`) |

**Formats:**

| Format | Output |
|--------|--------|
| `onnx` | `model.onnx` |
| `generator` | `model.generator.pt` |
| `sample` | `model.onnx` + `model.onnx.json` + `sample.wav` |

**Example:**

```bash
./run.sh export -o ./model -c ./training/lightning_logs/version_0/checkpoints/last.ckpt -f sample --sample-text "Hello, this is my custom voice."
```

## Dataset Structure

Training expects an [LJSpeech](https://keithito.com/LJ-Speech-Dataset/)-style layout:

```
dataset/
├── metadata.csv          # pipe-delimited: 0001.wav|Hello world
└── wavs/
    ├── 0001.wav
    ├── 0002.wav
    └── ...
```

To get started, just place your `.wav` files in a `wavs/` subdirectory and run `metadata`:

```
my-dataset/
└── wavs/
    ├── 001.wav
    ├── 002.wav
    └── ...
```

```bash
./run.sh metadata -i ./my-dataset -o ./my-dataset -l fr
# → generates my-dataset/metadata.csv with Whisper transcriptions
```

## Local Docker Build

If you want to build the image locally instead of pulling from GHCR:

```bash
./build.sh
export VOICE_TRAINER_IMAGE=voice-model-trainer
```

You can also set `VOICE_TRAINER_PULL=never` to skip pulling the remote image.

## Testing

```bash
# Run all tests
./test.sh

# Run a specific test suite
./test/run_tests.sh augment

# Available suites: run, augment, metadata, train, export
```

## Help

Every command supports `--help`:

```bash
./run.sh --help
./run.sh metadata --help
./run.sh augment --help
./run.sh train --help
./run.sh export --help
```
