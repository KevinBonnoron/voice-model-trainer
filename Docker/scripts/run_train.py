#!/usr/bin/env python3
"""
Entrypoint for piper.train fit when running in Docker.
Sets multiprocessing start method to 'spawn' so DataLoader workers
do not hang with CUDA (fork + GPU can deadlock in containers).
Then invokes piper.train with the same arguments.
"""
import sys


def main() -> None:
    # Must set before any torch/CUDA or worker creation
    import torch.multiprocessing as mp
    try:
        mp.set_start_method("spawn", force=True)
    except RuntimeError:
        pass  # already set

    # Allow pathlib.PosixPath in checkpoint files created with older PyTorch
    # versions. PyTorch 2.6+ defaults to weights_only=True which rejects it.
    import pathlib
    import torch.serialization
    torch.serialization.add_safe_globals([pathlib.PosixPath])

    # Older checkpoints may contain hyperparameters (e.g. model.sample_bytes)
    # that no longer exist in the current piper version.  Lightning's CLI
    # re-parses them on resume and calls sys.exit on unknown keys.  Patch
    # _parse_ckpt_path to fall back to CLI-provided values instead.
    import lightning.pytorch.cli as _lightning_cli
    _orig_parse_ckpt = _lightning_cli.LightningCLI._parse_ckpt_path

    def _lenient_parse_ckpt_path(self):
        import io, os
        try:
            # Suppress argparse usage dump on unknown hyperparameters
            old_stderr = sys.stderr
            sys.stderr = io.StringIO()
            try:
                _orig_parse_ckpt(self)
            finally:
                sys.stderr = old_stderr
        except SystemExit:
            print(
                "Warning: checkpoint hyperparameters could not be parsed, "
                "using CLI-provided values instead.",
                file=sys.stderr,
            )

    _lightning_cli.LightningCLI._parse_ckpt_path = _lenient_parse_ckpt_path

    # Piper logs loss_g/loss_d/val_loss without prog_bar=True, so they
    # don't appear in the progress bar.  Patch LightningModule.log to
    # force prog_bar=True for these metrics.
    import lightning.pytorch as pl
    _orig_log = pl.LightningModule.log

    _PROG_BAR_METRICS = {"loss_g", "loss_d", "val_loss"}

    def _log_with_prog_bar(self, name, *args, prog_bar=False, **kwargs):
        if name in _PROG_BAR_METRICS:
            prog_bar = True
        return _orig_log(self, name, *args, prog_bar=prog_bar, **kwargs)

    pl.LightningModule.log = _log_with_prog_bar

    # Run piper.train: argv is e.g. ['run_train.py', 'fit', '--data.csv_path', ...]
    sys.argv = ["piper.train"] + sys.argv[1:]
    import runpy
    runpy.run_module("piper.train", run_name="__main__")


if __name__ == "__main__":
    main()
