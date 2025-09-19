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
    """Initialize a Python project with common structure."""
    parser = argparse.ArgumentParser(description="Initialize a Python project")
    parser.add_argument("name", help="Project name")
    parser.add_argument("--venv", action="store_true", help="Create virtual environment")
    
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
        (project_path / "README.md").write_text(f"# {args.name}\n\nDescription of {args.name} project.\n")
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
        
        if args.venv:
            subprocess.run([sys.executable, "-m", "venv", str(project_path / ".venv")])
        
        print(f"Created Python project: {args.name}")
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
    
    parser = argparse.ArgumentParser(description="Keep SSH connection alive")
    parser.add_argument("host", help="SSH host to connect to")
    parser.add_argument("--interval", type=int, default=60, help="Ping interval in seconds")
    
    args = parser.parse_args()
    
    print(f"Keeping SSH connection alive to {args.host} (interval: {args.interval}s)")
    print("Press Ctrl+C to stop")
    
    try:
        while True:
            try:
                result = subprocess.run(
                    ["ssh", "-o", "ConnectTimeout=10", args.host, "echo", "keepalive"],
                    capture_output=True,
                    timeout=15
                )
                if result.returncode == 0:
                    print(".", end="", flush=True)
                else:
                    print("X", end="", flush=True)
            except subprocess.TimeoutExpired:
                print("T", end="", flush=True)
            except Exception as e:
                print(f"E({e})", end="", flush=True)
            
            time.sleep(args.interval)
    except KeyboardInterrupt:
        print("\nSSH keep-alive stopped")
        return 0


def setup_vscode():
    """Setup VSCode settings by merging default Python settings into .vscode/settings.json."""
    parser = argparse.ArgumentParser(description="Setup VSCode settings for Python development")
    parser.add_argument("--target-dir", default=".", help="Target directory containing .vscode (default: current directory)")
    
    args = parser.parse_args()
    
    try:
        # Get the path to the default settings file
        script_dir = Path(__file__).parent
        default_settings_file = script_dir / "vscode_settings" / "default_python.json"
        
        if not default_settings_file.exists():
            print(f"Error: Default settings file not found at {default_settings_file}")
            return 1
        
        # Read default settings
        with open(default_settings_file, 'r') as f:
            default_settings = json.load(f)
        
        # Setup target .vscode directory and settings file
        target_dir = Path(args.target_dir).resolve()
        vscode_dir = target_dir / ".vscode"
        settings_file = vscode_dir / "settings.json"
        
        # Create .vscode directory if it doesn't exist
        vscode_dir.mkdir(exist_ok=True)
        
        # Read existing settings or create empty dict
        existing_settings = {}
        if settings_file.exists():
            try:
                with open(settings_file, 'r') as f:
                    existing_settings = json.load(f)
            except json.JSONDecodeError:
                print(f"Warning: {settings_file} contains invalid JSON, starting fresh")
                existing_settings = {}
        
        # Merge settings (default settings will override existing ones for Python-specific keys)
        merged_settings = existing_settings.copy()
        merged_settings.update(default_settings)
        
        # Write merged settings back
        with open(settings_file, 'w') as f:
            json.dump(merged_settings, f, indent=4)
        
        print(f"✅ VSCode settings updated successfully!")
        print(f"📁 Settings file: {settings_file}")
        print(f"🔧 Applied {len(default_settings)} Python-specific settings")
        
        return 0
        
    except Exception as e:
        print(f"Error setting up VSCode: {e}")
        return 1


def atv_select():
    """Select and activate a virtual environment from history using fzf."""
    parser = argparse.ArgumentParser(description="Select and activate virtual environment using fzf")
    parser.add_argument("--help-venv", action="store_true", help="Show virtual environment management help")
    
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
            text=True
        )
        return result.returncode
        
    except Exception as e:
        print(f"Error running venv-select: {e}")
        print("Make sure zsh and the venv functions are properly configured.")
        return 1