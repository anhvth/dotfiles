"""Tests for the PyTools registry and CLI."""

from pytools.cli import build_registry
from pytools.core.registry import Registry, Tool


def dummy_runner(args):
    """Dummy runner for testing."""
    return 0


def test_registry_add_get():
    """Test adding and retrieving tools from registry."""
    reg = Registry()
    tool = Tool(
        name="test-tool",
        summary="A test tool",
        runner=dummy_runner,
        usage="test-tool [args]",
        tags=["test"],
        safety="safe",
    )
    reg.add(tool)

    retrieved = reg.get("test-tool")
    assert retrieved is not None
    assert retrieved.name == "test-tool"
    assert retrieved.summary == "A test tool"


def test_registry_list():
    """Test listing tools in registry."""
    reg = Registry()
    reg.add(Tool(name="tool1", summary="Tool 1", runner=dummy_runner))
    reg.add(Tool(name="tool2", summary="Tool 2", runner=dummy_runner))

    tools = reg.list()
    assert len(tools) == 2
    assert tools[0].name == "tool1"
    assert tools[1].name == "tool2"


def test_registry_names():
    """Test getting tool names from registry."""
    reg = Registry()
    reg.add(Tool(name="alpha", summary="Alpha", runner=dummy_runner))
    reg.add(Tool(name="beta", summary="Beta", runner=dummy_runner))

    names = reg.names()
    assert names == ["alpha", "beta"]


def test_registry_get_nonexistent():
    """Test getting non-existent tool returns None."""
    reg = Registry()
    tool = reg.get("nonexistent")
    assert tool is None


def test_build_registry():
    """Test building the full registry."""
    reg = build_registry()

    # Check some expected tools are registered
    expected_tools = [
        "cat-projects",
        "pyinit",
        "organize-downloads",
        "print-ipv4",
        "hf-down",
        "lsh",
        "kill-process-grep",
        "keep-ssh",
        "atv-select",
        "env-set",
        "env-unset",
        "env-list",
        "setup-typing",
        "report-error",
    ]

    tool_names = reg.names()
    for tool_name in expected_tools:
        assert tool_name in tool_names, f"Tool {tool_name} not found in registry"


def test_registry_tools_have_required_fields():
    """Test that all tools have required metadata."""
    reg = build_registry()

    for tool in reg.list():
        assert tool.name
        assert tool.summary
        assert tool.runner
        assert tool.safety in ["safe", "write", "destructive", "interactive"]
        assert isinstance(tool.tags, list)
