#!/usr/bin/env python3
"""
Cat Projects - Create a per-file snapshot of a code-base for LLMs.

This tool walks one or more directories and creates a comprehensive snapshot
of the codebase, suitable for ingestion by LLMs or diff tools.
"""

import argparse
import ast
import concurrent.futures as cf
import re
import sys
from pathlib import Path
from typing import Iterable, List, Sequence, Tuple

try:
    from loguru import logger
except ImportError:
    # Fallback to standard logging if loguru is not available
    import logging
    logger = logging.getLogger(__name__)
    logging.basicConfig(level=logging.INFO)


# Configuration
DEFAULT_EXTS: Tuple[str, ...] = (".py",)
DEFAULT_IGNORES: Tuple[str, ...] = (
    ".venv", "venv", "__pycache__", ".git", ".mypy_cache",
    ".FOLDER", "node_modules", "demo", "legacy",
)
MAX_LINE_LEN = 120

# Copilot prompt framework
PROMPT = """
🚀 GitHub Copilot Super-Prompt Framework

Modes:
  • /PR – Generate a Copilot-style Pull Request plan
  • /ANALYZE – Perform deep architectural/code analysis and refactor suggestions

If no mode is specified, default to /PR.

⸻

🧠 You are a GitHub Copilot Prompt Engineer

You generate structured Copilot prompts and perform architecture/code analysis depending on the mode.

---

⚙️ /PR Mode — Generate Copilot Pull Request Plan

When invoked:
  • Understand the feature, bug, or refactor request
  • Map out the workflow triggered by the request (user → UI → API → backend → DB)
  • Identify relevant files, modules, and components
  • For each relevant section:
    – What to change
    – Why it matters
    – How to express it clearly as Copilot instructions

📦 Response Format (PR-style)

🧠 Title
Short summary (e.g. "Add file upload validation to admin panel")

📊 Overview (Workflow Graph)
Structured flow, e.g.:
[User Action] → [UI Component] → [API] → [Service] → [DB]

🪲 Problem / Request
Description of the feature, bug, or goal

📁 Affected Files & Instructions
- path: src/pages/AdminUpload.tsx
  section: handleUpload()
  change: Add client-side validation before POST

💡 Suggested Changes
Step-by-step Copilot instructions

✅ Done When
Expected success criteria (e.g. validation error shown, data saved)

---

🔍 /ANALYZE Mode — Architecture & Refactor Insights

When invoked:
  • Parse project structure (modules, imports, exports)
  • Identify coupling, duplication, or anti-patterns
  • Suggest improvements (split components, extract services, rename, restructure)

📦 Response Format

🧠 Summary
High-level finding (e.g. "UI components are too tightly coupled to API calls")

📊 Dependency Graph
Component/function map (indented or text-based)

🧩 Key Observations
Top 3 insights about architecture or code health

💡 Suggested Refactors
Concrete steps to improve structure with justification

⚠️ Code Smells
List of duplication, nested logic, bloated components, etc.

---

⬇️ Codebase Input

When this framework is used, the full project source code will follow this instruction block.

---

✅ Example usage:
  • Please /PR a flow for file uploads with Copilot
  • Can you /ANALYZE the dashboard module for tight coupling or bloated components?
"""


def iter_paths(
    root_paths: Sequence[Path],
    exts: Sequence[str],
    ignore_patterns: Sequence[str] = DEFAULT_IGNORES,
) -> Iterable[Path]:
    """Yield files under root_paths whose suffix is in exts and whose path
    does not contain any string in ignore_patterns."""

    exts_set = {e.lower() for e in exts}
    ignore_patterns_set = {p for p in ignore_patterns}

    def _should_ignore(p: Path) -> bool:
        return any(pat in str(p) for pat in ignore_patterns_set)

    for root in root_paths:
        if _should_ignore(root):
            continue
        if root.is_file() and root.suffix.lower() in exts_set:
            yield root
            continue

        for file in root.rglob("*"):
            if not file.is_file():
                continue
            if file.suffix.lower() not in exts_set:
                continue
            if _should_ignore(file):
                continue
            yield file


def read_text(path: Path) -> str:
    """Return file content with universal‑newline handling."""
    try:
        return path.read_text(encoding="utf‑8", errors="replace")
    except Exception:
        logger.warning(f"Failed reading {path}")
        return ""


def _truncate(text: str, limit: int = MAX_LINE_LEN) -> str:
    text = re.sub(r"\s+", " ", text.strip())
    return text if len(text) <= limit else text[: limit - 3] + "…"


def _first_docline(node: ast.AST, kind: str, name: str) -> str:
    """Return first non‑empty docstring line or generic fallback."""
    if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef, ast.Module)):
        doc = ast.get_docstring(node, clean=True)
        if doc:
            for line in doc.splitlines():
                if line := line.strip():
                    return line
    return f"Provides functionality for the {kind} '{name}'."


def _params_returns(node) -> str:
    """Return (param, …) → Ret string for node."""
    try:
        params = ast.unparse(node.args)
    except Exception:
        pos = [a.arg for a in node.args.args]
        if node.args.vararg:
            pos.append(f"*{node.args.vararg.arg}")
        if node.args.kwarg:
            pos.append(f"**{node.args.kwarg.arg}")
        params = f"({', '.join(pos)})"

    ret = ""
    if node.returns is not None:
        try:
            ret = f" → {ast.unparse(node.returns)}"
        except Exception:
            if isinstance(node.returns, ast.Name):
                ret = f" → {node.returns.id}"
            else:
                ret = " → ?"
    return params + ret


def summarise_python(code: str, path: str) -> str:
    """Return structured summary of code or raise on syntax error."""
    tree = ast.parse(code, filename=path)
    lines: list[str] = []

    for node in tree.body:
        if isinstance(node, ast.ClassDef):
            cname = node.name
            lines.append(_truncate(f"▸ Class {cname}: {_first_docline(node, 'class', cname)}"))
            for sub in node.body:
                if isinstance(sub, (ast.FunctionDef, ast.AsyncFunctionDef)):
                    mname = sub.name
                    purpose = _first_docline(sub, "method", mname)
                    sig = _params_returns(sub)
                    lines.append(_truncate(f"• {mname}{sig}: {purpose}"))
        elif isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            fname = node.name
            purpose = _first_docline(node, "function", fname)
            sig = _params_returns(node)
            lines.append(_truncate(f"▸ Function {fname}{sig}: {purpose}"))
    return "\n".join(lines)


def file_to_block(path: Path, root: Path, summarise: bool) -> str:
    """Return <relpath>\ncontent\n</relpath> block for path."""
    try:
        rel = path.relative_to(root)
        text = read_text(path)

        if summarise:
            has_defs = re.search(r"\b(class|def)\b", text) is not None
            if has_defs:
                try:
                    text = summarise_python(text, str(rel))
                except SyntaxError:
                    logger.warning(f"SyntaxError in {rel}, falling back to raw")

        return f"<{rel}>\n{text}\n</{rel}>"
    except Exception:
        return ""


def make_snapshot(
    roots: Sequence[Path],
    *,
    exts: Sequence[str] = DEFAULT_EXTS,
    summarise: bool = False,
    workers: int = 8,
    ignore_patterns: Sequence[str] = DEFAULT_IGNORES,
    prefix: str = PROMPT,
) -> str:
    """Return concatenated snapshot for roots."""
    roots = [p.resolve() for p in roots]
    all_files = list(iter_paths(roots, exts, ignore_patterns=ignore_patterns))

    # Always include .github/copilot-instructions.md if it exists
    copilot_path = Path(".github/copilot-instructions.md").resolve()
    if copilot_path.exists() and copilot_path not in all_files:
        all_files.insert(0, copilot_path)

    logger.info(f"{len(all_files)} files found")

    def _one(p: Path) -> str:
        # If copilot-instructions, use project root as base
        if p == copilot_path:
            root = copilot_path.parent.parent.parent if copilot_path.parent.name == 'github' else roots[0]
        else:
            root = next(r for r in roots if r in p.parents or r == p)
        return file_to_block(p, root, summarise)

    with cf.ThreadPoolExecutor(max_workers=workers) as pool:
        blocks: List[str] = list(pool.map(_one, all_files))

    ret = "\n".join(blocks)
    if prefix:
        ret = f"{prefix}\n{ret}"
    return ret.strip()


def main():
    """Main entry point for the cat-projects command."""
    parser = argparse.ArgumentParser(description="Create code snapshot for LLMs.")
    parser.add_argument("paths", nargs="+", help="Files or directories to scan.")
    parser.add_argument(
        "-e", "--exts",
        default=",".join(DEFAULT_EXTS),
        help="Comma‑separated list of file extensions (default: .py).",
    )
    parser.add_argument(
        "-s", "--summarise",
        action="store_true",
        help="Summarise Python files."
    )
    parser.add_argument(
        "-w", "--workers",
        type=int,
        default=8,
        help="Thread workers (default: 8).",
    )
    parser.add_argument(
        "-i", "--ignore",
        default="",
        help="Comma‑separated list of additional substrings to ignore.",
    )

    args = parser.parse_args()

    paths = [Path(p) for p in args.paths]
    exts = [e if e.startswith(".") else f".{e}" for e in args.exts.split(",") if e]

    extra_ignores = tuple(p.strip() for p in args.ignore.split(",") if p.strip())
    ignore_patterns = DEFAULT_IGNORES + extra_ignores

    snapshot = make_snapshot(
        paths,
        exts=exts,
        summarise=args.summarise,
        workers=args.workers,
        ignore_patterns=ignore_patterns,
    )

    sys.stdout.write(snapshot)
    return 0


if __name__ == "__main__":
    exit(main())
