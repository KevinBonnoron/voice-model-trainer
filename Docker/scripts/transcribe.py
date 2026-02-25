#!/usr/bin/env python3
"""
Transcribe audio files using OpenAI's Whisper model.
Writes transcriptions in pipe-delimited format (filename|text) to an output file.
"""
import argparse
import logging
import sys
from pathlib import Path

_LOGGER = logging.getLogger(__name__)

VALID_MODELS = ("tiny", "base", "small", "medium", "large")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--input-dir",
        required=True,
        help="Directory containing .wav files to transcribe",
    )
    parser.add_argument(
        "--output-file",
        required=True,
        help="Path to write transcriptions (pipe-delimited: filename|text)",
    )
    parser.add_argument(
        "--model",
        default="small",
        choices=VALID_MODELS,
        help="Whisper model size (default: small)",
    )
    parser.add_argument(
        "--language",
        default=None,
        help="Language code (e.g., en, fr). Auto-detected if omitted.",
    )
    parser.add_argument(
        "--device",
        default="cpu",
        help="Device for inference: cpu or cuda (default: cpu)",
    )
    parser.add_argument(
        "--files",
        nargs="*",
        default=None,
        help="Specific .wav filenames to transcribe. If omitted, all .wav files are processed.",
    )
    parser.add_argument("--debug", action="store_true", help="Log at DEBUG level")
    args = parser.parse_args()

    logging.basicConfig(level=logging.DEBUG if args.debug else logging.INFO)

    input_dir = Path(args.input_dir)
    output_file = Path(args.output_file)

    if not input_dir.is_dir():
        _LOGGER.error("Input directory does not exist: %s", input_dir)
        sys.exit(1)

    # Collect .wav files to process
    if args.files:
        wav_files = [input_dir / f for f in args.files]
        missing = [f for f in wav_files if not f.is_file()]
        if missing:
            for f in missing:
                _LOGGER.warning("File not found: %s", f)
            wav_files = [f for f in wav_files if f.is_file()]
    else:
        wav_files = sorted(input_dir.glob("*.wav"))

    if not wav_files:
        _LOGGER.error("No .wav files to transcribe in %s", input_dir)
        sys.exit(1)

    _LOGGER.info("Found %d .wav file(s) to transcribe", len(wav_files))
    _LOGGER.info("Loading Whisper model '%s' on device '%s'...", args.model, args.device)

    import whisper

    model = whisper.load_model(args.model, device=args.device)

    transcribe_opts = {}
    if args.language:
        transcribe_opts["language"] = args.language

    succeeded = 0
    failed = 0
    transcript_lines = []

    for wav_path in wav_files:
        _LOGGER.info("Transcribing: %s", wav_path.name)
        try:
            result = model.transcribe(str(wav_path), **transcribe_opts)
            text = result["text"].strip()

            if not text:
                _LOGGER.warning("Empty transcription for '%s', skipping", wav_path.name)
                failed += 1
                continue

            transcript_lines.append(f"{wav_path.name}|{text}")
            succeeded += 1

        except Exception:
            _LOGGER.exception("Failed to transcribe '%s'", wav_path.name)
            failed += 1

    # Write transcriptions to output file
    if transcript_lines:
        output_file.write_text("\n".join(transcript_lines) + "\n", encoding="utf-8")
        _LOGGER.info("Wrote %d transcription(s) to %s", len(transcript_lines), output_file)

    _LOGGER.info("Done: %d succeeded, %d failed", succeeded, failed)

    if succeeded == 0:
        _LOGGER.error("All files failed to transcribe")
        sys.exit(1)


if __name__ == "__main__":
    main()
