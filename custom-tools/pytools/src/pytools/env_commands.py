#!/usr/bin/env python3
"""Environment variable management commands.

Provides three simple commands for managing KEY=VALUE entries in ~/.env:
- env-set: Set a variable
- env-unset: Remove a variable
- env-list: List all variables
"""

from __future__ import annotations

import sys
from pathlib import Path

ENV_FILE = Path.home() / ".env"


def ensure_env_file() -> None:
    """Create ~/.env if it doesn't exist."""
    ENV_FILE.parent.mkdir(parents=True, exist_ok=True)
    if not ENV_FILE.exists():
        ENV_FILE.write_text("")


def read_env() -> list[str]:
    """Read all lines from ~/.env."""
    ensure_env_file()
    return ENV_FILE.read_text().splitlines()


def write_env(lines: list[str]) -> None:
    """Write lines to ~/.env with trailing newline."""
    ENV_FILE.write_text("\n".join(lines) + ("\n" if lines else ""))


def env_set(argv: list[str] | None = None) -> int:
    """Set an environment variable in ~/.env.
    
    Usage: env-set KEY VALUE
    """
    args = argv if argv is not None else sys.argv[1:]
    
    if len(args) != 2:
        sys.stderr.write("Usage: env-set KEY VALUE\n")
        sys.stderr.write("Set a variable in ~/.env\n")
        return 1
    
    key, value = args
    
    # Remove any existing entry for this key
    lines = [line for line in read_env() if not line.startswith(f"{key}=")]
    lines.append(f"{key}={value}")
    write_env(lines)
    
    print(f"✓ Set {key}={value} in {ENV_FILE}")
    return 0


def env_unset(argv: list[str] | None = None) -> int:
    """Unset an environment variable from ~/.env.
    
    Usage: env-unset KEY
    """
    args = argv if argv is not None else sys.argv[1:]
    
    if len(args) != 1:
        sys.stderr.write("Usage: env-unset KEY\n")
        sys.stderr.write("Remove a variable from ~/.env\n")
        return 1
    
    key = args[0]
    
    original_lines = read_env()
    lines = [line for line in original_lines if not line.startswith(f"{key}=")]
    
    if len(lines) == len(original_lines):
        sys.stderr.write(f"✗ {key} not found in {ENV_FILE}\n")
        return 1
    
    write_env(lines)
    print(f"✓ Unset {key} from {ENV_FILE}")
    return 0


def env_list(argv: list[str] | None = None) -> int:
    """List all environment variables in ~/.env.
    
    Usage: env-list
    """
    args = argv if argv is not None else sys.argv[1:]
    
    if args and args[0] in ("-h", "--help"):
        print("Usage: env-list")
        print("List all variables in ~/.env")
        return 0
    
    lines = read_env()
    
    if not lines or not any(line.strip() for line in lines):
        print(f"No variables set in {ENV_FILE}")
        return 0
    
    for line in lines:
        if line.strip():
            print(line)
    
    return 0


# Entry points for direct execution
def main_set() -> int:
    """Entry point for env-set command."""
    return env_set()


def main_unset() -> int:
    """Entry point for env-unset command."""
    return env_unset()


def main_list() -> int:
    """Entry point for env-list command."""
    return env_list()


if __name__ == "__main__":
    # For testing
    if len(sys.argv) < 2:
        sys.stderr.write("Usage: python -m env_commands {set|unset|list} ...\n")
        sys.exit(1)
    
    cmd = sys.argv[1]
    args = sys.argv[2:]
    
    if cmd == "set":
        sys.exit(env_set(args))
    elif cmd == "unset":
        sys.exit(env_unset(args))
    elif cmd == "list":
        sys.exit(env_list(args))
    else:
        sys.stderr.write(f"Unknown command: {cmd}\n")
        sys.exit(1)
