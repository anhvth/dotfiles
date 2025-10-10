"""Shared execution helpers for running pytools registry commands."""

from __future__ import annotations

import importlib
import io
from contextlib import redirect_stderr, redirect_stdout
from dataclasses import dataclass
from typing import Callable

from .registry import Registry, Tool


@dataclass
class ToolExecutionResult:
    """Result from executing a registry tool."""

    return_code: int
    stdout: str
    stderr: str


class ToolNotFoundError(ValueError):
    """Raised when a requested tool is not present in the registry."""


class ToolPassthroughError(RuntimeError):
    """Raised when attempting to capture output for a passthrough tool."""


def run_module_main(
    main_func: Callable[[], int], prog: str, args: list[str], capture: bool
) -> tuple[int, str, str]:
    """Execute a module-style ``main`` and optionally capture stdio."""
    import sys

    orig_argv = sys.argv[:]
    sys.argv = [prog] + args
    stdout_buf: io.StringIO = io.StringIO()
    stderr_buf: io.StringIO = io.StringIO()
    try:
        if capture:
            with redirect_stdout(stdout_buf), redirect_stderr(stderr_buf):
                code = int(main_func())
        else:
            code = int(main_func())
    except SystemExit as exc:
        code = int(exc.code) if isinstance(exc.code, int) else 1
    except Exception as exc:  # noqa: BLE001
        stderr_buf.write(f"Unhandled error: {exc}\n")
        code = 1
    finally:
        sys.argv = orig_argv
    return code, stdout_buf.getvalue(), stderr_buf.getvalue()


_MODULE_OVERRIDES: dict[str, tuple[str, str, str]] = {
    # tool_name: (module_path, attribute_name, program_name)
    "hf-down": ("pytools.hf_down", "main", "hf-down"),
    "cat-projects": ("pytools.cat_projects", "main", "cat-projects"),
    "print-ipv4": ("pytools.print_ipv4", "main", "print-ipv4"),
    "organize-downloads": ("pytools.organize_downloads", "main", "organize-downloads"),
    "pyinit": ("pytools.cli_utils", "pyinit", "pyinit"),
    "env-set": ("pytools.env_commands", "main_set", "env-set"),
    "env-unset": ("pytools.env_commands", "main_unset", "env-unset"),
    "env-list": ("pytools.env_commands", "main_list", "env-list"),
}


def execute_tool_capture(
    registry: Registry, name: str, args: list[str]
) -> ToolExecutionResult:
    """Run a tool by name while capturing stdout and stderr.

    Returns the captured output and exit code. Raises ``ToolNotFoundError`` if the
    tool is not registered and ``ToolPassthroughError`` if the tool is marked as
    passthrough (interactive only) and therefore cannot be captured.
    """
    tool = registry.get(name)
    if tool is None:
        raise ToolNotFoundError(f"Unknown tool: {name}")
    if tool.passthrough:
        raise ToolPassthroughError(
            f"Tool '{name}' requires passthrough execution and cannot be captured."
        )

    # Some tools already expose a ``main`` function that can be run in captured mode.
    if name in _MODULE_OVERRIDES:
        module_path, attr, prog = _MODULE_OVERRIDES[name]
        module = importlib.import_module(module_path)
        main_callable = getattr(module, attr)
        rc, stdout, stderr = run_module_main(main_callable, prog, args, capture=True)
        return ToolExecutionResult(return_code=rc, stdout=stdout, stderr=stderr)

    # Fallback: run the registered runner while redirecting stdio.
    stdout_buf: io.StringIO = io.StringIO()
    stderr_buf: io.StringIO = io.StringIO()

    with redirect_stdout(stdout_buf), redirect_stderr(stderr_buf):
        rc = tool.runner(args)

    return ToolExecutionResult(
        return_code=rc, stdout=stdout_buf.getvalue(), stderr=stderr_buf.getvalue()
    )


def should_expose_tool(tool: Tool) -> bool:
    """Return True if the tool is safe to expose to automations like MCP servers."""
    if tool.passthrough:
        return False
    if tool.safety == "destructive":
        return False
    return True
