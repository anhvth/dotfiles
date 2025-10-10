"""Tests for shared executor helpers."""

import sys

import pytest

from pytools.core.executor import (
    ToolExecutionResult,
    ToolNotFoundError,
    ToolPassthroughError,
    execute_tool_capture,
    should_expose_tool,
)
from pytools.core.registry import Registry, Tool


def _build_registry_with_tool(
    name: str, summary: str, runner, safety: str = "safe", passthrough: bool = False
) -> Registry:
    reg = Registry()
    reg.add(
        Tool(
            name=name,
            summary=summary,
            runner=runner,
            safety=safety,
            passthrough=passthrough,
        )
    )
    return reg


def test_execute_tool_capture_captures_stdout_and_stderr():
    """execute_tool_capture should collect stdout/stderr streams."""

    def runner(args):
        print("stdout:", ",".join(args))
        print("oops", file=sys.stderr)
        return 5

    reg = _build_registry_with_tool("dummy", "Dummy tool", runner)
    result = execute_tool_capture(reg, "dummy", ["a", "b"])
    assert isinstance(result, ToolExecutionResult)
    assert "stdout: a,b" in result.stdout
    assert "oops" in result.stderr
    assert result.return_code == 5


def test_execute_tool_capture_unknown_tool_raises():
    reg = Registry()
    with pytest.raises(ToolNotFoundError):
        execute_tool_capture(reg, "missing", [])


def test_execute_tool_capture_passthrough_rejected():
    reg = _build_registry_with_tool(
        "interactive", "Interactive tool", lambda args: 0, passthrough=True
    )
    with pytest.raises(ToolPassthroughError):
        execute_tool_capture(reg, "interactive", [])


def test_should_expose_tool_filters_passthrough_and_destructive():
    safe_tool = Tool(name="safe", summary="safe", runner=lambda a: 0)
    destructive_tool = Tool(
        name="danger", summary="danger", runner=lambda a: 0, safety="destructive"
    )
    passthrough_tool = Tool(
        name="interact", summary="interactive", runner=lambda a: 0, passthrough=True
    )

    assert should_expose_tool(safe_tool) is True
    assert should_expose_tool(destructive_tool) is False
    assert should_expose_tool(passthrough_tool) is False
