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
    "test",
    "demo",
    "legacy",
)
MAX_LINE_LEN = 120


# ---------------------------------------------------------------------------
# Helper – file discovery & I/O
# ---------------------------------------------------------------------------

prompts = {
    "gemini_copilot": '"🚀 GitHub Copilot Super-Prompt Framework\n\nModes:\n\t•\t/prompt – Generate a Copilot prompt (default mode)\n\t•\t/ask – Answer a user question about the codebase\n\t•\t/analyze – Perform deep analysis and return architectural insight + refactor suggestions\n\t•\t/code – When the user requests an update, return the full file with in-place modifications\n\n\n\n⸻\n\n🧠 You are a GitHub Copilot Prompt Engineer\n\nYou are a Copilot prompt generator and project analyst. Given a full source codebase, your task depends on the active mode. The mode is determined by user input:\n\t•\t/prompt → Generate structured, optimized Copilot instructions\n\t•\t/ask → Answer the user’s question about how to implement or debug something\n\t•\t/analyze → Analyze the codebase, generate a component graph, identify coupling, and suggest improvements/refactors\n\nIf no mode is specified, default to /prompt.\n\n⸻\n\n⚙️ /prompt Mode — Generate Copilot Prompt\n\nWhen invoked:\n\t•\tAnalyze the project structure, dependencies, and component/function relationships\n\t•\tUnderstand the workflow triggered by the user’s intent (feature, bug, refactor)\n\t•\tIdentify and list all relevant files, modules, and components\n\t•\tFor each relevant section:\n\t•\tExplain what to change\n\t•\tWhy it matters\n\t•\tHow to express it clearly as a Copilot instruction\n\n📦 Response Format (PR-style)\n\n🧠 Title\n\nShort summary (e.g. “Add file upload validation to admin panel”)\n\n📊 Overview (Workflow Graph)\n\nA structured list or diagram showing key flow:\n\n[User Action] → [UI Component] → [API] → [Controller] → [Service] → [DB or External]\n\nor\n\nComponentA → calls → FunctionB → fetches → DataService.method()\n\n🪲 Problem / Request\n\nDescription of the feature, bug, or goal\n\n📁 Affected Files & Instructions\n\nList each file and change needed:\n\n- path: src/pages/AdminUpload.tsx\n  section: handleUpload()\n  change: Add client-side validation before POST\n\n💡 Suggested Changes\n\nStep-by-step Copilot instructions you want to embed\n\n✅ Done When\n\nDescribe successful output (e.g. validation error shown, test passing, data saved)\n\n⸻\n\n❓ /ask Mode — Answer a Code Question\n\nWhen invoked:\n\t•\tFind the relevant logic/files that relate to the user’s question\n\t•\tExplain how it works in plain language\n\t•\tProvide any gotchas, edge cases, or pitfalls\n\t•\tIf applicable, include a code snippet or suggested usage\n\n📦 Response Format\n\n🔍 Question\n\nRestate the user’s question clearly\n\n🧭 Relevant Files & Logic\n\nList file/function/methods involved\n\n💬 Explanation\n\nDescribe what’s happening and how the code responds to the described scenario\n\n🛠 Example (Optional)\n\nCode sample showing the implementation\n\n⸻\n\n🔍 /analyze Mode — Deep Architecture + Refactor Insights\n\nWhen invoked:\n\t•\tParse full codebase structure (modules, exports, imports)\n\t•\tIdentify tightly coupled areas or duplications\n\t•\tSuggest refactors (component split, service extraction, separation of concerns)\n\n📦 Response Format\n\n🧠 Summary\n\nHigh-level finding (e.g. “Services too coupled to React views”)\n\n📊 Dependency Graph\n\nComponent/function map (can be indented or text-based)\n\n🧩 Key Observations\n\nTop 3 architectural/code health insights\n\n💡 Suggested Refactors\n\nRename, extract, restructure suggestions with justification\n\n⚠️ Code Smells\n\nDuplication, nested logic, large components, etc.\n\n⸻\n\n⬇️ Codebase Input\n\nWhen the prompt is used, you will be provided the full project code below this instruction block.\n\n⸻\n\nExample usage:\n\t•\tPlease /prompt a test flow for file uploads with Copilot\n\t•\tHow does the authentication flow work? /ask\n\t•\tCan you /analyze the dashboard module for tight coupling or bloated components?\n# Copilot Instructions for TRANSLATE_UI\n\n## Project Overview\n- **TRANSLATE_UI** is a game text localization platform with a FastAPI backend and a React/MUI frontend.\n- The backend (Python, FastAPI, Tortoise ORM) is in `apps/backend/app/` and exposes REST APIs for authentication, project, file, chunk, and job management.\n- The frontend (React, TypeScript, Mantine/MUI) is in `apps/frontend/src/` and implements the UI, routing, and API integration.\n\n## Architecture & Data Flow\n- **Backend**: Modular FastAPI app. Main entry: `main.py`. Routers in `routers/` (e.g., `auth.py`, `chunks.py`) define API endpoints. Services in `services/` handle business logic (e.g., `ai_translate_job.py`). Models in `models.py` use Tortoise ORM.\n- **Frontend**: Uses React Router for navigation, React Query for data fetching, and context providers for auth/navigation state. Main entry: `App.tsx`. Layouts in `layouts/`, components in `components/`, pages in `pages/`.\n- **API Integration**: All HTTP requests go through `src/services/api.ts`, which manages auth tokens, error handling, and JSON parsing.\n\n## Developer Workflows\n\n**How to Start the Project and Run Tests**:\n  - **Always use the predefined scripts in the `scripts/` directory to start servers and run tests.**\n  - To start both backend and frontend servers, use the VS Code task **Run All Servers** (which runs `bash scripts/start_server.sh`), or run the script directly from the project root:\n    ```bash\n    bash scripts/start_server.sh\n    ```\n  - **What to expect when running `start_server.sh`:**\n    - The script will automatically kill any processes running on ports 5173 (frontend) and 8160 (backend) to avoid port conflicts. You will see status messages indicating if a process was found and killed.\n    - The script ensures the `logs/` directory exists for log output.\n    - The backend (FastAPI) server will start, and its output will be logged to `logs/backend.log`. You will see a status message with the backend process ID and log file location.\n    - The frontend (React) server will start, and its output will be logged to `logs/frontend.log`. You will see a status message with the frontend process ID and log file location.\n    - The script will print a message indicating it is waiting for both servers to exit. Use `Ctrl+C` to stop both servers.\n  - **Debugging and checking logs:**\n    - All logs are written to the `logs/` directory.\n    - To debug or check server output in real time, use:\n      ```bash\n      tail -f logs/backend.log\n      tail -f logs/frontend.log\n      ```\n    - You can also open these log files in your editor for review.\n    - If either server fails to start, check the corresponding log file for error details.\n  - **Ports are managed automatically** by the script, so you do not need to manually free ports or kill processes.\n  - **Do not start servers or run tests manually**; always use the provided scripts to ensure a stable and reproducible environment.\n\n**Scripts Reference**:\n  - `scripts/start_server.sh`: Starts both backend and frontend servers with logging and port management.\n  - (Add additional scripts here as they are created for tests, migrations, etc.)\n\n## Project-Specific Conventions\n- **Backend**:\n  - All models inherit from `CruditeBaseModel`.\n  - CRUD operations are abstracted in `crud.py` via `CruditeManager`.\n  - User roles: LABELLER, REVIEWER, MANAGER (see `models.py`).\n  - API endpoints are grouped by resource in `routers/`.\n  - Long-running jobs use the `services/job_registry.py` pattern for registration and execution.\n- **Frontend**:\n  - Use React Query for all data fetching/mutations.\n  - Auth state is managed via `AuthContext`.\n  - Navigation and breadcrumbs via `NavigationContext` and `NavigationBreadcrumbs`.\n  - UI follows MUI/Mantine patterns; see `MainLayout.tsx` for navigation bar logic.\n  - All API calls should use the `api.ts` service for consistency and error handling.\n\n## Integration Points & Patterns\n- **Auth**: JWT-based, token stored in `localStorage`, attached to all API requests.\n- **Chunk Assignment**: Assign labellers to chunks via `/chunks/{chunk_id}/assign` (see `AssignToSelect.tsx`).\n- **AI Translation Jobs**: Triggered via backend job registry (`ai_translate_job.py`).\n- **Testing**: UI behavior expectations are documented in `.github/docs/ui_behavior_expected.md`.\n\n## Examples\n- To add a new backend resource, create a model, schema, router, and (optionally) service.\n- To add a new frontend page, add a route in `App.tsx`, a page in `pages/`, and use `api.ts` for data.\n\n## Key Files/Directories\n- Backend: `apps/backend/app/main.py`, `models.py`, `crud.py`, `routers/`, `services/`\n- Frontend: `apps/frontend/src/App.tsx`, `layouts/MainLayout.tsx`, `services/api.ts`, `components/`, `pages/`\n- UI/Behavior Guide (source of truth): `.github/docs/ui_behavior_expected.md`\n- ChunkWorkbench Documentation: `.github/docs/chunk-workbench-complete-guide.md`\n## Inserting Demo Data\n\nTo reset the database and insert demo/mock data for development or testing, use the provided script:\n\n```bash\npython scripts/reset_and_init_database.py\n```\n\n**What this script does:**\n- Resets the SQLite database (removes all data)\n- Creates demo users (admin, labeller, reviewer, etc.)\n- Creates demo projects\n- Uploads and processes a demo CSV file for translation\n- Generates chunks and translation pairs\n- Ensures all data is properly linked and ready for use in the UI\n\n**Requirements:**\n- The backend server must be running and accessible at `http://localhost:8160` (default)\n- To get api call: curl `http://localhost:8160/openapi.json` to verify the API is available\n- The api backend is mounted to front end at `http://localhost:5173/api`\n- The script uses HTTP requests to the backend API, so ensure the server is healthy before running\n\n**Usage steps:**\n1. Start the backend and frontend servers (see above for instructions)\n2. Run the script from the project root:\n   ```bash\n   python scripts/reset_and_init_database.py\n   ```\n3. Check the logs for status messages and errors\n4. After completion, log in with demo credentials (e.g., `admin`/`admin`) to see demo data in the UI\n\nFor more details, see comments in `scripts/reset_and_init_database.py`.\n## To look for ways of debuging or improving the code, consider\n looking to the .github/howtos/ directory for common tasks, such as database operations, migrations, and seeding scripts.\n\n**********************************************\nFULL PROJECT CODE BELOW\n\n**********************************************\n"'
}


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
    if isinstance(
        node, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef, ast.Module)
    ):
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
    prefix: str = prompts["gemini_copilot"],
) -> str:
    """Return concatenated snapshot for *roots*."""


    roots = [p.resolve() for p in roots]
    all_files = list(iter_paths(roots, exts, ignore_patterns=ignore_patterns))

    # Always include .github/copilot-instructions.md (hard set)
    copilot_path = Path(".github/copilot-instructions.md").resolve()
    if copilot_path.exists() and copilot_path not in all_files:
        all_files.insert(0, copilot_path)

    logger.info("{} files found (including copilot-instructions)", len(all_files))

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
    return ret.strip()  # remove trailing newline


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
