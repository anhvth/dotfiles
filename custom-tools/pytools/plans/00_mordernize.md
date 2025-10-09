# PyTools Modernization Plan (v0.3 Roadmap)

This plan evaluates the current state of PyTools, highlights UX and consistency gaps, proposes a guiding philosophy, and outlines concrete steps to modernize the CLI and tools. It balances small, high‑impact fixes with a coherent longer‑term direction.

## Philosophy

- Single Entry, Consistent Everywhere: One `pytools` CLI with predictable subcommands and behavior across tools.
- Safe by Default: Destructive actions require explicit confirmation; dry‑run first, clear previews, undo when possible.
- Friendly, Not Fancy: Helpful messages, simple defaults, color where it helps, plain output when scripted.
- Observable and Trustworthy: Every run logged; errors actionable; diagnostics easy to find and share.
- Composable Outputs: Human‑readable by default, machine‑readable on demand (e.g., `--json`).
- Minimal Surprises: Cross‑platform where feasible, graceful fallbacks for external dependencies.
- Docs Close to Code: Help text and examples generated from the registry; README and docs reliably reflect reality.

## Current State Snapshot

- Unified CLI with a registry and session logger exists (`src/pytools/cli.py`, `src/pytools/core/*`).
- Mixed argument frameworks across tools (argparse, Typer); some tools aren’t registered in the CLI.
- Rich‑rendered CLI exists; most tools print plain text with inconsistent stderr/exit codes.
- README references docs (`docs/quickstart.md`, `docs/modern_cli_plan.md`) and tests that are not present.
- External tools (`tmux`, `fzf`, `wget`) used without a shared preflight check pattern.
- Safety tags are informative but not enforced (no global confirmation/dry‑run policies).
- Config paths vary (e.g., venv history under `~/.cache/dotfiles` vs. `~/.config/pytools`).

## Inconsistencies and UX Issues (Product View)

1) Fragmented CLI patterns
   - Some tools use `argparse` (e.g., `lsh`, `organize-downloads`), others use `typer` (`report_error`, `setup_typing`).
   - Tools with Typer apps are not wired into the registry; discoverability suffers.

2) Help and usage mismatch
   - Registry shows manual `usage` strings that can drift from actual parsers.
   - No `--help` proxying inside `pytools run <tool> --help` for all tools.

3) Safety not enforced
   - “Destructive” tools (move/kill) lack global `--dry-run` and confirmation gates.
   - No consistent preview UI before actions.

4) Output inconsistency
   - Errors sometimes printed to stdout; stderr/exit codes not standardized.
   - Rich styling in CLI vs. plain prints in tools; no `--no-color` global toggle.

5) Missing documentation and tests
   - README references non‑existent `docs/` and test suites; reduces trust and DX.

6) External dependency surprises
   - `fzf`, `tmux`, `wget` checks scattered; no single `doctor` command or clear remediation.

7) Config sprawl
   - Ad‑hoc paths (e.g., `~/.cache/dotfiles/venv_history`) vs. `~/.config/pytools`; no shared config loader.

8) Limited observability from tools
   - Session logs exist but are not surfaced (`pytools sessions`), and tools do not attach structured context.

9) Cross‑platform gaps
   - `organize-downloads` uses `st_ctime` (change time on Linux) as “creation date”; behavior differs by OS.

10) Ad‑hoc interactive capture
   - `cli.py` keeps a hardcoded module map to re‑import and capture output, which is brittle and duplicates logic.

## Modernization Objectives

- Unify CLI ergonomics across tools with a consistent invocation, help, and output model.
- Enforce safety practices (dry‑run/confirm) where actions modify the system.
- Introduce shared preflight checks for external dependencies.
- Centralize configuration and session introspection.
- Make docs and tests match reality; keep them lightweight but reliable.

## Plan of Action

1) CLI Architecture Consolidation
- Adopt a single pattern for tools: each module exposes `main(argv: list[str] | None = None) -> int` and uses `argparse` internally. Keep modules thin and pure in/out.
- In registry, store a callable `runner(args: list[str]) -> int` and a flag `passthrough` for interactive tools.
- Remove the hardcoded “module map” in `cli.py` by ensuring `runner` can optionally return `(rc, stdout, stderr)` when `capture=True`. Standardize capture via one code path.
- Add global flags in `pytools` (`--no-color`, `--json`, `--version`).

2) Safety & Confirmation
- Standardize `--dry-run` across tools that modify system state (`organize-downloads`, `lsh` as schedules, `kill-process-grep`).
- Add `--yes/--force` gate for destructive operations; interactive preview by default when run from TTY.
- For `kill-process-grep`, restrict to current user by default; require `--all-users` to widen scope; add a final confirmation when >N processes selected.

3) Output & Error Model
- Convention: normal messages → stdout; errors/warnings → stderr; non‑zero exit codes on failure.
- Add `--json` output where meaningful (e.g., `print-ipv4`, `cat-projects` summary metadata, `hf-down` result).
- Consistent Rich‑based panels for previews and summaries; respect `--no-color` for script use.

4) Dependency Management
- Add `pytools doctor` to check presence/versions of `fzf`, `tmux`, `wget`, and network access; suggest install commands.
- Tools import/execute only after passing dependency checks; otherwise emit clear guidance and rc=2.

5) Configuration Unification
- Introduce `~/.config/pytools/config.toml` with helper loader; env var `PYTOOLS_CONFIG_DIR` already respected by session logger.
- Move venv history (`atv-select`) path under config dir; maintain backward‑compatible fallback and migration message.

6) Observability Improvements
- Extend `SessionLogger` with context (tool name, args, rc, stderr length, duration).
- Add `pytools sessions` commands: `list`, `tail <id>`, `show <id> --json`.
- Encourage tools to attach structured extras (e.g., counts, selected items) to session events.

7) Documentation & Help
- Generate CLI docs from the registry (`pytools list` + per‑tool `usage`) to `docs/CLI.md`.
- Create minimal `docs/quickstart.md` aligned with actual features; link from README.
- Keep README claims accurate (remove fake test counts; add real test badges later).

8) Testing Baseline
- Add a minimal `tests/` covering: registry add/list, `pytools list`, `run` success/failure paths, session write.
- Add smoke tests for each tool’s `--help` and error handling; avoid network/external reliance in CI by mocking.

9) Tool‑specific UX Fixes
- organize-downloads:
  - Use modification time (`st_mtime`) by default with `--by created|modified` option; document OS caveat.
  - `--dry-run`, `--pattern` include/exclude, `--min-size`, `--max-size`, `--move-to <dir>`.
  - Preview table (from/to) with conflict resolution strategy; optional `--trash` integration if available.
- lsh:
  - Preflight check for `tmux`; quote commands robustly; optional `--env KEY=VAL` pairs; write command files under a temp dir; render a plan preview.
- hf-down:
  - Preflight for `wget`, add `--output` (alias `-O`) and `--retries`; better error messages; optional Python fallback via `urllib` if `wget` missing.
- kill-process-grep:
  - Filter current user by default; summarize impact; last‑chance confirmation; SIGTERM then optional `--signal SIGKILL`.
- cat-projects:
  - Add `--json` to output a file list and counts; clarify ignore semantics; ensure robust summariser fallback.
- report_error/setup_typing:
  - Register both as tools; align to `main(argv) -> int` shim while keeping Typer CLIs callable directly.
- set-env:
  - Register in CLI; add `--file` override for custom env path; consistent stderr on errors and rc semantics.

10) Developer Experience & Quality
- Adopt `ruff` and `mypy` configs in `pyproject.toml`; keep `setup_typing.py` for bootstrapping but ensure configs live in VCS.
- Provide `Makefile` or `uv` tasks: `fmt`, `lint`, `test`, `docs`.
- Add `--version` sourced from `pytools.__version__`.

## Milestones

Phase 1 — Foundations (1–2 days)
- Register missing tools (`report_error`, `setup_typing`, `set_env`).
- Remove capture hack by standardizing runner behavior.
- Add `pytools --version`, `--no-color`, `doctor` (basic checks).

Phase 2 — Safety & UX (2–3 days)
- Implement `--dry-run` and confirmations for destructive tools.
- Standardize stderr/exit codes; add JSON output where trivial.
- Introduce config loader; migrate venv history path.

Phase 3 — Docs & Tests (1–2 days)
- Add `docs/quickstart.md` and `docs/CLI.md` generation.
- Add minimal `tests/` and wire to CI (if any), trimming README claims accordingly.

Phase 4 — Polish & Tool Enhancements (ongoing)
- Tool‑specific improvements listed above; iterative releases.

## Success Criteria

- All tools runnable via `pytools run <name>` with consistent `--help`, stderr, and exit codes.
- Destructive operations require `--yes` or explicit confirmation; previews available with `--dry-run`.
- `pytools doctor` reports dependency status with remediation.
- Docs exist and match reality; tests cover core CLI paths and basic tool health.
- Session logs are accessible (`pytools sessions …`) and include useful context.

## Risks and Mitigations

- Backward compatibility: keep current module entry points; add shims rather than breaking Typer apps.
- External dependencies: don’t auto‑install; provide clear guidance and fallbacks.
- Scope creep: ship improvements in phases; prefer small PRs and incremental releases.

## Notes on Organize Downloads (Example Deep‑Dive)

- Problem: Uses `st_ctime` which is change time on Linux → misleading grouping.
- Plan: default to `st_mtime` with a `--by` option; add preview and conflict policy; implement `--dry-run` and `--yes` gates.
- UX: Rich table preview showing From → To, total size, and counts; warnings on large moves; resume on partial failures; skip dotfiles by default with `--include-hidden` to opt‑in.

## Immediate Next Steps

1) Add registry entries for `report_error`, `setup_typing`, and `set_env`.
2) Introduce `pytools doctor` and basic dependency checks.
3) Add `--version`, `--no-color` flags, and standardize run capture.
4) Create `docs/quickstart.md` skeleton and trim README claims to reality.
5) Add `--dry-run` to `organize-downloads` and a simple preview, then iterate.

