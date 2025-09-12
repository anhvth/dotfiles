#!/usr/bin/env python3
"""Command-line tool to manage simple key=value pairs in ~/.env

This replicates the behavior of the original `set_env` and `unset_env`
zsh functions: write entries like KEY=VALUE to the user's `~/.env` file,
removing any previous entry for the same key. Also provide list and unset
operations for convenience.
"""

from __future__ import annotations

import argparse
from pathlib import Path
import sys


ENV_FILE = Path.home() / ".env"


def ensure_env_file() -> None:
    ENV_FILE.parent.mkdir(parents=True, exist_ok=True)
    if not ENV_FILE.exists():
        ENV_FILE.write_text("")


def read_env() -> list[str]:
    ensure_env_file()
    return ENV_FILE.read_text().splitlines()


def write_env(lines: list[str]) -> None:
    ENV_FILE.write_text("\n".join(lines) + ("\n" if lines else ""))


def set_var(key: str, value: str) -> None:
    lines = [l for l in read_env() if not l.startswith(f"{key}=")]
    lines.append(f"{key}={value}")
    write_env(lines)
    print(f"Set {key}={value} in {ENV_FILE}")


def unset_var(key: str) -> None:
    lines = [l for l in read_env() if not l.startswith(f"{key}=")]
    if len(lines) == len(read_env()):
        print(f"{key} not found in {ENV_FILE}")
        return
    write_env(lines)
    print(f"Unset {key} from {ENV_FILE}")


def list_vars() -> None:
    for line in read_env():
        if line.strip():
            print(line)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="set-env", description="Manage simple KEY=VALUE entries in ~/.env")
    sub = parser.add_subparsers(dest="cmd")

    p_set = sub.add_parser("set", help="Set a variable")
    p_set.add_argument("key")
    p_set.add_argument("value")

    p_unset = sub.add_parser("unset", help="Unset a variable")
    p_unset.add_argument("key")

    sub.add_parser("list", help="List variables")

    args = parser.parse_args(argv)

    if args.cmd == "set":
        set_var(args.key, args.value)
        return 0
    if args.cmd == "unset":
        unset_var(args.key)
        return 0
    if args.cmd == "list":
        list_vars()
        return 0

    parser.print_help()
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
