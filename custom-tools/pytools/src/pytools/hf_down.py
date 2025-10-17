#!/usr/bin/env python3
"""
Hugging Face Downloader - Download files from Hugging Face Hub using modern CLI.

This tool downloads files from Hugging Face Hub using the official `hf` CLI
with automatic dependency management and optimized transfer speeds.
"""

import importlib
import os
import subprocess
import sys


def ensure_package(pkg_name, import_name=None):
    """Ensure a Python package is installed. If not, install it via pip."""
    import_name = import_name or pkg_name
    try:
        importlib.import_module(import_name)
    except ImportError:
        print(f"[INFO] Installing {pkg_name} …")
        subprocess.check_call([sys.executable, "-m", "pip", "install", pkg_name])


def check_hf_cli():
    """Check if hf CLI is available and working."""
    try:
        # Just try to run 'hf' without arguments - it should show help and exit with code 2
        subprocess.run(["hf"], capture_output=True, text=True)
        # hf command exists if it runs (even with non-zero exit code showing help)
        return True
    except FileNotFoundError:
        return False


def run_cmd(cmd_args):
    """Run a shell command, raising on error."""
    print(f"[DEBUG] Running: {' '.join(cmd_args)}")
    result = subprocess.run(cmd_args, capture_output=False)
    if result.returncode != 0:
        raise RuntimeError(f"Command failed: {' '.join(cmd_args)}")


def main():
    """Main entry point for the hf-down command."""
    if len(sys.argv) < 2:
        print("Usage: hf-down <repo_id> [--output <path>]")
        print("Download files from Hugging Face Hub")
        return 1

    repo = sys.argv[1]
    output_path = None

    # Parse optional output
    if "--output" in sys.argv:
        idx = sys.argv.index("--output")
        if idx + 1 < len(sys.argv):
            output_path = sys.argv[idx + 1]
        else:
            print("Error: --output given but no path specified.")
            return 1

    # Ensure dependencies
    # Need huggingface_hub with hf_transfer and the CLI
    ensure_package("huggingface_hub", "huggingface_hub")

    # Verify huggingface_hub installation
    try:
        # Verify import works
        import huggingface_hub  # noqa: F401
    except Exception as e:
        print("[ERROR] Could not import huggingface_hub after install:", e)
        return 1

    # Ensure hf CLI is available
    if not check_hf_cli():
        print("[INFO] hf CLI not found. Installing via pip …")
        subprocess.check_call(
            [sys.executable, "-m", "pip", "install", "huggingface_hub[cli]"]
        )
        # re-check
        if not check_hf_cli():
            print("[ERROR] Cannot install hf CLI.")
            return 1

    # Try to enable faster transfer if hf_transfer is available
    try:
        import hf_transfer  # noqa: F401

        os.environ.setdefault("HF_HUB_ENABLE_HF_TRANSFER", "1")
        print("[INFO] Using hf_transfer for faster downloads")
    except ImportError:
        # hf_transfer not available, continue without it
        print("[INFO] hf_transfer not available, using standard download")
        # Make sure to not set the environment variable
        os.environ.pop("HF_HUB_ENABLE_HF_TRANSFER", None)

    # Build download command
    cmd = ["hf", "download", repo]
    if output_path:
        # Using --local-dir for local directory output
        cmd += ["--local-dir", output_path]

    # Finally run the download
    try:
        run_cmd(cmd)
    except Exception as e:
        print("[ERROR] Download failed:", e)
        return 1

    print("[OK] Done.")
    return 0


if __name__ == "__main__":
    exit(main())
