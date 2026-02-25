#!/usr/bin/env python3
"""
Write Piper voice config (model.onnx.json) from a training checkpoint so that
PiperVoice can load the ONNX model for synthesis. Reads sample_rate, num_symbols,
num_speakers, hop_length from the checkpoint; uses DEFAULT_PHONEME_ID_MAP and
a default espeak voice (en-us).
"""
import argparse
import json
import logging
from pathlib import Path

import torch

# Piper inference config format
from piper.config import PhonemeType, PiperConfig
from piper.phoneme_ids import DEFAULT_PHONEME_ID_MAP

_LOGGER = logging.getLogger(__name__)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--checkpoint",
        required=True,
        help="Path to model checkpoint (.ckpt)",
    )
    parser.add_argument(
        "--output-dir",
        required=True,
        help="Directory containing model.onnx (config will be written as model.onnx.json)",
    )
    parser.add_argument(
        "--espeak-voice",
        default="en-us",
        help="Espeak voice for phonemization (default: en-us)",
    )
    parser.add_argument("--debug", action="store_true", help="Log at DEBUG level")
    args = parser.parse_args()

    logging.basicConfig(level=logging.DEBUG if args.debug else logging.INFO)
    checkpoint_path = Path(args.checkpoint)
    output_dir = Path(args.output_dir)

    if not checkpoint_path.is_file():
        raise FileNotFoundError(f"Checkpoint not found: {checkpoint_path}")
    if not output_dir.is_dir():
        raise FileNotFoundError(f"Output dir not found: {output_dir}")

    # Load checkpoint to read hparams (no need to load full model)
    ckpt = torch.load(checkpoint_path, map_location="cpu", weights_only=False)
    hparams = ckpt.get("hyper_parameters") or ckpt.get("hparams") or {}
    sample_rate = int(hparams.get("sample_rate", 22050))
    num_symbols = int(hparams.get("num_symbols", 256))
    num_speakers = int(hparams.get("num_speakers", 1))
    hop_length = int(hparams.get("hop_length", 256))

    config = PiperConfig(
        num_symbols=num_symbols,
        num_speakers=num_speakers,
        sample_rate=sample_rate,
        espeak_voice=args.espeak_voice,
        phoneme_id_map=DEFAULT_PHONEME_ID_MAP,
        phoneme_type=PhonemeType.ESPEAK,
        speaker_id_map={},
        hop_length=hop_length,
    )
    config_path = output_dir / "model.onnx.json"
    with open(config_path, "w", encoding="utf-8") as f:
        json.dump(config.to_dict(), f, ensure_ascii=False, indent=2)
    _LOGGER.info("Wrote %s", config_path)


if __name__ == "__main__":
    main()
