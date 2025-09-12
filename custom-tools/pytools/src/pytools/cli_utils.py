#!/usr/bin/env python3
"""
CLI utilities module for various system and development tasks.
"""

import argparse
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