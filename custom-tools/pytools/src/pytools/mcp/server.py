"""Model Context Protocol server exposing PyTools commands."""

from __future__ import annotations

import argparse
import json
import shlex
import sys
import time
import uuid
from dataclasses import dataclass
from typing import Any, Iterable

from .. import __version__
from ..cli import build_registry
from ..core.executor import (
    ToolExecutionResult,
    ToolNotFoundError,
    ToolPassthroughError,
    execute_tool_capture,
    should_expose_tool,
)
from ..core.registry import Registry, Tool
from ..core.session import SessionLogger

JSONRPC_VERSION = "2.0"
MCP_PROTOCOL_VERSION = "0.1.0"


@dataclass
class JsonRpcResponse:
    """Wrapper representing a JSON-RPC response or error."""

    payload: dict[str, Any]


class StdioTransport:
    """Simple stdio transport implementing MCP framing."""

    def __init__(self, *, reader, writer) -> None:
        self._reader = reader
        self._writer = writer

    def read_message(self) -> dict[str, Any] | None:
        """Read the next JSON-RPC message. Returns None on EOF."""
        headers: dict[str, str] = {}
        while True:
            line = self._reader.readline()
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
        length = int(length_str)
        body = self._reader.read(length)
        if not body:
            return None
        return json.loads(body.decode("utf-8"))

    def send(self, message: dict[str, Any]) -> None:
        """Send a JSON-RPC message."""
        data = json.dumps(message, separators=(",", ":"), ensure_ascii=False)
        encoded = data.encode("utf-8")
        header = f"Content-Length: {len(encoded)}\r\n\r\n".encode("ascii")
        self._writer.write(header)
        self._writer.write(encoded)
        self._writer.flush()

    def notify(self, method: str, params: dict[str, Any] | None = None) -> None:
        """Send a JSON-RPC notification."""
        payload: dict[str, Any] = {
            "jsonrpc": JSONRPC_VERSION,
            "method": method,
        }
        if params is not None:
            payload["params"] = params
        self.send(payload)


def _jsonrpc_result(msg_id: int | str | None, result: Any) -> JsonRpcResponse:
    return JsonRpcResponse(
        {
            "jsonrpc": JSONRPC_VERSION,
            "id": msg_id,
            "result": result,
        }
    )


def _jsonrpc_error(
    msg_id: int | str | None, code: int, message: str, data: Any | None = None
) -> JsonRpcResponse:
    error_payload: dict[str, Any] = {
        "jsonrpc": JSONRPC_VERSION,
        "id": msg_id,
        "error": {"code": code, "message": message},
    }
    if data is not None:
        error_payload["error"]["data"] = data
    return JsonRpcResponse(error_payload)


def _coerce_arguments(raw: Any) -> list[str]:
    """Normalise arguments provided in a MCP tool invocation."""
    if raw is None:
        return []
    if isinstance(raw, list):
        return [str(item) for item in raw]
    if isinstance(raw, dict):
        if "args" in raw:
            return _coerce_arguments(raw["args"])
        if "argString" in raw:
            return shlex.split(str(raw["argString"]))
    if isinstance(raw, str):
        return shlex.split(raw)
    raise ValueError("Unsupported arguments payload for tools/call")


def _tool_to_descriptor(tool: Tool) -> dict[str, Any]:
    """Convert a registry Tool into a MCP tool descriptor."""
    args_description = tool.usage or f"{tool.name} [args...]"
    return {
        "name": tool.name,
        "description": tool.summary,
        "inputSchema": {
            "type": "object",
            "properties": {
                "args": {
                    "type": "array",
                    "items": {"type": "string"},
                    "description": f"Arguments passed to `{tool.name}`. Usage: {args_description}",
                    "default": [],
                }
            },
            "required": [],
        },
        "metadata": {
            "usage": tool.usage,
            "tags": tool.tags,
            "safety": tool.safety,
        },
    }


def _format_content(result: ToolExecutionResult) -> list[dict[str, Any]]:
    """Format tool execution output for MCP clients."""
    content: list[dict[str, Any]] = []
    if result.stdout:
        content.append({"type": "text", "text": result.stdout})
    if result.stderr:
        content.append(
            {
                "type": "text",
                "text": result.stderr,
                "annotations": {"stream": "stderr"},
            }
        )
    if not content:
        content.append({"type": "text", "text": ""})
    return content


class MCPServer:
    """Core MCP server implementation."""

    def __init__(
        self,
        registry: Registry,
        logger: SessionLogger,
        transport: StdioTransport,
        *,
        interactive: bool = False,
    ) -> None:
        self._registry = registry
        self._logger = logger
        self._transport = transport
        self._initialized = False
        self._shutdown_requested = False
        self._client_info: dict[str, Any] = {}
        self._interactive = interactive
        self._banner_shown = False

    def serve(self) -> int:
        """Serve until EOF or exit notification."""
        if self._interactive and not self._banner_shown:
            self._print_interactive_banner()
            self._banner_shown = True

        while True:
            message = self._transport.read_message()
            if message is None:
                if self._interactive:
                    time.sleep(0.2)
                    continue
                break

            reply = self._handle_message(message)
            if reply is not None:
                self._transport.send(reply.payload)

            if self._shutdown_requested:
                break

        return 0

    # ------------------------------------------------------------------
    # Message handlers

    def _handle_message(self, message: dict[str, Any]) -> JsonRpcResponse | None:
        try:
            method = message.get("method")
            msg_id = message.get("id")
            if method is None:
                return _jsonrpc_error(msg_id, -32600, "Missing method")

            if method == "initialize":
                return self._handle_initialize(msg_id, message.get("params") or {})
            if method == "tools/list":
                return self._handle_tools_list(msg_id)
            if method == "tools/call":
                return self._handle_tools_call(msg_id, message.get("params") or {})
            if method == "shutdown":
                self._shutdown_requested = True
                return _jsonrpc_result(msg_id, None)
            if method == "ping":
                return _jsonrpc_result(msg_id, {"ok": True})
            if method == "exit":
                self._shutdown_requested = True
                return None

            return _jsonrpc_error(msg_id, -32601, f"Unknown method: {method}")
        except Exception as exc:  # noqa: BLE001
            return _jsonrpc_error(message.get("id"), -32603, "Server error", str(exc))

    def _handle_initialize(
        self, msg_id: int | str | None, params: dict[str, Any]
    ) -> JsonRpcResponse:
        self._initialized = True
        self._client_info = params.get("clientInfo", {})

        result = {
            "protocolVersion": MCP_PROTOCOL_VERSION,
            "serverInfo": {"name": "pytools-mcp", "version": __version__},
            "capabilities": {
                "tools": {"list": True, "call": True},
            },
        }

        # Notify client that we are ready.
        self._transport.notify(
            "initialized",
            {
                "serverInfo": result["serverInfo"],
                "clientInfo": self._client_info,
            },
        )
        return _jsonrpc_result(msg_id, result)

    def _handle_tools_list(self, msg_id: int | str | None) -> JsonRpcResponse:
        if not self._initialized:
            return _jsonrpc_error(msg_id, -32002, "Server not initialized")

        tools = [
            _tool_to_descriptor(tool)
            for tool in self._registry.list()
            if should_expose_tool(tool)
        ]
        return _jsonrpc_result(msg_id, {"tools": tools})

    def _handle_tools_call(
        self, msg_id: int | str | None, params: dict[str, Any]
    ) -> JsonRpcResponse:
        if not self._initialized:
            return _jsonrpc_error(msg_id, -32002, "Server not initialized")

        name = params.get("name")
        if not isinstance(name, str):
            return _jsonrpc_error(msg_id, -32602, "tools/call requires a string name")

        raw_args = params.get("arguments") if "arguments" in params else params.get("args")
        try:
            args = _coerce_arguments(raw_args)
        except ValueError as exc:
            return _jsonrpc_error(msg_id, -32602, str(exc))

        try:
            result = execute_tool_capture(self._registry, name, args)
        except ToolNotFoundError:
            return _jsonrpc_error(msg_id, -32001, f"Unknown tool: {name}")
        except ToolPassthroughError:
            return _jsonrpc_error(
                msg_id,
                -32001,
                f"Tool '{name}' requires an interactive terminal and is not available.",
            )

        self._logger.log(
            "mcp-call",
            tool=name,
            args=args,
            rc=result.return_code,
            stdout_len=len(result.stdout),
            stderr_len=len(result.stderr),
        )

        payload = {
            "content": _format_content(result),
            "isError": result.return_code != 0,
            "metadata": {
                "return_code": result.return_code,
                "stderr": result.stderr,
                "args": args,
            },
        }

        return _jsonrpc_result(msg_id, payload)

    # ------------------------------------------------------------------
    # Helpers

    def _print_interactive_banner(self) -> None:
        print(
            "[pytools-mcp] Waiting for Model Context Protocol client on stdin/stdout.\n"
            "Connect an MCP-compatible assistant or run: python scripts/mcp_client_example.py\n"
            "Press Ctrl+C to exit.",
            file=sys.stderr,
        )


def _build_argument_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="pytools-mcp",
        description="Model Context Protocol server exposing PyTools commands.",
    )
    parser.add_argument(
        "--session-id",
        help="Optional session identifier for logging; defaults to a generated value.",
    )
    return parser


def main(argv: Iterable[str] | None = None) -> int:
    """Entry point for launching the MCP server over stdio."""
    parser = _build_argument_parser()
    args = parser.parse_args(list(argv) if argv is not None else None)

    registry = build_registry()
    session_id = args.session_id or f"mcp-{uuid.uuid4().hex}"
    logger = SessionLogger(session_id=session_id)
    transport = StdioTransport(reader=sys.stdin.buffer, writer=sys.stdout.buffer)
    interactive = bool(getattr(sys.stdin, "isatty", lambda: False)())
    server = MCPServer(
        registry=registry,
        logger=logger,
        transport=transport,
        interactive=interactive,
    )
    return server.serve()


if __name__ == "__main__":
    raise SystemExit(main())
