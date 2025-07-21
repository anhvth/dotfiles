#!/usr/bin/env python3
"""project_catter.py — Create a per‑file snapshot of a code‑base
================================================================

* Walk one or more roots and collect files that match the requested
  extensions (default: ``.py``).
* Ignore typical development artefacts (``.venv``, ``__pycache__`` …) **and**
  any additional substrings supplied via the new ``--ignore`` option.
* For every file output a *block* that looks like::

    <src/module/foo.py>
    ...code or summary...
    </src/module/foo.py>

* If ``--summarise`` is **off** the block contains the raw file.
* If ``--summarise`` is **on** the block contains a *structured summary*
  generated with Python’s ``ast`` module.  No‑network, no‑API‑keys.

The snapshot is designed for ingestion by downstream LLMs or diff tools.

Usage
-----
>>> python project_catter.py my_repo/ -e .py,.pyi --summarise -w 16 \
        --ignore ".test,_test" > snapshot.txt
"""
from __future__ import annotations

import argparse
import ast
import concurrent.futures as cf
import re
import sys
from pathlib import Path
from typing import Iterable, List, Sequence, Tuple

from loguru import logger

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
DEFAULT_EXTS: Tuple[str, ...] = (".py",)
DEFAULT_IGNORES: Tuple[str, ...] = (
    ".venv",
    "__pycache__",
    ".git",
    ".mypy_cache",
    ".FOLDER",
    "node_modules",
    "test"
)
MAX_LINE_LEN = 120


# ---------------------------------------------------------------------------
# Helper – file discovery & I/O
# ---------------------------------------------------------------------------

def iter_paths(
    root_paths: Sequence[Path],
    exts: Sequence[str],
    ignore_patterns: Sequence[str] = DEFAULT_IGNORES,
) -> Iterable[Path]:
    """Yield files under *root_paths* whose suffix is in *exts* and whose path
    does **not** contain any string in *ignore_patterns*."""

    exts_set = {e.lower() for e in exts}
    ignore_patterns_set = {p for p in ignore_patterns}

    def _should_ignore(p: Path) -> bool:
        return any(pat in str(p) for pat in ignore_patterns_set)

    for root in root_paths:
        if _should_ignore(root):
            continue
        if root.is_file() and root.suffix.lower() in exts_set:
            logger.debug("Yield single file: {}", root)
            yield root
            continue

        for file in root.rglob("*"):
            if not file.is_file():
                continue
            if file.suffix.lower() not in exts_set:
                continue
            if _should_ignore(file):
                continue
            logger.trace("Yield: {}", file)
            yield file


def read_text(path: Path) -> str:
    """Return file content with universal‑newline handling."""
    try:
        return path.read_text(encoding="utf‑8", errors="replace")
    except Exception as exc:  # pragma: no cover — rare
        logger.warning("Failed reading {}: {}", path, exc)
        return ""  # empty but keeps block


# ---------------------------------------------------------------------------
# AST‑based summariser (zero external calls)
# ---------------------------------------------------------------------------

def _truncate(text: str, limit: int = MAX_LINE_LEN) -> str:
    text = re.sub(r"\s+", " ", text.strip())
    return text if len(text) <= limit else text[: limit - 3] + "…"


def _first_docline(node: ast.AST, kind: str, name: str) -> str:
    """Return first non‑empty docstring line or generic fallback."""
    doc = ast.get_docstring(node, clean=True)
    if doc:
        for line in doc.splitlines():
            if line := line.strip():
                return line
    return f"Provides functionality for the {kind} '{name}'."


def _params_returns(node: ast.FunctionDef | ast.AsyncFunctionDef) -> str:
    """Return ``(param, …) → Ret`` string for *node*."""

    try:
        params = ast.unparse(node.args)
    except Exception:  # pragma: no cover — edge cases
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
        except Exception:  # pragma: no cover
            if isinstance(node.returns, ast.Name):
                ret = f" → {node.returns.id}"
            else:
                ret = " → ?"
    return params + ret


def summarise_python(code: str, path: str) -> str:
    """Return structured summary of *code* or raise on syntax error."""
    tree = ast.parse(code, filename=path)
    lines: list[str] = []

    for node in tree.body:
        if isinstance(node, ast.ClassDef):
            cname = node.name
            lines.append(
                _truncate(f"▸ Class {cname}: {_first_docline(node, 'class', cname)}")
            )
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


# ---------------------------------------------------------------------------
# Public helpers
# ---------------------------------------------------------------------------

def file_to_block(path: Path, root: Path, summarise: bool) -> str:
    """Return ``<relpath>\ncontent\n</relpath>`` block for *path*."""

    rel = path.relative_to(root)
    text = read_text(path)

    if summarise:
        has_defs = re.search(r"\b(class|def)\b", text) is not None
        if has_defs:
            try:
                text = summarise_python(text, str(rel))
            except SyntaxError as exc:
                logger.warning("SyntaxError in {} ({}), falling back to raw", rel, exc)

    return f"<{rel}>\n{text}\n</{rel}>"


def make_snapshot(
    roots: Sequence[Path],
    *,
    exts: Sequence[str] = DEFAULT_EXTS,
    summarise: bool = False,
    workers: int = 8,
    ignore_patterns: Sequence[str] = DEFAULT_IGNORES,
) -> str:
    """Return concatenated snapshot for *roots*."""

    roots = [p.resolve() for p in roots]
    all_files = list(iter_paths(roots, exts, ignore_patterns=ignore_patterns))
    logger.info("{} files found", len(all_files))

    def _one(p: Path) -> str:
        root = next(r for r in roots if r in p.parents or r == p)
        return file_to_block(p, root, summarise)

    with cf.ThreadPoolExecutor(max_workers=workers) as pool:
        blocks: List[str] = list(pool.map(_one, all_files))

    return "\n".join(blocks)


# ---------------------------------------------------------------------------
# CLI entry‑point
# ---------------------------------------------------------------------------

def _parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    ap = argparse.ArgumentParser(description="Create code snapshot for LLMs.")
    ap.add_argument("paths", nargs="+", help="Files or directories to scan.")
    ap.add_argument(
        "-e",
        "--exts",
        default=",".join(DEFAULT_EXTS),
        help="Comma‑separated list of file extensions (default: .py).",
    )
    ap.add_argument(
        "-s", "--summarise", action="store_true", help="Summarise Python files."
    )
    ap.add_argument(
        "-w",
        "--workers",
        type=int,
        default=8,
        help="Thread workers (default: 8).",
    )
    ap.add_argument(
        "-i",
        "--ignore",
        default="",
        help="Comma‑separated list of additional substrings to ignore (e.g. '.test,_test').",
    )
    return ap.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> None:  # pragma: no cover
    ns = _parse_args(argv)

    paths = [Path(p) for p in ns.paths]
    exts = [e if e.startswith(".") else f".{e}" for e in ns.exts.split(",") if e]

    extra_ignores = tuple(p.strip() for p in ns.ignore.split(",") if p.strip())
    ignore_patterns = DEFAULT_IGNORES + extra_ignores

    snapshot = make_snapshot(
        paths,
        exts=exts,
        summarise=ns.summarise,
        workers=ns.workers,
        ignore_patterns=ignore_patterns,
    )
    # Print without extra newline so output can be redirected cleanly
    sys.stdout.write(snapshot)


if __name__ == "__main__":  # pragma: no cover
    print("project_catter.py: Creating code snapshot", file=sys.stderr)
    main()
