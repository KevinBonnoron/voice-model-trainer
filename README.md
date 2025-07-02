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

### 🔧 Preprocess

Used to prepare your input audio/text data before training:

```bash
./run.sh preprocess [options]
```

Available options:
- `-i`, `--input`                      : Path to the raw dataset (required)
- `-o`, `--output`                     : Path where preprocessed data will be saved (required)
- `-l`, `--language LANGUAGE`          : Set the preprocess language (default: `en-us`)
- `-s`, `--sample-rate SAMPLE_RATE`    : Set the preprocess sample rate (default: `22050`)
- `-m`, `--multiple-speaker VALUE`     : Set the multiple speaker mode (default: `false`)
- `-f`, `--format FORMAT`              : Set the dataset format: `ljspeech` (default: `ljspeech`)
- `-h`, `--help`                       : Show help message

Example:

```bash
./run.sh preprocess -i ./input -o ./dataset
```


#### 🎯 Train

Used to start training the voice model:

```bash
./run.sh train [options]
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

Example:

```bash
./run.sh train -d ./data -a gpu --devices 1 -b 32 -m 10000 -p 32
```

#### 🎵 Generate

Used to generate test sentences from a trained model:

```bash
./run.sh generate [options]
```

Available options:

- `-o`, `--output PATH`              : Path to save generated test data (required)
- `-s`, `--sentences-file FILE`      : Path to the sentences file in jsonl format (required)
- `-c`, `--checkpoint-file`          : Path to the checkpoint file in ckpt format (required)
- `-h`, `--help`                     : Show help message

Example:

```bash
./run.sh generate -o ./output -s ./en-us.jsonl -c ./checkpoint.ckpt
```

#### 🚀 Export

Used to export a trained model in different formats:

```bash
./run.sh export [options]
```

Available options:

- `-o`, `--output PATH`              : Path to save exported data (required)
- `-c`, `--checkpoint-file`          : Path to the checkpoint file in ckpt format (required)
- `-f`, `--format FORMAT`            : Exported format: `onnx` (default: `onnx`)
- `-h`, `--help`                     : Show help message

Example:

```bash
./run.sh export -o ./exported-model -c ./checkpoint.ckpt
```

---

## 📁 Directory Structure

Example structure of your dataset:

```
/your-dataset/
├── wavs/
    ├── 0001.wav
    ├── 0002.wav
    └── ...
├── dataset.csv
└── ...
```

Ensure that input paths are absolute or relative to the project root.

---

## 🛠 Requirements

- Docker
- Any shell (e.g., bash, zsh)

No need to install Python or dependencies locally — everything runs inside the container.

---

## ❓ Need Help?

Run:

```bash
./run.sh --help
./run.sh preprocess --help
./run.sh train --help
./run.sh generate --help
./run.sh export --help
```

to see all available options.
