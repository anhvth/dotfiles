from __future__ import annotations

import argparse
import difflib
import importlib
import io
import shutil
import sys
from contextlib import redirect_stderr, redirect_stdout
from typing import Callable

from rich.console import Console
from rich.panel import Panel
from rich.table import Table

from . import __version__
from .core.registry import Registry, Tool
from .core.session import SessionLogger

console = Console()
_NO_COLOR = False
_JSON_OUTPUT = False


def set_global_flags(no_color: bool = False, json_output: bool = False) -> None:
    """Set global output formatting flags."""
    global _NO_COLOR, _JSON_OUTPUT, console
    _NO_COLOR = no_color
    _JSON_OUTPUT = json_output
    if no_color:
        console = Console(no_color=True, force_terminal=False)


def _run_module_main(
    main_func: Callable[[], int], prog: str, args: list[str], capture: bool
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


def _typer_app_wrapper(app, prog: str, args: list[str]) -> int:
    """Wrapper for Typer apps to match main() signature."""
    orig_argv = sys.argv[:]
    sys.argv = [prog] + args
    try:
        app()
        return 0
    except SystemExit as e:
        return int(e.code) if isinstance(e.code, int) else 1
    except Exception as e:
        sys.stderr.write(f"Error: {e}\n")
        return 1
    finally:
        sys.argv = orig_argv


def check_dependency(cmd: str) -> bool:
    """Check if a command is available in PATH."""
    return shutil.which(cmd) is not None


def check_dependencies() -> dict[str, dict[str, str | bool]]:
    """Check all external dependencies and return status."""
    deps = {
        "fzf": {
            "required_by": ["kill-process-grep", "atv-select"],
            "install": "https://github.com/junegunn/fzf#installation",
        },
        "tmux": {
            "required_by": ["lsh"],
            "install": "apt install tmux / brew install tmux",
        },
        "wget": {
            "required_by": ["hf-down"],
            "install": "apt install wget / brew install wget",
        },
        "pyright": {
            "required_by": ["report-error"],
            "install": "npm install -g pyright",
        },
    }

    results = {}
    for cmd, info in deps.items():
        results[cmd] = {
            "available": check_dependency(cmd),
            "required_by": ", ".join(info["required_by"]),
            "install": info["install"],
        }
    return results


def run_doctor() -> int:
    """Check system dependencies and provide remediation guidance."""
    console.print(Panel("PyTools Dependency Check", border_style="cyan", expand=False))

    deps = check_dependencies()

    table = Table(title="Dependency Status", show_lines=False)
    table.add_column("Tool", style="bold")
    table.add_column("Status")
    table.add_column("Required By")
    table.add_column("Install Guide")

    all_good = True
    for cmd, info in deps.items():
        status = (
            "[green]✓ Available[/green]"
            if info["available"]
            else "[red]✗ Missing[/red]"
        )
        if not info["available"]:
            all_good = False
        table.add_row(cmd, status, str(info["required_by"]), str(info["install"]))

    console.print(table)

    # Check Python environment
    console.print("\n[bold]Python Environment:[/bold]")
    console.print(f"  Python: {sys.version.split()[0]}")
    console.print(f"  Executable: {sys.executable}")

    # Check pytools installation
    try:
        import pytools

        console.print(f"  PyTools: {pytools.__version__}")
    except Exception as e:
        console.print(f"  PyTools: [red]Error - {e}[/red]")

    if all_good:
        console.print("\n[green]✓ All dependencies are available![/green]")
        return 0
    else:
        console.print("\n[yellow]⚠ Some dependencies are missing.[/yellow]")
        console.print("Install missing dependencies to use all features.")
        return 1


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

    # report-error
    from . import report_error as _rep

    reg.add(
        Tool(
            name="report-error",
            summary="Report Pylance/Pyright errors to JSON file",
            runner=lambda a: _typer_app_wrapper(_rep.app, "report-error", a),
            usage="report-error <file_path> [--output-file FILE] [--json-format] [--verbose]",
            tags=["dev", "typing"],
            safety="write",
        )
    )

    # setup-typing
    from . import setup_typing as _typing

    reg.add(
        Tool(
            name="setup-typing",
            summary="Configure typing and linting for a Python project",
            runner=lambda a: _typer_app_wrapper(_typing.app, "setup-typing", a),
            usage="setup-typing [--python-version 3.11] [--type-checking-mode basic]",
            tags=["dev", "typing", "config"],
            safety="write",
        )
    )

    # set-env
    from . import set_env as _env

    reg.add(
        Tool(
            name="set-env",
            summary="Manage KEY=VALUE entries in ~/.env",
            runner=lambda a: _run_module_main(_env.main, "set-env", a, capture=True)[0],
            usage="set-env {set KEY VALUE | unset KEY | list}",
            tags=["config", "env"],
            safety="write",
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
    """Display all available tools in a formatted table."""
    if _JSON_OUTPUT:
        import json

        tools_data = [
            {
                "name": t.name,
                "summary": t.summary,
                "usage": t.usage or t.name,
                "safety": t.safety,
                "tags": t.tags,
            }
            for t in reg.list()
        ]
        print(json.dumps(tools_data, indent=2))
        return

    table = Table(title="PyTools – Available Commands", show_lines=False)
    table.add_column("Name", style="bold cyan")
    table.add_column("Summary")
    table.add_column("Safety")
    table.add_column("Tags")
    for t in reg.list():
        table.add_row(t.name, t.summary, t.safety, ",".join(t.tags))
    console.print(table)


def run_tool(reg: Registry, logger: SessionLogger, name: str, args: list[str]) -> int:
    """Execute a tool by name with given arguments."""
    tool = reg.get(name)
    if not tool:
        console.print(f"[red]Unknown tool:[/red] {name}")
        if not _NO_COLOR:
            matches = difflib.get_close_matches(name, reg.names(), n=3)
            if matches:
                console.print(f"[yellow]Did you mean:[/yellow] {', '.join(matches)}")
        return 1

    logger.log("invoke", tool=name, args=args, safety=tool.safety)

    if tool.passthrough:
        code = tool.runner(args)
        logger.log("result", tool=name, rc=code)
        return code

    # For non-passthrough tools, capture output
    # Rebuild the execution to capture stdout/stderr
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
        "set-env": (importlib.import_module("pytools.set_env").main, "set-env"),
    }

    try:
        if name in module_map:
            main_func, prog = module_map[name]
            rc, out, err = _run_module_main(main_func, prog, args, capture=True)
            if out and not _JSON_OUTPUT:
                console.print(
                    Panel.fit(out, title=f"{name} output", border_style="green")
                )
            elif out:
                print(out, end="")
            if err:
                if not _NO_COLOR:
                    err_console = Console(stderr=True, no_color=_NO_COLOR)
                    err_console.print(
                        Panel.fit(err, title=f"{name} stderr", border_style="yellow")
                    )
                else:
                    sys.stderr.write(err)
            logger.log(
                "result", tool=name, rc=rc, stdout_len=len(out), stderr_len=len(err)
            )
            return rc

        # For Typer apps and others, just run through runner
        code = tool.runner(args)
        logger.log("result", tool=name, rc=code)
        return code
    except Exception as e:
        err_console = Console(stderr=True, no_color=_NO_COLOR)
        err_console.print(f"[red]Failed to run {name}:[/red] {e}")
        logger.log("error", tool=name, error=str(e))
        return 1


def interactive_loop(reg: Registry, logger: SessionLogger) -> int:
    """Run an interactive REPL for tool execution."""
    # Try prompt_toolkit, fallback to input()
    try:
        from prompt_toolkit import PromptSession
        from prompt_toolkit.completion import WordCompleter
        from prompt_toolkit.history import InMemoryHistory

        completer = WordCompleter(
            reg.names() + ["help", "list", "run", "exit", "quit", "doctor"],
            ignore_case=True,
        )
        session = PromptSession(history=InMemoryHistory())

        console.print(
            Panel(
                "Welcome to PyTools interactive mode. Type 'list' or 'help'.",
                title="PyTools",
                border_style="cyan",
            )
        )
        render_tools(reg)
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
            if cmd == "doctor":
                run_doctor()
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
                                f"{t.summary}\n\nUsage: {t.usage or t.name}\n\nSafety: {t.safety}\nTags: {', '.join(t.tags)}",
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
    except ImportError:
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
            if cmd == "doctor":
                run_doctor()
                continue
            parts = cmd.split()
            name = parts[0]
            args = parts[1:]
            if reg.get(name) is None:
                print(f"Unknown command: {name}")
                continue
            run_tool(reg, logger, name, args)
    return 0


def main(argv: list[str] | None = None) -> int:
    """Main CLI entry point."""
    parser = argparse.ArgumentParser(
        prog="pytools",
        description="Unified interactive CLI for pytools",
        epilog="Use 'pytools list' to see all available tools.",
    )
    parser.add_argument("--version", action="version", version=f"pytools {__version__}")
    parser.add_argument(
        "--no-color", action="store_true", help="Disable colored output"
    )
    parser.add_argument(
        "--json", action="store_true", help="Output in JSON format where applicable"
    )

    sub = parser.add_subparsers(dest="cmd")

    sub.add_parser("list", help="List available tools")
    sub.add_parser("doctor", help="Check system dependencies")

    p_run = sub.add_parser("run", help="Run a tool directly")
    p_run.add_argument("tool")
    p_run.add_argument("args", nargs=argparse.REMAINDER)

    sub.add_parser("interactive", help="Start interactive session (default)")

    args = parser.parse_args(argv)

    # Set global flags
    set_global_flags(no_color=args.no_color, json_output=args.json)

    reg = build_registry()
    logger = SessionLogger()

    if args.cmd == "list":
        render_tools(reg)
        return 0
    if args.cmd == "doctor":
        return run_doctor()
    if args.cmd == "run":
        return run_tool(reg, logger, args.tool, list(args.args))

    # default: interactive
    return interactive_loop(reg, logger)


if __name__ == "__main__":
    raise SystemExit(main())
