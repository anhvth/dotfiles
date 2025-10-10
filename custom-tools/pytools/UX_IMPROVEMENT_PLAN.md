# PyTools UX Improvement Plan

## Overview

This document outlines UX issues in the pytools CLI and proposes comprehensive improvements for better user experience.

## Critical Issues

### 1. ☠️ Kill the Legacy `set-env`

The old `set-env` command is gone. Anyone still typing `pytools run set-env ...` deserves the brutal error they'll get.

**Working commands now:**
```bash
pytools run env-set KEY VALUE
pytools run env-unset KEY
pytools run env-list
```

**Done:** wired into `src/pytools/env_commands.py` and registered in `cli.py`. Tests and docs updated; `set_env.py` is dead weight.

---

## Moderate Issues

### 2. ⚠️ **atv-select** - Confusing Help Flag

**Current:**
```bash
atv-select --help-venv  # Shows venv management help
```

**Problem:**
- `--help-venv` is non-standard, should be part of regular `--help`
- Hides important information from default help

**Solution:**
```bash
atv-select --help       # Show full help including venv management info
```

Or create a separate command:
```bash
venv-help              # Dedicated command for venv documentation
```

**Files to change:**
- `src/pytools/cli_utils.py::atv_select()`
- Merge `--help-venv` content into main help text

---

### 3. ⚠️ **cat-projects** - Cryptic Flags

**Current:**
```bash
cat-projects . -e .py,.js -s -w 8 -i node_modules
```

**Problems:**
- `-e` for extensions is not intuitive
- `-s` for summarise is cryptic
- `-w` for workers is unclear
- `-i` for ignore could be confused with other meanings

**Solution:**
Use long-form primary flags with short aliases:
```bash
cat-projects . --extensions .py,.js --summarize --workers 8 --ignore node_modules
# Short form still available:
cat-projects . -e .py,.js -s -w 8 -i node_modules
```

**Implementation:**
- Change argparse to use both long and short forms
- Make long form the primary in help text
- Document short forms as aliases

**Files to change:**
- `src/pytools/cat_projects.py::main()`

---

### 4. ✅ **lsh** - Clearer Naming & Help

**Current (after refresh):**
```bash
lsh commands.txt 4 --session-name run_list_commands --gpus 0,1,2,3 --dry-run
```

**Changes:**
- Expanded help text explaining List Shell (lsh) purpose
- Added `--session-name` alias and `--cpu-per-worker`
- Improved error messages for missing files, GPUs, tmux dependency

**Files updated:**
- `src/pytools/lsh.py::main()`
- `src/pytools/cli.py` usage/summary strings
- docs and quickstart examples

---

### 5. ⚠️ **organize-downloads** - Good but Can Be Better

**Current:**
```bash
organize-downloads ~/Downloads --dry-run --by modified --pattern '*.pdf' --yes
```

**Strengths:**
- Has `--dry-run` ✅
- Has confirmation with `--yes` ✅
- Clear flag names ✅

**Minor improvements:**
- Consider `--sort-by` instead of `--by` (more explicit)
- Add `--recursive` flag for subdirectories
- Add `--max-depth` for recursive limit

**Files to change:**
- `src/pytools/organize_downloads.py::main()`

---

## Minor Issues

### 6. ℹ️ **hf-down** - Limited Error Messages

**Current:**
```bash
hf-down <URL> [SAVE_NAME]
```

**Improvement:**
- Better error messages when URL is invalid
- Show progress if possible
- Validate URL format before attempting download

**Files to change:**
- `src/pytools/hf_down.py::download_file()`

---

### 7. ℹ️ **keep-ssh** - Good UX, Minor Polish

**Current:**
```bash
keep-ssh user@host --interval 60 --verbose
```

**Strengths:**
- Clear flag names ✅
- Good feedback with symbols ✅

**Minor improvements:**
- Add `--log-file` option for persistent logging
- Add `--retry-limit` for max connection failures before giving up

**Files to change:**
- `src/pytools/cli_utils.py::keep_ssh()`

---

## General UX Principles to Apply

### 1. **Consistency Across Tools**

✅ **DO:**
- Use `--dry-run` (with hyphen) everywhere
- Use `--yes` or `-y` for confirmation skipping
- Use long flags as primary, short as aliases

❌ **DON'T:**
- Mix `--dry-run` and `--dry_run`
- Use only short flags without long equivalents
- Create custom help flags like `--help-venv`

### 2. **Safety Levels**

For destructive operations, ALWAYS have:
1. Preview/dry-run mode (`--dry-run`)
2. Confirmation prompt (can be skipped with `--yes`)
3. Clear summary of what will change

### 3. **Flag Naming**

**Good:**
- `--extensions` (descriptive)
- `--workers` (clear)
- `--sort-by` (explicit)

**Bad:**
- `-e` only (cryptic)
- `--by` (ambiguous)
- `--help-venv` (non-standard)

### 4. **Error Messages**

Always provide:
- What went wrong
- Why it failed
- How to fix it (if possible)
- Example of correct usage

---

## Implementation Priority

### Phase 1: Critical (Breaking Changes)
1. obliterate `set-env`, ship `env-*` trio ⚡ — already live, never going back

### Phase 2: Moderate (Non-Breaking Enhancements)
2. **atv-select**: Remove `--help-venv`, merge into main help
3. **cat-projects**: Add long-form flags (keep short as aliases)
4. **lsh**: Improve argument naming and help text

### Phase 3: Polish (Minor Improvements)
5. **organize-downloads**: Add `--sort-by`, `--recursive`
6. **hf-down**: Better error messages
7. **keep-ssh**: Add logging options

---

## Migration Guide for Users

### Env Command Reality Check

`set-env` aliases are gone. Update any scripts or enjoy the failure. Release notes shout about `env-*` so nobody can miss it.

---

## Testing Checklist

For each change:
- [ ] Update tool implementation
- [ ] Update CLI registry in `cli.py`
- [ ] Update unit tests
- [ ] Update `README.md` examples
- [ ] Update `docs/CLI.md` reference
- [ ] Test in interactive mode
- [ ] Test in direct mode
- [ ] Test with `--help`
- [ ] Update shell completion (if any)

---

## Files to Modify

### Phase 1 (env-* split):
- `src/pytools/env_commands.py` - Primary implementation
- `src/pytools/cli.py` - Register new tools
- `tests/test_cli.py` - Update tests
- `README.md` - Update examples
- `docs/CLI.md` - Update reference

### Phase 2 (flag improvements):
- `src/pytools/cli_utils.py` - atv-select
- `src/pytools/cat_projects.py` - flag naming
- `src/pytools/lsh.py` - argument clarity

### Phase 3 (polish):
- `src/pytools/organize_downloads.py`
- `src/pytools/hf_down.py`
- `src/pytools/cli_utils.py` - keep-ssh

---

## Success Metrics

After implementation:
- ✅ No more "set-env set" stuttering
- ✅ All flags have long-form names
- ✅ Consistent `--dry-run` across tools
- ✅ No custom help flags (use main `--help`)
- ✅ Clear, actionable error messages
- ✅ Updated documentation matches reality
- ✅ All tests passing

---

## Notes

- Consider creating a CONTRIBUTING.md with UX guidelines
- Add pre-commit hook to check flag naming consistency
- Consider adding shell completion for new commands
- Update any shell aliases or wrapper scripts in dotfiles
