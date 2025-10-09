# Docs Folder Agents Guide

## Architecture Overview

Documentation directory containing guides, roadmaps, and operational runbooks for the dotfiles project maintenance.

Main files: `README.md` (overview), `baseline.md` (environment snapshot), `refactor-roadmap.md` (modernization plan), `rollback.md` (revert procedures).

Data flow: Documents updated during configuration changes to maintain sync with codebase.

## Developer Workflows

- **Reading docs**: Start with README.md for overview, then specific guides
- **Updating docs**: Edit markdown files when making config changes
- **Rollback**: Follow rollback.md to revert changes using baseline.md as reference
- **Planning**: Use refactor-roadmap.md for phased modernization steps

## Conventions & Patterns

- **File naming**: Descriptive names with .md extension
- **Structure**: README.md as entry point, specialized docs for specific purposes
- **Content**: Living documentation updated with code changes
- **Markdown**: Standard markdown with headings, lists, code blocks

## Integration Points

- **Dotfiles components**: Documents reference zsh/, vim/, tmux/ configurations
- **Setup scripts**: Baseline captures environment before/after setup
- **Version control**: Docs committed alongside code changes