"""Tests for the MCP server integration."""

from __future__ import annotations

from typing import Any

from pytools.core.registry import Registry, Tool
from pytools.mcp.server import MCPServer


class DummyTransport:
    def __init__(self) -> None:
        self.notifications: list[tuple[str, dict[str, Any] | None]] = []

    def read_message(self):
        raise NotImplementedError

    def send(self, payload: dict[str, Any]) -> None:  # pragma: no cover - not used
        self.notifications.append(("send", payload))

    def notify(self, method: str, params: dict[str, Any] | None = None) -> None:
        self.notifications.append((method, params))


class DummyLogger:
    def __init__(self) -> None:
        self.events: list[tuple[str, dict[str, Any]]] = []

    def log(self, event_type: str, **kwargs: Any) -> None:
        self.events.append((event_type, kwargs))


def _build_registry() -> Registry:
    reg = Registry()
    reg.add(Tool(name="safe", summary="Safe tool", runner=lambda args: 0))
    reg.add(
        Tool(
            name="danger",
            summary="Dangerous",
            runner=lambda args: 0,
            safety="destructive",
        )
    )
    return reg


def test_initialize_reports_capabilities_and_notifies():
    registry = _build_registry()
    transport = DummyTransport()
    logger = DummyLogger()
    server = MCPServer(registry=registry, logger=logger, transport=transport)

    response = server._handle_initialize(1, {"clientInfo": {"name": "test"}})
    assert response.payload["result"]["protocolVersion"] == "0.1.0"
    notifications = {method: params for method, params in transport.notifications}
    assert "initialized" in notifications
    assert notifications["initialized"]["clientInfo"] == {"name": "test"}


def test_tools_list_filters_unexposed_tools():
    registry = _build_registry()
    transport = DummyTransport()
    logger = DummyLogger()
    server = MCPServer(registry=registry, logger=logger, transport=transport)
    server._handle_initialize(1, {})

    response = server._handle_tools_list(2)
    tool_names = [tool["name"] for tool in response.payload["result"]["tools"]]
    assert tool_names == ["safe"]


def test_tools_call_executes_and_returns_output():
    def runner(args):
        print("hello")
        return 0

    registry = Registry()
    registry.add(Tool(name="echo", summary="Echo", runner=runner))
    transport = DummyTransport()
    logger = DummyLogger()
    server = MCPServer(registry=registry, logger=logger, transport=transport)
    server._handle_initialize(1, {})

    response = server._handle_tools_call(3, {"name": "echo", "arguments": []})
    assert response.payload["result"]["isError"] is False
    content = response.payload["result"]["content"]
    assert content and "hello" in content[0]["text"]
    assert logger.events and logger.events[0][0] == "mcp-call"


def test_tools_call_unknown_tool_returns_error():
    registry = Registry()
    transport = DummyTransport()
    logger = DummyLogger()
    server = MCPServer(registry=registry, logger=logger, transport=transport)
    server._handle_initialize(1, {})

    response = server._handle_tools_call(4, {"name": "missing"})
    assert "error" in response.payload
    assert response.payload["error"]["code"] == -32001
