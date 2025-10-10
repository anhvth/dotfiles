#!/usr/bin/env python3
"""Minimal client for exercising the PyTools MCP server.

The script launches ``pytools.mcp.server`` over stdio, performs a protocol
handshake, lists the exposed tools, invokes a safe command, and shuts the server
down. Use it as a sanity check while integrating with Model Context Protocol
clients such as Claude Desktop.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any, Callable

ROOT = Path(__file__).resolve().parents[1]
SRC_DIR = ROOT / "src"


def _encode_message(message: dict[str, Any]) -> bytes:
    data = json.dumps(message, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    header = f"Content-Length: {len(data)}\r\n\r\n".encode("ascii")
    return header + data


def _read_frame(stream) -> dict[str, Any] | None:
    headers: dict[str, str] = {}
    while True:
        line = stream.readline()
        if line in (b"", None):
            return None
        if line.strip() == b"":
            break
        decoded = line.decode("utf-8")
        if ":" not in decoded:
            continue
        key, value = decoded.split(":", 1)
        headers[key.strip().lower()] = value.strip()

    length_str = headers.get("content-length")
    if length_str is None:
        return None
    body = stream.read(int(length_str))
    if not body:
        return None
    return json.loads(body.decode("utf-8"))


def _send(proc: subprocess.Popen[Any], message: dict[str, Any]) -> None:
    payload = _encode_message(message)
    assert proc.stdin is not None  # noqa: S101
    proc.stdin.write(payload)
    proc.stdin.flush()


def _receive_until(
    proc: subprocess.Popen[Any], predicate: Callable[[dict[str, Any]], bool]
) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    """Collect messages until predicate returns True."""
    assert proc.stdout is not None  # noqa: S101
    seen: list[dict[str, Any]] = []
    while True:
        msg = _read_frame(proc.stdout)
        if msg is None:
            raise RuntimeError("MCP server stopped unexpectedly")
        seen.append(msg)
        if predicate(msg):
            return msg, seen


def _format_messages(messages: list[dict[str, Any]]) -> str:
    return "\n".join(json.dumps(m, indent=2) for m in messages)


def main() -> int:
    env = os.environ.copy()
    env["PYTHONPATH"] = (
        str(SRC_DIR)
        if "PYTHONPATH" not in env
        else str(SRC_DIR) + os.pathsep + env["PYTHONPATH"]
    )

    server_cmd = [
        sys.executable,
        "-m",
        "pytools.mcp.server",
        "--session-id",
        "mcp-client-example",
    ]

    proc = subprocess.Popen(
        server_cmd,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        env=env,
    )

    try:
        # 1. initialize
        _send(
            proc,
            {
                "jsonrpc": "2.0",
                "id": 1,
                "method": "initialize",
                "params": {"clientInfo": {"name": "pytools-mcp-client", "version": "0.1"}},
            },
        )
        response, trace = _receive_until(proc, lambda m: m.get("id") == 1)
        print("Initialization exchange:")
        print(_format_messages(trace))

        # 2. tools/list
        _send(proc, {"jsonrpc": "2.0", "id": 2, "method": "tools/list"})
        response, trace = _receive_until(proc, lambda m: m.get("id") == 2)
        print("\nAvailable tools:")
        print(_format_messages(trace))

        # 3. tools/call (example: env-list)
        _send(
            proc,
            {
                "jsonrpc": "2.0",
                "id": 3,
                "method": "tools/call",
                "params": {"name": "env-list", "arguments": []},
            },
        )
        response, trace = _receive_until(proc, lambda m: m.get("id") == 3)
        print("\nSample invocation (env-list):")
        print(_format_messages(trace))

        # 4. shutdown
        _send(proc, {"jsonrpc": "2.0", "id": 4, "method": "shutdown"})
        response, trace = _receive_until(proc, lambda m: m.get("id") == 4)
        print("\nShutdown acknowledgement:")
        print(_format_messages(trace))

        return 0
    finally:
        if proc.stdin:
            proc.stdin.close()
        if proc.stdout:
            proc.stdout.close()
        stderr_output = b""
        if proc.stderr:
            stderr_output = proc.stderr.read()
            proc.stderr.close()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.terminate()
            proc.wait(timeout=5)
        if stderr_output:
            sys.stderr.write(stderr_output.decode("utf-8"))


if __name__ == "__main__":
    raise SystemExit(main())
