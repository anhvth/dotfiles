#!/usr/bin/env python3
"""
CLI utilities module for various system and development tasks.
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path


def pyinit():
    """Initialize a Python project with common structure and VSCode settings."""
    parser = argparse.ArgumentParser(description="Initialize a Python project")
    parser.add_argument("name", help="Project name")
    parser.add_argument(
        "--venv", action="store_true", help="Create virtual environment"
    )

    args = parser.parse_args()

    project_path = Path(args.name)
    if project_path.exists():
        print(f"Error: Directory '{args.name}' already exists")
        return 1

    try:
        # Create project structure
        project_path.mkdir()
        (project_path / "src").mkdir()
        (project_path / "tests").mkdir()

        # Create basic files
        (project_path / "README.md").write_text(
            f"# {args.name}\n\nDescription of {args.name} project.\n"
        )
        (project_path / "pyproject.toml").write_text(f"""[project]
name = "{args.name}"
version = "0.1.0"
description = ""
readme = "README.md"
requires-python = ">=3.8"
dependencies = []

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
""")

        (project_path / ".gitignore").write_text("""__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

.env
.venv
env/
venv/
ENV/
env.bak/
venv.bak/

.pytest_cache/
.coverage
htmlcov/

.DS_Store
""")

        # Setup VSCode settings
        vscode_dir = project_path / ".vscode"
        vscode_dir.mkdir(exist_ok=True)
        settings_file = vscode_dir / "settings.json"

        # Get default Python settings
        script_dir = Path(__file__).parent
        default_settings_file = script_dir / "vscode_settings" / "default_python.json"

        if default_settings_file.exists():
            with open(default_settings_file, "r") as f:
                default_settings = json.load(f)

            with open(settings_file, "w") as f:
                json.dump(default_settings, f, indent=4)

            print(f"✅ Created Python project: {args.name}")
            print("📁 VSCode settings configured")
        else:
            print(f"✅ Created Python project: {args.name}")
            print(
                f"⚠️  Warning: Default VSCode settings not found at {default_settings_file}"
            )

        if args.venv:
            subprocess.run([sys.executable, "-m", "venv", str(project_path / ".venv")])
            print(f"🐍 Virtual environment created at {args.name}/.venv")

        return 0

    except Exception as e:
        print(f"Error creating project: {e}")
        return 1


def keep_ssh():
    """Keep SSH connections alive by running a persistent connection."""
    import time
    import signal
    import sys

    def signal_handler(sig, frame):
        print("\nSSH keep-alive stopped")
        sys.exit(0)

    signal.signal(signal.SIGINT, signal_handler)

    parser = argparse.ArgumentParser(
        description="Keep SSH connection alive by sending periodic keepalive messages",
        epilog="""
Examples:
  keep-ssh user@example.com
  keep-ssh admin@server.com --interval 30

Output symbols:
  . = successful keepalive
  X = connection failed
  T = connection timed out
  E = other error

Make sure SSH keys are set up for passwordless authentication.
        """,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("host", help="SSH host to connect to (e.g., user@hostname)")
    parser.add_argument(
        "--interval",
        type=int,
        default=60,
        help="Ping interval in seconds (default: 60)",
    )
    parser.add_argument(
        "--verbose", action="store_true", help="Show detailed output instead of symbols"
    )

    args = parser.parse_args()

    print(f"Keeping SSH connection alive to {args.host} (interval: {args.interval}s)")
    print("Press Ctrl+C to stop")
    if not args.verbose:
        print("Output: . = success, X = failed, T = timeout, E = error")

    try:
        while True:
            try:
                result = subprocess.run(
                    [
                        "ssh",
                        "-o",
                        "ConnectTimeout=10",
                        "-o",
                        "BatchMode=yes",
                        "-o",
                        "StrictHostKeyChecking=accept-new",
                        args.host,
                        "echo",
                        "keepalive",
                    ],
                    capture_output=True,
                    timeout=15,
                )
                if result.returncode == 0:
                    if args.verbose:
                        print(f"[{time.strftime('%H:%M:%S')}] Keepalive successful")
                    else:
                        print(".", end="", flush=True)
                else:
                    if args.verbose:
                        print(
                            f"[{time.strftime('%H:%M:%S')}] Connection failed (exit code {result.returncode})"
                        )
                    else:
                        print("X", end="", flush=True)
            except subprocess.TimeoutExpired:
                if args.verbose:
                    print(f"[{time.strftime('%H:%M:%S')}] Connection timed out")
                else:
                    print("T", end="", flush=True)
            except Exception as e:
                if args.verbose:
                    print(f"[{time.strftime('%H:%M:%S')}] Error: {e}")
                else:
                    print("E", end="", flush=True)

            time.sleep(args.interval)
    except KeyboardInterrupt:
        print("\nSSH keep-alive stopped")
        return 0


def atv_select():
    """Select and activate a virtual environment from history using fzf."""
    parser = argparse.ArgumentParser(
        description="Select and activate virtual environment using fzf"
    )
    parser.add_argument(
        "--help-venv",
        action="store_true",
        help="Show virtual environment management help",
    )

    args = parser.parse_args()

    if args.help_venv:
        print("""
Virtual Environment Selection with fzf

This tool provides an interactive way to select and activate Python virtual environments
from your usage history using fzf (fuzzy finder).

Features:
- Lists most recently used virtual environments
- Interactive selection with fzf fuzzy search
- Fallback to most recent if fzf is not available
- Automatic activation of selected environment

Dependencies:
- fzf (optional but recommended for interactive selection)
- Virtual environment history file at ~/.cache/dotfiles/venv_history

Note: This is a Python implementation that calls the shell function 'venv-select'.
For full virtual environment management, use the shell commands directly:
- va, venv-activate: Activate environment
- vd, venv-deactivate: Deactivate environment  
- vc, venv-create: Create new environment
- vs, venv-select: Select from history (same as this command)
- vl, venv-list: List all environments
- vh, venv-help: Show detailed help
        """)
        return 0

    try:
        # Call the shell function venv-select which handles fzf interaction
        result = subprocess.run(
            ["zsh", "-c", "source ~/.zshrc && venv-select"],
            capture_output=False,  # Let it interact with terminal
            text=True,
        )
        return result.returncode

    except Exception as e:
        print(f"Error running venv-select: {e}")
        print("Make sure zsh and the venv functions are properly configured.")
        return 1
