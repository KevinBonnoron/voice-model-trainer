# Voice Model Training - Getting Started

This project allows you to train your own custom voice model from audio data.

## 🚀 Getting Started

### 1. Build the Docker Image

Before anything else, you need to build the Docker image that contains all necessary dependencies and tools.

From the root of the project, run:

```bash
./build.sh
```

This script will create a Docker image (e.g., named `voice-model-trainer`) used throughout the training process.

---

### 2. Run the Training Pipeline

Once the image is built, use the `run.sh` script to execute the main steps of the voice training pipeline within the Docker container.

The script supports the following main subcommands:

#### Preprocess

Used to prepare your input audio/text data before training:

```bash
./run.sh preprocess -i /path/to/your/dataset -o /path/to/output
```

- `-i`, `--input`: Path to the raw dataset (required)
- `-o`, `--output`: Path where preprocessed data will be saved (required)

#### Train

Used to start training the voice model:

```bash
./run.sh train [options]
```

Example:

```bash
./run.sh train -d ./data -a gpu --devices 1 -b 32 -m 10000 -p 32
```

Available options:

- `-d`, `--dataset-dir PATH`           : Path to the dataset directory (required)
- `-a`, `--accelerator ACCELERATOR`    : Hardware accelerator to use: `cpu` or `gpu` (default: `gpu`)
- `--devices DEVICES`                  : Number of devices to use (e.g., GPU count) (default: `1`)
- `-v`, `--validation-split FLOAT`     : Proportion of training data used for validation (default: `0.0`)
- `-b`, `--batch-size INT`             : Batch size for training (default: `32`)
- `-m`, `--max-epochs INT`             : Maximum number of training epochs (default: `10000`)
- `-p`, `--precision PRECISION`        : Precision mode: `16`, `32`, `64`, `bf16`, or `mixed` (default: `32`)
- `-r`, `--resume-from-checkpoint`     : Path to a checkpoint file to resume training
- `-h`, `--help`                       : Display help and exit

---

## 📁 Directory Structure

Example structure of your dataset:

```
/your-dataset/
├── audio.wav
├── transcript.txt
└── ...
```

Ensure that input paths are absolute or relative to the project root.

---

## 🛠 Requirements

- Docker
- Bash-compatible shell (e.g., bash, zsh)

No need to install Python or dependencies locally — everything runs inside the container.

---

## ❓ Need Help?

Run:

```bash
./run.sh preprocess --help
./run.sh train --help
```

to see all available options.
