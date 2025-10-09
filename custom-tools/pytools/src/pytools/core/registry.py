"""Registry for managing pytools commands."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Callable


@dataclass
class Tool:
    """Metadata and runner for a command-line tool."""

    name: str
    summary: str
    runner: Callable[[list[str]], int]
    usage: str | None = None
    tags: list[str] = field(default_factory=list)
    safety: str = "safe"  # safe, write, destructive, interactive
    passthrough: bool = False  # whether to pass through stdout/stderr directly


class Registry:
    """Registry for managing available tools."""

    def __init__(self) -> None:
        self._tools: dict[str, Tool] = {}

    def add(self, tool: Tool) -> None:
        """Register a new tool."""
        self._tools[tool.name] = tool

    def get(self, name: str) -> Tool | None:
        """Retrieve a tool by name."""
        return self._tools.get(name)

    def list(self) -> list[Tool]:
        """Return all tools sorted by name."""
        return sorted(self._tools.values(), key=lambda t: t.name)

    def names(self) -> list[str]:
        """Return all tool names sorted."""
        return sorted(self._tools.keys())
