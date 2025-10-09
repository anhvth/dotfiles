from __future__ import annotations

import argparse
import difflib
import importlib
import io
import sys
from contextlib import redirect_stdout, redirect_stderr
from typing import Callable, List, Optional

from rich.console import Console
from rich.panel import Panel
from rich.table import Table

from .core.registry import Registry, Tool
from .core.session import SessionLogger


console = Console()


def _run_module_main(
    main_func: Callable[[], int], prog: str, args: List[str], capture: bool
) -> tuple[int, str, str]:
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
    except SystemExit as e:
        code = int(e.code) if isinstance(e.code, int) else 1
    except Exception as e:  # noqa: BLE001
        stderr_buf.write(f"Unhandled error: {e}\n")
        code = 1
    finally:
        sys.argv = orig_argv
    return code, stdout_buf.getvalue(), stderr_buf.getvalue()


def build_registry() -> Registry:
    reg = Registry()

    # lsh
    from . import lsh as _lsh

    reg.add(
        Tool(
            name="lsh",
            summary="Execute commands in parallel with tmux and CPU/GPU assignment",
            runner=lambda a: _run_module_main(_lsh.main, "lsh", a, capture=False)[0],
            usage="lsh <commands.txt> <num_workers> [--name NAME] [--gpus 0,1] [--dry-run]",
            tags=["system", "tmux", "parallel"],
            safety="interactive",
            passthrough=True,
        )
    )

    # hf-down
    from . import hf_down as _hf

    reg.add(
        Tool(
            name="hf-down",
            summary="Download files from Hugging Face (url transform included)",
            runner=lambda a: _run_module_main(_hf.main, "hf-down", a, capture=True)[0],
            usage="hf-down <URL> [SAVE_NAME]",
            tags=["network", "download"],
            safety="write",
        )
    )

    # cat-projects
    from . import cat_projects as _cat

    reg.add(
        Tool(
            name="cat-projects",
            summary="Create code snapshots for LLMs",
            runner=lambda a: _run_module_main(
                _cat.main, "cat-projects", a, capture=True
            )[0],
            usage="cat-projects <paths...> [-e .py,.js] [--summarise]",
            tags=["dev", "snapshot"],
            safety="safe",
        )
    )

    # print-ipv4
    from . import print_ipv4 as _ipv4

    reg.add(
        Tool(
            name="print-ipv4",
            summary="Display public IPv4 address",
            runner=lambda a: _run_module_main(
                _ipv4.main, "print-ipv4", a, capture=True
            )[0],
            usage="print-ipv4",
            tags=["network"],
            safety="safe",
        )
    )

    # organize-downloads
    from . import organize_downloads as _org

    reg.add(
        Tool(
            name="organize-downloads",
            summary="Organize Downloads by creation date (moves files)",
            runner=lambda a: _run_module_main(
                _org.main, "organize-downloads", a, capture=True
            )[0],
            usage="organize-downloads [~/Downloads]",
            tags=["system", "fs"],
            safety="destructive",
        )
    )

    # kill-process-grep
    from . import kill_process_grep as _kpg

    reg.add(
        Tool(
            name="kill-process-grep",
            summary="Interactive process killer with fzf",
            runner=lambda a: _run_module_main(
                _kpg.main, "kill-process-grep", a, capture=False
            )[0],
            usage="kill-process-grep",
            tags=["system", "fzf"],
            safety="interactive",
            passthrough=True,
        )
    )

    # utilities in cli_utils
    from . import cli_utils as _utils

    reg.add(
        Tool(
            name="pyinit",
            summary="Initialize a Python project with VSCode settings",
            runner=lambda a: _run_module_main(_utils.pyinit, "pyinit", a, capture=True)[
                0
            ],
            usage="pyinit <name> [--venv]",
            tags=["dev", "scaffold"],
            safety="write",
        )
    )

    reg.add(
        Tool(
            name="keep-ssh",
            summary="Keep SSH connections alive",
            runner=lambda a: _run_module_main(
                _utils.keep_ssh, "keep-ssh", a, capture=False
            )[0],
            usage="keep-ssh user@host [--interval 60] [--verbose]",
            tags=["network", "ssh"],
            safety="interactive",
            passthrough=True,
        )
    )

    reg.add(
        Tool(
            name="atv-select",
            summary="Select and activate a venv from history (fzf)",
            runner=lambda a: _run_module_main(
                _utils.atv_select, "atv-select", a, capture=False
            )[0],
            usage="atv-select [--help-venv]",
            tags=["venv", "fzf"],
            safety="interactive",
            passthrough=True,
        )
    )

    return reg


def render_tools(reg: Registry) -> None:
    table = Table(title="PyTools – Available Commands", show_lines=False)
    table.add_column("Name", style="bold cyan")
    table.add_column("Summary")
    table.add_column("Safety")
    table.add_column("Tags")
    for t in reg.list():
        table.add_row(t.name, t.summary, t.safety, ",".join(t.tags))
    console.print(table)


def run_tool(reg: Registry, logger: SessionLogger, name: str, args: List[str]) -> int:
    tool = reg.get(name)
    if not tool:
        console.print(f"[red]Unknown tool:[/red] {name}")
        return 1
    logger.log("invoke", tool=name, args=args)

    if tool.passthrough:
        code = tool.runner(args)
        logger.log("result", tool=name, rc=code)
        return code

    # capture output for nice rendering
    # Re-run using module import path via helper in build_registry
    # The runner returns only rc when capture=True; re-run a parallel capture here
    # by importing module again and invoking with capture to obtain buffers.
    # To avoid duplicating import, we wrap with a small hack: rebind to _run_module_main.
    # Instead, call the module directly by name if available.
    # As our runner with capture already returns rc only, replicate capture locally.

    # Approach: temporarily patch runner to return rc,stdout,stderr by introspection is fragile;
    # easier: call again using known modules through registry. For simplicity, just invoke runner
    # while redirecting global stdout/stderr (already supported when capture=True in registry setup).

    # We rebuild capture by importing name→module map for known tools
    # Fallback to simply running and not capturing if unsupported
    try:
        # Map names to module main functions for capture
        module_map = {
            "hf-down": (importlib.import_module("pytools.hf_down").main, "hf-down"),
            "cat-projects": (
                importlib.import_module("pytools.cat_projects").main,
                "cat-projects",
            ),
            "print-ipv4": (
                importlib.import_module("pytools.print_ipv4").main,
                "print-ipv4",
            ),
            "organize-downloads": (
                importlib.import_module("pytools.organize_downloads").main,
                "organize-downloads",
            ),
            "pyinit": (importlib.import_module("pytools.cli_utils").pyinit, "pyinit"),
        }
        if name in module_map:
            main_func, prog = module_map[name]
            rc, out, err = _run_module_main(main_func, prog, args, capture=True)
            if out:
                console.print(
                    Panel.fit(out, title=f"{name} output", border_style="green")
                )
            if err:
                console.print(
                    Panel.fit(err, title=f"{name} stderr", border_style="yellow")
                )
            logger.log("result", tool=name, rc=rc, stdout=out, stderr=err)
            return rc
        # default passthrough
        code = tool.runner(args)
        logger.log("result", tool=name, rc=code)
        return code
    except Exception as e:  # noqa: BLE001
        console.print(f"[red]Failed to run {name}:[/red] {e}")
        logger.log("error", tool=name, error=str(e))
        return 1


def interactive_loop(reg: Registry, logger: SessionLogger) -> int:
    # Try prompt_toolkit, fallback to input()
    try:
        from prompt_toolkit import PromptSession
        from prompt_toolkit.completion import WordCompleter
        from prompt_toolkit.history import InMemoryHistory

        completer = WordCompleter(
            reg.names() + ["help", "list", "run", "exit", "quit"], ignore_case=True
        )
        session = PromptSession(history=InMemoryHistory())

        console.print(
            Panel(
                "Welcome to PyTools interactive mode. Type 'list' or 'help'.",
                title="PyTools",
                border_style="cyan",
            )
        )
        while True:
            try:
                text = session.prompt("pytools> ", completer=completer)
            except (EOFError, KeyboardInterrupt):
                console.print("Goodbye!")
                return 0
            cmd = text.strip()
            if not cmd:
                continue
            if cmd in ("exit", "quit"):
                return 0
            if cmd == "list":
                render_tools(reg)
                continue
            if cmd.startswith("help"):
                parts = cmd.split()
                if len(parts) == 1:
                    render_tools(reg)
                else:
                    t = reg.get(parts[1])
                    if t:
                        console.print(
                            Panel(
                                f"{t.summary}\n\nUsage: {t.usage or t.name}",
                                title=t.name,
                                border_style="blue",
                            )
                        )
                    else:
                        console.print(f"Unknown tool: {parts[1]}")
                continue
            if cmd.startswith("run "):
                _, *rest = cmd.split()
                if not rest:
                    console.print("Usage: run <tool> [args...]")
                    continue
                name = rest[0]
                args = rest[1:]
                rc = run_tool(reg, logger, name, args)
                if rc != 0:
                    console.print(f"[red]Return code:[/red] {rc}")
                continue

            # free text: fuzzy match first token to a tool name
            parts = cmd.split()
            name = parts[0]
            args = parts[1:]
            if reg.get(name) is None:
                match = difflib.get_close_matches(name, reg.names(), n=1)
                if match:
                    console.print(f"Assuming you meant: [bold]{match[0]}[/bold]")
                    name = match[0]
                else:
                    console.print(f"Unknown command: {name}")
                    continue
            rc = run_tool(reg, logger, name, args)
            if rc != 0:
                console.print(f"[red]Return code:[/red] {rc}")
    except Exception:
        # basic loop
        console.print("Prompt toolkit unavailable, falling back to basic mode.")
        print("Type 'list' to see tools. 'exit' to quit.")
        while True:
            try:
                cmd = input("pytools> ").strip()
            except (EOFError, KeyboardInterrupt):
                print("Goodbye!")
                return 0
            if not cmd:
                continue
            if cmd in ("exit", "quit"):
                return 0
            if cmd == "list":
                render_tools(reg)
                continue
            parts = cmd.split()
            name = parts[0]
            args = parts[1:]
            if reg.get(name) is None:
                print(f"Unknown command: {name}")
                continue
            run_tool(reg, logger, name, args)


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(
        prog="pytools", description="Unified interactive CLI for pytools"
    )
    sub = parser.add_subparsers(dest="cmd")

    sub.add_parser("list", help="List available tools")

    p_run = sub.add_parser("run", help="Run a tool directly")
    p_run.add_argument("tool")
    p_run.add_argument("args", nargs=argparse.REMAINDER)

    sub.add_parser("interactive", help="Start interactive session (default)")

    args = parser.parse_args(argv)
    reg = build_registry()
    logger = SessionLogger()

    if args.cmd == "list":
        render_tools(reg)
        return 0
    if args.cmd == "run":
        return run_tool(reg, logger, args.tool, list(args.args))

    # default: interactive
    return interactive_loop(reg, logger)


if __name__ == "__main__":
    raise SystemExit(main())
