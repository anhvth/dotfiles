from __future__ import annotations

import argparse
import json
import os
import py_compile
import shutil
import subprocess
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

import yaml

UV_INSTALL_HINT = "Install uv: https://github.com/astral-sh/uv"

DEFAULT_USER_CONFIG_NAME = "improve-code.yaml"
DEFAULT_TEMPLATE_CONFIG_NAME = "improve_code.default.yaml"


@dataclass(frozen=True)
class RuffViolation:
    path: Path
    code: str
    message: str
    line: str


@dataclass(frozen=True)
class ImproveCodeConfig:
    target: str
    logs_dir: str
    excluded_parts: tuple[str, ...]


def default_template_config_path() -> Path:
    return Path(__file__).resolve().with_name(DEFAULT_TEMPLATE_CONFIG_NAME)


def ensure_user_config_exists(*, root: Path, config_path: Path) -> None:
    if config_path.exists():
        return

    template = default_template_config_path()
    if not template.is_file():
        raise FileNotFoundError(
            f"Missing default config template: {template}. "
            "Reinstall the package or restore the template file."
        )

    config_path.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(template, config_path)
    print("")
    print(f"Created default config at: {config_path}")
    print("Edit this file to customize improve-code behavior.")
    print("")


def load_config(*, config_path: Path) -> ImproveCodeConfig:
    raw_text = config_path.read_text(encoding="utf-8")
    payload = yaml.safe_load(raw_text)
    if payload is None:
        payload = {}
    if not isinstance(payload, dict):
        raise TypeError(f"Config must be a YAML mapping (dict), got: {type(payload).__name__}")

    target = payload.get("target")
    logs_dir = payload.get("logs_dir")
    excluded_parts = payload.get("excluded_parts")

    if not isinstance(target, str) or target.strip() == "":
        raise TypeError("Config field 'target' must be a non-empty string")
    if not isinstance(logs_dir, str) or logs_dir.strip() == "":
        raise TypeError("Config field 'logs_dir' must be a non-empty string")

    if not isinstance(excluded_parts, list) or not all(isinstance(x, str) for x in excluded_parts):
        raise TypeError("Config field 'excluded_parts' must be a list of strings")

    cleaned_excluded = tuple(x for x in excluded_parts if x.strip() != "")
    return ImproveCodeConfig(target=target, logs_dir=logs_dir, excluded_parts=cleaned_excluded)


def find_project_root(start: Path) -> Path:
    current = start.resolve()

    for candidate in (current, *current.parents):
        if (candidate / "pyproject.toml").is_file():
            return candidate

    for candidate in (current, *current.parents):
        if (candidate / ".git").exists():
            return candidate

    return current


def iter_python_files(root: Path, *, excluded_parts: set[str]) -> list[Path]:
    python_files: list[Path] = []
    for path in root.rglob("*.py"):
        if excluded_parts.intersection(path.parts):
            continue
        python_files.append(path)
    return python_files


def _run_subprocess(
    cmd: list[str], *, cwd: Path, capture: bool
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        cmd,
        cwd=str(cwd),
        text=True,
        capture_output=capture,
        check=False,
        env={**os.environ},
    )


def _looks_like_missing_tool(result: subprocess.CompletedProcess[str]) -> bool:
    stderr = (result.stderr or "").lower()
    # uv error strings vary; keep this broad-but-safe.
    needles = [
        "failed to spawn",
        "no such file",
        "not found",
        "could not find",
        "unknown command",
    ]
    return result.returncode != 0 and any(n in stderr for n in needles)


def run_ruff(*args: str, cwd: Path, capture: bool = False) -> subprocess.CompletedProcess[str]:
    if shutil.which("uv") is None:
        raise FileNotFoundError(f"uv is required to run ruff. {UV_INSTALL_HINT}")

    # Prefer running in-project environment first (if available).
    result = _run_subprocess(["uv", "run", "ruff", *args], cwd=cwd, capture=capture)
    if not _looks_like_missing_tool(result):
        return result

    # Fallback: run ruff as a uv-managed tool (works even if the project doesn't declare ruff).
    if shutil.which("uvx") is not None:
        return _run_subprocess(["uvx", "ruff", *args], cwd=cwd, capture=capture)

    return _run_subprocess(["uv", "tool", "run", "ruff", *args], cwd=cwd, capture=capture)


def ruff_check_json(root: Path, target: Path) -> list[dict]:
    result = run_ruff(
        "check",
        "--output-format",
        "json",
        str(target),
        cwd=root,
        capture=True,
    )

    # ruff returns non-zero when it finds issues; that's expected.
    if result.stdout.strip() == "":
        if result.returncode != 0:
            detail = (result.stderr or "").strip() or "ruff failed"
            raise RuntimeError(f"ruff execution failed: {detail}")
        return []

    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        msg = "\n".join(
            [
                "Could not parse ruff JSON output.",
                "--- stdout ---",
                result.stdout,
                "--- stderr ---",
                result.stderr or "",
            ]
        )
        raise RuntimeError(msg) from exc

    if not isinstance(payload, list):
        raise TypeError("Expected ruff JSON output to be a list")
    return payload


def parse_ruff_violations(
    raw: list[dict], project_root: Path
) -> tuple[list[RuffViolation], list[RuffViolation]]:
    errors: list[RuffViolation] = []
    warnings: list[RuffViolation] = []

    for item in raw:
        filename = str(item.get("filename", ""))
        code = str(item.get("code", ""))
        message = str(item.get("message", ""))

        location = item.get("location") or {}
        row = location.get("row")
        line = str(row) if row is not None else "?"

        try:
            path = Path(filename)
            if path.is_absolute():
                path = path.relative_to(project_root)
        except Exception:
            path = Path(filename) if filename else Path("?")

        violation = RuffViolation(path=path, code=code, message=message, line=line)

        if code.startswith(("E", "F")):
            errors.append(violation)
        else:
            warnings.append(violation)

    return errors, warnings


def format_violations_by_file(violations: list[RuffViolation]) -> dict[Path, list[RuffViolation]]:
    grouped: dict[Path, list[RuffViolation]] = {}
    for v in violations:
        grouped.setdefault(v.path, []).append(v)
    return dict(sorted(grouped.items(), key=lambda kv: str(kv[0])))


def collect_syntax_errors(python_files: list[Path]) -> list[tuple[Path, str]]:
    errors: list[tuple[Path, str]] = []
    for path in python_files:
        try:
            py_compile.compile(str(path), doraise=True)
        except Exception as exc:
            errors.append((path, str(exc)))
    return errors


def collect_lint(
    *, root: Path, target: Path
) -> tuple[str | None, list[RuffViolation], list[RuffViolation]]:
    try:
        raw = ruff_check_json(root, target)
    except Exception as exc:
        return str(exc), [], []

    errors, warnings = parse_ruff_violations(raw, project_root=root)
    return None, errors, warnings


def render_header(*, root: Path, python_files_count: int) -> list[str]:
    now = datetime.now().isoformat()
    return [
        "# Code Quality Report",
        f"- Generated: {now}",
        f"- Root: {root}",
        f"- Files scanned: {python_files_count}",
        "",
    ]


def render_syntax_section(*, root: Path, syntax_errors: list[tuple[Path, str]]) -> list[str]:
    lines: list[str] = ["## Syntax Validation"]
    if not syntax_errors:
        lines.extend(["✅ No syntax errors detected", ""])
        return lines

    lines.extend([f"❌ Found {len(syntax_errors)} syntax error(s):", ""])
    for path, message in syntax_errors:
        lines.extend([f"### {path.relative_to(root)}", "```", message, "```", ""])
    return lines


def render_lint_section(
    *,
    lint_tool_error: str | None,
    lint_errors: list[RuffViolation],
    lint_warnings: list[RuffViolation],
) -> list[str]:
    lines: list[str] = ["## Linting Issues"]

    if lint_tool_error is not None:
        lines.extend(
            [
                "❌ Could not run ruff to compute lint issues:",
                "",
                f"- {lint_tool_error}",
                "",
            ]
        )

    if lint_errors:
        lines.extend([f"❌ Found {len(lint_errors)} linting error(s):", ""])
        for path, items in format_violations_by_file(lint_errors).items():
            lines.append(f"### {path}")
            for v in items:
                lines.append(f"- **Line {v.line}** [{v.code}]: {v.message}")
            lines.append("")
    else:
        lines.extend(["✅ No critical linting errors", ""])

    if lint_warnings:
        lines.extend([f"⚠️  Found {len(lint_warnings)} linting warning(s):", ""])
        for path, items in format_violations_by_file(lint_warnings).items():
            lines.append(f"### {path}")
            for v in items:
                lines.append(f"- **Line {v.line}** [{v.code}]: {v.message}")
            lines.append("")
    else:
        lines.extend(["✅ No linting warnings", ""])

    return lines


def compute_total_issues(
    *,
    syntax_errors: list[tuple[Path, str]],
    lint_errors: list[RuffViolation],
    lint_warnings: list[RuffViolation],
    lint_tool_error: str | None,
) -> int:
    total = len(syntax_errors) + len(lint_errors) + len(lint_warnings)
    if lint_tool_error is not None:
        total += 1
    return total


def render_summary_section(
    *,
    syntax_error_count: int,
    lint_error_count: int,
    lint_warning_count: int,
    total_issues: int,
) -> tuple[list[str], int]:
    lines: list[str] = [
        "## Summary",
        f"- **Syntax Errors**: {syntax_error_count}",
        f"- **Lint Errors**: {lint_error_count}",
        f"- **Lint Warnings**: {lint_warning_count}",
        f"- **Total Issues**: {total_issues}",
        "",
    ]

    if total_issues == 0:
        lines.append("🎉 **All checks passed! Code is clean.**")
        return lines, 0

    lines.append("⚠️  **Manual fixes required for the issues above.**")
    return lines, 1


def build_report_markdown(*, root: Path, python_files: list[Path], target: Path) -> tuple[str, int]:
    syntax_errors = collect_syntax_errors(python_files)
    lint_tool_error, lint_errors, lint_warnings = collect_lint(root=root, target=target)

    parts: list[str] = []
    parts.extend(render_header(root=root, python_files_count=len(python_files)))
    parts.extend(render_syntax_section(root=root, syntax_errors=syntax_errors))
    parts.extend(
        render_lint_section(
            lint_tool_error=lint_tool_error,
            lint_errors=lint_errors,
            lint_warnings=lint_warnings,
        )
    )

    total_issues = compute_total_issues(
        syntax_errors=syntax_errors,
        lint_errors=lint_errors,
        lint_warnings=lint_warnings,
        lint_tool_error=lint_tool_error,
    )
    summary_lines, exit_code = render_summary_section(
        syntax_error_count=len(syntax_errors),
        lint_error_count=len(lint_errors),
        lint_warning_count=len(lint_warnings),
        total_issues=total_issues,
    )
    parts.extend(summary_lines)

    return "\n".join(parts) + "\n", exit_code


def cmd_format(*, root: Path, target: Path) -> int:
    print("Formatting with ruff...")
    result = run_ruff("format", str(target), cwd=root, capture=False)
    return result.returncode


def cmd_fix(*, root: Path, target: Path) -> int:
    print("Auto-fixing with ruff...")
    result = run_ruff("check", "--fix", str(target), cwd=root, capture=False)
    return result.returncode


def cmd_report(
    *, root: Path, logs_dir: Path, command_name: str, python_files: list[Path], target: Path
) -> int:
    logs_dir.mkdir(parents=True, exist_ok=True)

    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    report_path = logs_dir / f"{command_name}_{ts}.md"

    md, exit_code = build_report_markdown(
        root=root,
        python_files=python_files,
        target=target,
    )

    report_path.write_text(md, encoding="utf-8")
    print(md, end="")

    if exit_code == 0:
        print(f"Report saved to: {report_path}")
    else:
        print(f"Issues found. Report saved to: {report_path}")

    return exit_code


def cmd_view(*, logs_dir: Path) -> int:
    if not logs_dir.exists():
        print(f"No reports found in {logs_dir}")
        return 1

    improve = sorted(logs_dir.glob("improve_*.md"), reverse=True)
    report = sorted(logs_dir.glob("report_*.md"), reverse=True)

    candidates = [*improve[:1], *report[:1]]
    if not candidates:
        print(f"No reports found in {logs_dir}")
        return 1

    latest = sorted(candidates, reverse=True)[0]
    print(f"Showing: {latest}")
    print("")
    print(latest.read_text(encoding="utf-8"), end="")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="improve-code",
        description="Format, auto-fix, and report code quality using ruff.",
    )
    parser.add_argument(
        "command",
        nargs="?",
        default="improve",
        choices=["improve", "format", "report", "view"],
        help="Command to run (default: improve)",
    )
    parser.add_argument(
        "--config",
        default=None,
        help=(
            "Path to improve-code YAML config. "
            f"Default: {DEFAULT_USER_CONFIG_NAME} at project root."
        ),
    )
    parser.add_argument(
        "--target",
        default=None,
        help="Path to check/format (overrides config 'target')",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    root = find_project_root(Path.cwd())

    if args.config is None:
        config_path = (root / DEFAULT_USER_CONFIG_NAME).resolve()
        ensure_user_config_exists(root=root, config_path=config_path)
    else:
        config_path = Path(args.config).expanduser()
        if not config_path.is_absolute():
            config_path = (root / config_path).resolve()
        if not config_path.is_file():
            raise FileNotFoundError(f"Config file not found: {config_path}")

    config = load_config(config_path=config_path)

    target_str = args.target if args.target is not None else config.target
    target = (root / target_str).resolve()

    logs_dir_cfg = Path(config.logs_dir)
    logs_dir = logs_dir_cfg if logs_dir_cfg.is_absolute() else (root / logs_dir_cfg)
    logs_dir = logs_dir.resolve()

    excluded_parts = set(config.excluded_parts)
    python_files = iter_python_files(root, excluded_parts=excluded_parts)

    if args.command == "format":
        return cmd_format(root=root, target=target)

    if args.command == "report":
        return cmd_report(
            root=root,
            logs_dir=logs_dir,
            command_name="report",
            python_files=python_files,
            target=target,
        )

    if args.command == "view":
        return cmd_view(logs_dir=logs_dir)

    # improve (default)
    print("Running automated code improvements...")

    format_rc = cmd_format(root=root, target=target)
    if format_rc != 0:
        print("Formatting had issues (continuing...)")

    fix_rc = cmd_fix(root=root, target=target)
    if fix_rc != 0:
        print("Some issues could not be auto-fixed (continuing...)")

    return cmd_report(
        root=root,
        logs_dir=logs_dir,
        command_name="improve",
        python_files=python_files,
        target=target,
    )
